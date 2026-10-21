import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/core/crypto_service.dart';
import 'package:yastik_alti/data/local/local_database.dart';
import 'package:yastik_alti/domain/services/cloud_backup_service.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';

import '../../di/providers.dart';

// 1. State Sınıfı (Durum Tutucu)
class CloudBackupState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  CloudBackupState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  // State'i immutable (değiştirilemez) tutmak için copyWith metodu
  CloudBackupState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CloudBackupState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// 2. Controller (Durum Yöneticisi)
class CloudBackupController extends StateNotifier<CloudBackupState> {
  final CloudBackupService _backupService;
  final Ref
  _ref; // Uygulama genelindeki Provider'lara erişmek için Ref enjekte edildi

  CloudBackupController(this._backupService, this._ref)
    : super(CloudBackupState());

  /// Veritabanını buluta yedekler
  Future<void> backup(String passphrase) async {
    AppLog.debug('Cloud backup started', domain: 'BACKUP');
    state = state.copyWith(isLoading: true, isSuccess: false, clearError: true);

    try {
      final success = await _backupService.backupDatabase(passphrase);
      if (success) {
        AppLog.insight('cloud_backup_success');
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        AppLog.warning('Cloud backup did not complete', domain: 'BACKUP');
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              "Yedekleme tamamlanamadı. Lütfen bağlantınızı kontrol edin.",
        );
      }
    } catch (e) {
      AppLog.error('Cloud backup failed', domain: 'BACKUP', error: e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Buluttaki yedeği cihaza geri yükler
  Future<void> restore(String passphrase) async {
    AppLog.debug('Cloud restore started', domain: 'BACKUP');
    state = state.copyWith(isLoading: true, isSuccess: false, clearError: true);

    String? error;
    try {
      await _backupService.restoreDatabase(passphrase);
    } on BackupDecryptionException {
      error = "Parola yanlış ya da yedek dosyası bozuk. Cihazdaki verileriniz değiştirilmedi.";
    } on InvalidBackupContentException {
      error = "Bu dosya geçerli bir Yastık6 yedeği değil. Cihazdaki verileriniz değiştirilmedi.";
    } on FormatException {
      error = "Bu dosya geçerli bir Yastık6 yedeği değil. Cihazdaki verileriniz değiştirilmedi.";
    } catch (e) {
      error = e.toString();
    }

    // --- [HOT SWAP] ---
    // Always reopen: after a successful restore this loads the new file, and if anything failed
    // the connection may already be closed, so the app must not keep using it.
    final newDb = await LocalDatabase.instance.resetDatabase();
    _ref.read(databaseProvider.notifier).state = newDb;
    _ref.read(portfolioProvider.notifier).refreshDb();

    if (error == null) {
      AppLog.info('Restored database swapped in, portfolio state refreshed', domain: 'BACKUP');
      AppLog.insight('cloud_restore_success');
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      AppLog.warning('Cloud restore failed: $error', domain: 'BACKUP');
      state = state.copyWith(isLoading: false, errorMessage: error);
    }
  }

  /// UI kapandığında veya işlem sonrası state'i sıfırlamak için
  void resetState() {
    state = CloudBackupState();
  }
}

// 3. Provider (Dependency Injection)
final cloudBackupControllerProvider =
    StateNotifierProvider<CloudBackupController, CloudBackupState>((ref) {
      final backupService = ref.read(cloudBackupServiceProvider);
      // Controller'a kendi işlem alanından çıkıp global state'i tetikleyebilmesi için ref yollanıyor
      return CloudBackupController(backupService, ref);
    });
