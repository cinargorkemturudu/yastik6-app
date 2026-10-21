import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:yastik_alti/data/local/db_constants.dart';

import '../../core/crypto_service.dart';
import '../../core/env.dart';

abstract class CloudBackupStrategy {
  Future<bool> backupDatabase(File backupFile); // İMZA GÜNCELLENDİ
  /// Downloads the backup to [destinationPath]; never writes to the live database.
  Future<void> downloadBackup(String destinationPath);
  Future<GoogleSignInAccount?> signIn();
  Future<void> signOut();
}

class GoogleDriveBackupStrategy implements CloudBackupStrategy {
  static const _scopes = [drive.DriveApi.driveAppdataScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(
        serverClientId: Env.googleDriveClientId,
      );
      _isInitialized = true;
    }
  }

  Future<http.Client?> _getAuthenticatedClient(GoogleSignInAccount account) async {
    try {
      var authorization = await account.authorizationClient.authorizationForScopes(_scopes);
      authorization ??= await account.authorizationClient.authorizeScopes(_scopes);
      return authorization.authClient(scopes: _scopes);
    } catch (e) {
      throw Exception("Yetkilendirme Hatası: $e");
    }
  }

  @override
  Future<bool> backupDatabase(File backupFile) async {
    final account = await signIn();
    if (account == null) {
      throw Exception("Google Girişi başarısız oldu.");
    }

    final client = await _getAuthenticatedClient(account);
    if (client == null) {
      throw Exception("Google Drive API yetkisi alınamadı.");
    }

    try {
      final driveApi = drive.DriveApi(client);
      // Artık parametre olarak gelen dosyayı yüklüyoruz
      final media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
      final cloudFileName = 'yastik6_backup_${DbConstants.dbName}';

      final driveFile = drive.File()
        ..name = cloudFileName
        ..parents = ['appDataFolder'];

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$cloudFileName'",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final oldFileId = fileList.files!.first.id;
        if (oldFileId != null) {
          await driveApi.files.delete(oldFileId);
        }
      }

      await driveApi.files.create(driveFile, uploadMedia: media);
      debugPrint("Google Drive Yedekleme Başarılı!");
      return true;
    } catch (e) {
      throw Exception("Drive Yükleme Hatası: $e");
    }
  }

  @override
  Future<void> downloadBackup(String destinationPath) async {
    final account = await signIn();
    if (account == null) throw Exception("Google Girişi başarısız oldu.");

    final client = await _getAuthenticatedClient(account);
    if (client == null) throw Exception("Google Drive API yetkisi alınamadı.");

    try {
      final driveApi = drive.DriveApi(client);
      final cloudFileName = 'yastik6_backup_${DbConstants.dbName}';

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$cloudFileName'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception("Bulutta '$cloudFileName' adlı yedek dosyası bulunamadı.");
      }

      final fileId = fileList.files!.first.id;
      if (fileId == null) throw Exception("Dosya ID'si alınamadı.");

      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }
      await File(destinationPath).writeAsBytes(dataStore, flush: true);

      debugPrint("Google Drive yedeği indirildi.");
    } catch (e) {
      throw Exception("Drive İndirme Hatası: $e");
    }
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();
      return await _googleSignIn.authenticate();
    } catch (error) {
      throw Exception("Giriş Hatası: $error");
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}

class ICloudBackupStrategy implements CloudBackupStrategy {
  final String _containerId = 'iCloud.com.yourdomain.yastikAlti';

  @override
  Future<bool> backupDatabase(File backupFile) async {
    try {
      final cloudFileName = 'yastik6_backup_${DbConstants.dbName}';

      await ICloudStorage.upload(
        containerId: _containerId,
        filePath: backupFile.path, // Parametre gelen dosya
        destinationRelativePath: cloudFileName,
        onProgress: (stream) {
          stream.listen((progress) => debugPrint('iCloud Yükleniyor: %$progress'));
        },
      );

      debugPrint("iCloud Yedekleme Başarılı!");
      return true;
    } catch (e) {
      throw Exception("iCloud Yükleme Hatası: $e");
    }
  }

