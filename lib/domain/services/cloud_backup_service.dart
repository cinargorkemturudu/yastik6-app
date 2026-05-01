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

import '../../core/env.dart';

abstract class CloudBackupStrategy {
  Future<bool> backupDatabase();
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

  Future<File?> _getDatabaseFile() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DbConstants.dbName);
    final dbFile = File(dbPath);

    if (await dbFile.exists()) return dbFile;
    return null;
  }

  Future<http.Client?> _getAuthenticatedClient(GoogleSignInAccount account) async {
    try {
      var authorization = await account.authorizationClient.authorizationForScopes(_scopes);
      // Since authorizeScopes returns a non-nullable object or throws an error, we don't need a null check
      authorization ??= await account.authorizationClient.authorizeScopes(_scopes);

      return authorization.authClient(scopes: _scopes);
    } catch (e) {
      throw Exception("Yetkilendirme Hatası: $e");
    }
  }

  @override
  Future<bool> backupDatabase() async {
    final dbFile = await _getDatabaseFile();
    if (dbFile == null) {
      throw Exception("Yerel veritabanı bulunamadı. Lütfen önce uygulamaya bir işlem ekleyin.");
    }

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
      final media = drive.Media(dbFile.openRead(), dbFile.lengthSync());
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
      // authenticate() automatically throws a PlatformException if cancelled, no null check needed
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

  Future<File?> _getLocalDatabaseFile() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, DbConstants.dbName);
    final dbFile = File(dbPath);

    if (await dbFile.exists()) return dbFile;
    return null;
  }

  @override
  Future<bool> backupDatabase() async {
    final dbFile = await _getLocalDatabaseFile();
    if (dbFile == null) {
      throw Exception("Yerel veritabanı bulunamadı. Lütfen önce uygulamaya bir işlem ekleyin.");
    }

    try {
      final cloudFileName = 'yastik6_backup_${DbConstants.dbName}';

      await ICloudStorage.upload(
        containerId: _containerId,
        filePath: dbFile.path,
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

  CloudBackupService() : _strategy = Platform.isIOS ? ICloudBackupStrategy() : GoogleDriveBackupStrategy();

  Future<bool> backupDatabase() => _strategy.backupDatabase();
  Future<bool> restoreDatabase() => _strategy.restoreDatabase();
  Future<GoogleSignInAccount?> signIn() => _strategy.signIn();
  Future<void> signOut() => _strategy.signOut();
}