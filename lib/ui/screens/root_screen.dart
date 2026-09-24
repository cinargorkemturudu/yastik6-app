
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/screens/portfolio_screen.dart';
import 'package:yastik_alti/ui/screens/market_screen.dart';
import 'package:yastik_alti/ui/screens/converter_screen.dart';
import 'package:yastik_alti/ui/widgets/home_app_bar.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/ticker_settings_sheet.dart';
import 'package:yastik_alti/ui/states/cloud_backup_controller.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _currentIndex = 0;

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
    final cloudState = ref.watch(cloudBackupControllerProvider);
    final cloudNotifier = ref.read(cloudBackupControllerProvider.notifier);

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
      extendBody: true,
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
                leading: const Icon(Icons.settings_input_component, color: AppColors.brandBlue),
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
              ListTile(
                enabled: !cloudState.isLoading,
                leading: cloudState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined, color: AppColors.brandBlue),
                title: Text("Yedekle", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  cloudNotifier.backup();
                },
              ),
              ListTile(
                enabled: !cloudState.isLoading,
                leading: const Icon(Icons.settings_backup_restore, color: AppColors.brandBlue),
                title: Text("Geri Yükle", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showRestoreDialog();
                  if (confirm == true) {
                    cloudNotifier.restore();
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0.0),
              AppColors.background.withValues(alpha: 0.7),
              AppColors.background,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              // [SİHİRLİ DOKUNUŞ]: Mat siyahı engelleyen Material 3 katmanları tamamen sıfırlandı
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppColors.surfaceLight.withValues(alpha: 0.5),
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
          ),
        ),
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