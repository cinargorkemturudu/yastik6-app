import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // [EKLENDİ]: Riverpod gücü
import 'package:yastik_alti/ui/screens/portfolio_screen.dart';
import 'package:yastik_alti/ui/screens/market_screen.dart';
import 'package:yastik_alti/ui/screens/converter_screen.dart';
import 'package:yastik_alti/ui/widgets/home_app_bar.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/ticker_settings_sheet.dart';
import 'package:yastik_alti/ui/states/cloud_backup_controller.dart'; // [EKLENDİ]: Köprümüz

// [DÜZELTİLDİ]: Sınıf artık Riverpod ConsumerStatefulWidget
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _currentIndex = 0;
  // [SİLİNDİ]: _isCloudLoading ve _connectedEmail artık burada değil, Controller'da!
  // [SİLİNDİ]: O devasa _handleCloudAction metodu çöpe atıldı!

  final List<Widget> _screens = const [
    PortfolioScreen(),
    MarketScreen(),
    ConverterScreen(),
  ];

  void _showStatusMessage(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [YENİ EKLENDİ]: Riverpod State ve Controller bağlantısı
    final cloudState = ref.watch(cloudBackupControllerProvider);
    final cloudNotifier = ref.read(cloudBackupControllerProvider.notifier);

    // [YENİ EKLENDİ]: State değişimlerini gizlice dinleyip ekrana popup fırlatan yapı
    ref.listen(cloudBackupControllerProvider, (prev, next) {
      if (next.isLoading && !(prev?.isLoading ?? false)) {
        _showStatusMessage("Bulut işlemi başlatıldı, lütfen bekleyin...", AppColors.brandBlue);
      } else if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        _showStatusMessage("İşlem başarıyla tamamlandı!", AppColors.profitAccent);
      } else if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        _showStatusMessage(next.errorMessage!, AppColors.lossAccent);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HomeAppBar(),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p24),
                child: Text(AppStrings.common.menu, style: AppTextStyles.h2),
              ),

              const Divider(height: AppDimens.dividerHeight, color: AppColors.surfaceLight),

              ListTile(
                leading: const Icon(Icons.settings_input_component, color: AppColors.textPrimary),
                title: Text(AppStrings.titles.tickerCustomization, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const TickerSettingsSheet(),
                  );
                },
              ),

              // --- YEDEKLE BUTONU ---
              ListTile(
                enabled: !cloudState.isLoading, // [DÜZELTİLDİ]: UI kilitlemesini State yapıyor
                leading: cloudState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined, color: AppColors.brandBlue),
                title: Text("Yedekle", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context); // Menüyü kapat
                  cloudNotifier.backup(); // [DÜZELTİLDİ]: Motoru doğrudan Riverpod tetikliyor
                },
              ),

              // --- GERİ YÜKLE BUTONU ---
              ListTile(
                enabled: !cloudState.isLoading,
                leading: const Icon(Icons.settings_backup_restore, color: AppColors.lossAccent),
                title: Text("Geri Yükle", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showRestoreDialog();
                  if (confirm == true) {
                    cloudNotifier.restore(); // [DÜZELTİLDİ]: Motoru doğrudan Riverpod tetikliyor
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.surfaceLight,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary),
            selectedIcon: const Icon(Icons.account_balance_wallet, color: AppColors.brandBlue),
            label: AppStrings.navigation.portfolio,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_outlined, color: AppColors.textSecondary),
            selectedIcon: const Icon(Icons.show_chart, color: AppColors.brandBlue),
            label: AppStrings.navigation.market,
          ),
          NavigationDestination(
            icon: const Icon(Icons.currency_exchange_outlined, color: AppColors.textSecondary),
            selectedIcon: const Icon(Icons.currency_exchange, color: AppColors.brandBlue),
            label: AppStrings.navigation.converter,
          ),
        ],
      ),
    );
  }

  Future<bool?> _showRestoreDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verileri Geri Yükle?"),
        content: const Text("Buluttaki yedeğiniz indirilecek ve cihazdaki mevcut verilerinizin üzerine yazılacaktır. Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Geri Yükle", style: TextStyle(color: AppColors.lossAccent))),
        ],
      ),
    );
  }
}