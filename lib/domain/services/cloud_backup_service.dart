import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:yastik_alti/data/local/db_constants.dart';

import '../../core/crypto_service.dart';
import '../../core/env.dart';

abstract class CloudBackupStrategy {
  Future<bool> backupDatabase(File backupFile); // İMZA GÜNCELLENDİ
  Future<bool> restoreDatabase();
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
  Future<bool> restoreDatabase() async {
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

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, DbConstants.dbName);
      final dbFile = File(dbPath);

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }
      // Şifreli haliyle doğrudan veritabanı yoluna yazıyoruz, servis bunu alıp çözecek.
      await dbFile.writeAsBytes(dataStore, flush: true);

      debugPrint("Google Drive Geri yükleme Başarılı!");
      return true;
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
  Future<bool> restoreDatabase() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, DbConstants.dbName);
      final cloudFileName = 'yastik6_backup_${DbConstants.dbName}';

      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: cloudFileName,
        destinationFilePath: dbPath,
        onProgress: (stream) {
          stream.listen((progress) => debugPrint('iCloud İndiriliyor: %$progress'));
        },
      );

      debugPrint("iCloud Geri yükleme Başarılı!");
      return true;
    } catch (e) {
      throw Exception("iCloud İndirme Hatası: $e");
    }
  }

  @override
  Future<GoogleSignInAccount?> signIn() async => null;

  @override
  Future<void> signOut() async {}
}

class CloudBackupService {
  final CloudBackupStrategy _strategy;
  final CryptoService _cryptoService;

  CloudBackupService({required CryptoService crypto})
      : _cryptoService = crypto,
        _strategy = Platform.isIOS ? ICloudBackupStrategy() : GoogleDriveBackupStrategy();

  Future<bool> backupDatabase() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DbConstants.dbName);
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception("Yerel veritabanı bulunamadı. Lütfen önce uygulamaya bir işlem ekleyin.");
    }

    // 1. Oku ve Şifrele
    final rawBytes = await dbFile.readAsBytes();
    final encryptedPayload = _cryptoService.encryptBytes(rawBytes);

    // 2. Şifreli veriyi geçici bir dosyaya yaz (Ek paket kurmamak için aynı dizini kullanıyoruz)
    final tempEncryptedFile = File(join(dbFolder, '${DbConstants.dbName}.enc'));
    await tempEncryptedFile.writeAsString(encryptedPayload);

    // 3. Stratejiye ver, buluta yüklesin
    final success = await _strategy.backupDatabase(tempEncryptedFile);

    // 4. Çöpü temizle (Şifreli geçici dosyayı sil)
    if (await tempEncryptedFile.exists()) {
      await tempEncryptedFile.delete();
    }

    return success;
  }

  Future<bool> restoreDatabase() async {
    // 1. Strateji veriyi indirip dbFile konumuna yazar (Şu an şifreli halde)
    final success = await _strategy.restoreDatabase();
    if (!success) return false;

    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DbConstants.dbName);
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      // 2. Şifreli veriyi oku
      final encryptedContent = await dbFile.readAsString();

      // 3. Şifreyi çöz
      final decryptedBytes = _cryptoService.decryptToBytes(encryptedContent);

      // 4. Saf ve kullanılabilir veritabanını yerine yaz
      await dbFile.writeAsBytes(decryptedBytes, flush: true);
    }

    return true;
  }

  Future<GoogleSignInAccount?> signIn() => _strategy.signIn();
  Future<void> signOut() => _strategy.signOut();
}