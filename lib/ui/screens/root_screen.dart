import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/services/cloud_backup_service.dart';
import 'package:yastik_alti/ui/screens/portfolio_screen.dart';
import 'package:yastik_alti/ui/screens/market_screen.dart';
import 'package:yastik_alti/ui/screens/converter_screen.dart';
import 'package:yastik_alti/ui/widgets/home_app_bar.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/ticker_settings_sheet.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  bool _isCloudLoading = false; // Yedekleme/Geri yükleme sırasında UI'ı kilitler
  String? _connectedEmail; // Bağlı olan hesabı göstermek için

  final List<Widget> _screens = const [
    PortfolioScreen(),
    MarketScreen(),
    ConverterScreen(),
  ];

  // =========================================================================
  // BULUT İŞLEM YÖNETİCİSİ (Backup & Restore)
  // =========================================================================
  Future<void> _handleCloudAction(bool isBackup) async {
    if (_isCloudLoading) return;

    setState(() => _isCloudLoading = true);
    final backupService = CloudBackupService();

    try {
      final account = await backupService.signIn();
      if (!mounted) return;

      if (!Platform.isIOS && account == null) {
        _showStatusMessage(AppStrings.messages.loginCanceled, AppColors.lossAccent);
        setState(() => _isCloudLoading = false);
        return;
      }

      setState(() => _connectedEmail = account?.email);

      _showStatusMessage(
        isBackup ? "Buluta yedekleniyor..." : "Yedek indiriliyor...",
        AppColors.brandBlue,
      );

      // Dinamik olarak backup veya restore metodunu çağırır
      final success = isBackup
          ? await backupService.backupDatabase()
          : await backupService.restoreDatabase();

      if (!mounted) return;

      if (success) {
        _showStatusMessage(
            isBackup ? "Yedekleme başarılı!" : "Geri yükleme başarılı! Lütfen uygulamayı yeniden başlatın.",
            AppColors.profitAccent
        );
      } else {
        _showStatusMessage("İşlem başarısız oldu. Yedek bulunamadı veya hata oluştu.", AppColors.lossAccent);
      }
    } catch (e) {
      _showStatusMessage("Bir hata oluştu: $e", AppColors.lossAccent);
    } finally {
      if (mounted) setState(() => _isCloudLoading = false);
    }
  }

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

              if (_connectedEmail != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
                  child: Text("Bağlı: $_connectedEmail", style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue)),
                ),
                const SizedBox(height: 8),
              ],

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
                enabled: !_isCloudLoading,
                leading: _isCloudLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.cloud_upload_outlined, color: AppColors.brandBlue),
                title: Text("Yedekle", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _handleCloudAction(true);
                },
              ),

              // --- GERİ YÜKLE BUTONU ---
              ListTile(
                enabled: !_isCloudLoading,
                leading: const Icon(Icons.settings_backup_restore, color: AppColors.lossAccent),
                title: Text("Geri Yükle", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showRestoreDialog();
                  if (confirm == true) _handleCloudAction(false);
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