  @override
  Future<void> downloadBackup(String destinationPath) async {
    try {
      final cloudFileName = 'yastik6_backup_${DbConstants.dbName}';

      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: cloudFileName,
        destinationFilePath: destinationPath,
        onProgress: (stream) {
          stream.listen((progress) => debugPrint('iCloud İndiriliyor: %$progress'));
        },
      );

      debugPrint("iCloud yedeği indirildi.");
    } catch (e) {
      throw Exception("iCloud İndirme Hatası: $e");
    }
  }

  @override
  Future<GoogleSignInAccount?> signIn() async => null;

  @override
  Future<void> signOut() async {}
}

/// The parts of the local database that backup/restore needs; [LocalDatabase] in the app, a fake in tests.
abstract class BackupDatabaseFile {
  Future<String> get path;
  Future<void> checkpoint();
  Future<void> close();
}

/// The downloaded file decrypted fine but is not a SQLite database.
class InvalidBackupContentException implements Exception {
  const InvalidBackupContentException();
}

class CloudBackupService {
  static final List<int> _sqliteHeader = 'SQLite format 3\u0000'.codeUnits;

  final CloudBackupStrategy _strategy;
  final CryptoService _cryptoService;
  final BackupDatabaseFile _database;

  CloudBackupService({required CryptoService crypto, required BackupDatabaseFile database, CloudBackupStrategy? strategy})
      : _cryptoService = crypto,
        _database = database,
        _strategy = strategy ?? (Platform.isIOS ? ICloudBackupStrategy() : GoogleDriveBackupStrategy());

  Future<bool> backupDatabase(String passphrase) async {
    final dbPath = await _database.path;
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception("Yerel veritabanı bulunamadı. Lütfen önce uygulamaya bir işlem ekleyin.");
    }

    // 1. Make sure the file on disk holds every committed write, then read and encrypt it
    await _database.checkpoint();
    final rawBytes = await dbFile.readAsBytes();
    final encryptedPayload = await _cryptoService.encryptBackup(rawBytes, passphrase);

    // 2. Upload the encrypted copy from a temp file, and always clean it up
    final tempEncryptedFile = File('$dbPath.enc');
    try {
      await tempEncryptedFile.writeAsBytes(encryptedPayload, flush: true);
      return await _strategy.backupDatabase(tempEncryptedFile);
    } finally {
      if (await tempEncryptedFile.exists()) await tempEncryptedFile.delete();
    }
  }

  /// Replaces the local database with the cloud backup. Everything that can fail (download,
  /// wrong passphrase, corrupted file) happens before the live database is touched, so a
  /// failed restore leaves the current portfolio exactly as it was.
  Future<void> restoreDatabase(String passphrase) async {
    final dbPath = await _database.path;
    final downloaded = File('$dbPath.download');
    final restored = File('$dbPath.restore');

    try {
      await _strategy.downloadBackup(downloaded.path);
      final plain = await _cryptoService.decryptBackup(await downloaded.readAsBytes(), passphrase);
      if (!_isSqliteFile(plain)) throw const InvalidBackupContentException();
      await restored.writeAsBytes(plain, flush: true);

      // Only now swap it in: close the connection, replace the file, drop the old journal files
      await _database.close();
      await restored.rename(dbPath);
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        final sidecar = File('$dbPath$suffix');
        if (await sidecar.exists()) await sidecar.delete();
      }
    } finally {
      for (final temp in [downloaded, restored]) {
        if (await temp.exists()) await temp.delete();
      }
    }
  }

  bool _isSqliteFile(List<int> bytes) {
    if (bytes.length < _sqliteHeader.length) return false;
    for (var i = 0; i < _sqliteHeader.length; i++) {
      if (bytes[i] != _sqliteHeader[i]) return false;
    }
    return true;
  }

  Future<GoogleSignInAccount?> signIn() => _strategy.signIn();
  Future<void> signOut() => _strategy.signOut();
}
