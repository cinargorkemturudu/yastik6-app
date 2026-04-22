import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
// [V7 GÜNCEL]: Artık doğrudan Authorization nesnesine authClient() metodunu kazandırıyor
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:yastik_alti/data/local/db_constants.dart';

// =========================================================================
// STRATEGY PATTERN ARAYÜZÜ (Platform Bağımsız Yapı)
// =========================================================================
abstract class CloudBackupStrategy {
  Future<bool> backupDatabase();
  Future<bool> restoreDatabase();
  Future<GoogleSignInAccount?> signIn();
  Future<void> signOut();
}

// =========================================================================
// GOOGLE DRIVE UYGULAMASI (Android İçin - Google Sign In v7.2.0 API)
// =========================================================================
class GoogleDriveBackupStrategy implements CloudBackupStrategy {
  static const _scopes = [drive.DriveApi.driveAppdataScope];

  // [V7 ÇÖZÜMÜ 1]: Artık nesne oluşturulmuyor, Singleton (instance) kullanılıyor
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      // [V7 ÇÖZÜMÜ 2]: Client ID'ler artık initialize() içinde tanımlanıyor
      await _googleSignIn.initialize(
        serverClientId: "148786327804-saf1m6d7nh8td79f7cfsju8lnnafk0ev.apps.googleusercontent.com",
      );
      _isInitialized = true;
    }
  }

  Future<File?> _getDatabaseFile() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, DbConstants.dbName);
      final dbFile = File(dbPath);

      if (await dbFile.exists()) return dbFile;
      return null;
    } catch (e) {
      debugPrint("Dosya yolu bulunurken hata: $e");
      return null;
    }
  }

  // [V7 ÇÖZÜMÜ 3]: Yetkilendirme (Authorization) adımı ayrıldı
  Future<http.Client?> _getAuthenticatedClient(GoogleSignInAccount account) async {
    try {
      // 1. Kullanıcının Drive yetkisi verip vermediğini kontrol et, yoksa yetki iste
      var authorization = await account.authorizationClient.authorizationForScopes(_scopes);
      authorization ??= await account.authorizationClient.authorizeScopes(_scopes);

      // 2. Extension paketi sayesinde authorization nesnesi üzerinden Client al! (Unused import hatasını çözen yer)
      return authorization.authClient(scopes: _scopes);
    } catch (e) {
      debugPrint("Auth Client oluşturulamadı: $e");
      return null;
    }
  }

  @override
  Future<bool> backupDatabase() async {
    try {
      final dbFile = await _getDatabaseFile();
      if (dbFile == null) return false;

      final account = await signIn();
      if (account == null) return false;

      final client = await _getAuthenticatedClient(account);
      if (client == null) return false;

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
      debugPrint("Google Drive Yedekleme çöktü: $e");
      return false;
    }
  }

  @override
  Future<bool> restoreDatabase() async {
    try {
      final account = await signIn();
      if (account == null) return false;

      final client = await _getAuthenticatedClient(account);
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);
      final cloudFileName = 'yastik6_backup_${DbConstants.dbName}';

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$cloudFileName'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) return false;

      final fileId = fileList.files!.first.id;
      if (fileId == null) return false;

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
      debugPrint("Google Drive Geri yükleme çöktü: $e");
      return false;
    }
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();
      // [V7 ÇÖZÜMÜ 4]: 'signIn' metodu kalktı, yerine 'authenticate' geldi
      final account = await _googleSignIn.authenticate();
      return account;
    } catch (error) {
      debugPrint("Google Girişi iptal edildi veya hata: $error");
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}

// =========================================================================
// ICLOUD UYGULAMASI (iOS İçin Apple Ekosistemi)
// =========================================================================
class ICloudBackupStrategy implements CloudBackupStrategy {
  final String _containerId = 'iCloud.com.yourdomain.yastikAlti';

  Future<File?> _getLocalDatabaseFile() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, DbConstants.dbName);
      final dbFile = File(dbPath);

      if (await dbFile.exists()) return dbFile;
      return null;
    } catch (e) {
      debugPrint("Dosya yolu bulunurken hata: $e");
      return null;
    }
  }

  @override
  Future<bool> backupDatabase() async {
    try {
      final dbFile = await _getLocalDatabaseFile();
      if (dbFile == null) return false;

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
      debugPrint("iCloud Yedekleme çöktü: $e");
      return false;
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
      debugPrint("iCloud Geri yükleme çöktü: $e");
      return false;
    }
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    return null;
  }

  @override
  Future<void> signOut() async {
  }
}

// =========================================================================
// FACADE / KÖPRÜ (RootScreen ile Kusursuz Uyum)
// =========================================================================
class CloudBackupService {
  final CloudBackupStrategy _strategy;

  CloudBackupService() : _strategy = Platform.isIOS ? ICloudBackupStrategy() : GoogleDriveBackupStrategy();

  Future<bool> backupDatabase() => _strategy.backupDatabase();
  Future<bool> restoreDatabase() => _strategy.restoreDatabase();
  Future<GoogleSignInAccount?> signIn() => _strategy.signIn();
  Future<void> signOut() => _strategy.signOut();
}