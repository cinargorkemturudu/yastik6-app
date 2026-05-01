import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final Ref _ref; // Uygulama genelindeki Provider'lara erişmek için Ref enjekte edildi

  CloudBackupController(this._backupService, this._ref) : super(CloudBackupState());

  /// Veritabanını buluta yedekler
  Future<void> backup() async {
    state = state.copyWith(isLoading: true, isSuccess: false, clearError: true);

    try {
      final success = await _backupService.backupDatabase();
      if (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: "Yedekleme tamamlanamadı. Lütfen bağlantınızı kontrol edin."
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Buluttaki yedeği cihaza geri yükler
  Future<void> restore() async {
    state = state.copyWith(isLoading: true, isSuccess: false, clearError: true);

    try {
      final success = await _backupService.restoreDatabase();

      if (success) {
        // --- [HOT SWAP İŞLEMİ BAŞLIYOR] ---

        // 1. Eski bağlantıyı kapat ve indirilen yeni dosyadan taze bir bağlantı al
        final newDb = await LocalDatabase.instance.resetDatabase();

        // 2. Global StateProvider'ı yeni DB nesnesiyle güncelle (Bütün Repolar baştan yazılır)
        _ref.read(databaseProvider.notifier).state = newDb;

        // 3. Portföy motoruna veritabanının değiştiğini haber ver (UI yeniden çizilir)
        _ref.read(portfolioProvider.notifier).refreshDb();

        // 4. İşlemi başarıyla sonlandır
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: "Geri yükleme başarısız oldu. Bulutta yedek dosyası bulunamadı."
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// UI kapandığında veya işlem sonrası state'i sıfırlamak için
  void resetState() {
    state = CloudBackupState();
  }
}

// 3. Provider (Dependency Injection)
final cloudBackupControllerProvider = StateNotifierProvider<CloudBackupController, CloudBackupState>((ref) {
  final backupService = ref.read(cloudBackupServiceProvider);
  // Controller'a kendi işlem alanından çıkıp global state'i tetikleyebilmesi için ref yollanıyor
  return CloudBackupController(backupService, ref);
});