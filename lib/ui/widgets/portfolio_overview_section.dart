import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/ui_models/portfolio_donut_model.dart';
import 'package:yastik_alti/ui/ui_models/lot_ui_model.dart';
import 'package:yastik_alti/ui/states/home_view_model.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/mappers/universal_portfolio_mapper.dart';
import '../../domain/models/entities/transaction.dart';
import '../states/live_price_provider.dart';
import '../theme/app_text_style.dart';
import '../utils/app_formatter.dart';
import 'current_rates_ticker_section.dart';
import 'edit_transaction/edit_transaction_sheet.dart';
import 'portfolio_donut.dart';
import 'package:yastik_alti/ui/widgets/recent_lots_section.dart';
import 'package:yastik_alti/ui/screens/history_screen.dart';

class PortfolioOverviewSection extends ConsumerWidget {
  final String title;
  final AssetType? filterType;
  final Function(TransactionType) onTransaction;
  final VoidCallback onLegendTap;

  const PortfolioOverviewSection({
    super.key,
    required this.title,
    required this.filterType,
    required this.onTransaction,
    required this.onLegendTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioData = ref.watch(portfolioProvider);
    final uiState = ref.watch(homeViewModelProvider);
    final vmNotifier = ref.read(homeViewModelProvider.notifier);
    final marketState = ref.watch(livePriceProvider).valueOrNull;

    final Map<String, String> assetNames = {};
    if (marketState != null) {
      for (var quote in marketState.marketAssets) {
        assetNames[quote.assetCode] = quote.name;
      }
    }

    PortfolioDonutModel currentDonut;
    List<LotUiModel> allLots;

    if (uiState.isRealizedMode) {
      final summary = portfolioData.realizedSummary;

      if (summary != null) {
        currentDonut = UniversalPortfolioMapper.toRealizedDonutModel(summary, filterType, assetNames);
        allLots = UniversalPortfolioMapper.toRealizedLotUiModels(summary: summary, assetNames: assetNames, assetFilter: filterType);
      } else {
        currentDonut = PortfolioDonutModel(
            totalTl: Decimal.zero,
            totalPnlTl: Decimal.zero,
            totalPnlPct: 0,
            totalValueText: AppFormatter.money(Decimal.zero),
            // [FIXED] Added the missing required parameter here
            totalPnlText: "${AppFormatter.pnlValue(Decimal.zero)} (${AppFormatter.signedPercent(0)})",
            pnlColor: AppColors.textPrimary,
            items: []
        );
        allLots = [];
      }
    } else {
      currentDonut = UniversalPortfolioMapper.toDonutModel(portfolioData.snapshot, filterType, assetNames);
      allLots = UniversalPortfolioMapper.toLotUiModels(positions: portfolioData.snapshot.positions, allocationsMap: portfolioData.allocationsMap, assetNames: assetNames, assetFilter: filterType);
    }

    final recentLots = allLots.take(5).toList();

    return SafeArea(
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.pagePadding, horizontal: AppDimens.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CurrentRatesTickerSection(),
              const SizedBox(height: AppDimens.p10),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.titles.profitMode.toUpperCase(),
                    style: AppTextStyles.captionBold.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5
                    ),
                  ),
                  const SizedBox(width: AppDimens.p4),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: uiState.isRealizedMode,
                      onChanged: (_) => vmNotifier.toggleRealizedMode(),
                      activeThumbColor: AppColors.profitAccent,
                      trackColor: WidgetStateProperty.all(Colors.white.withValues(alpha: AppAlphas.hover)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.p10),

              Text(
                title,
                style: AppTextStyles.h2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppDimens.p10),

              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currentDonut.totalValueText,
                  style: AppTextStyles.heroAmount.copyWith(fontSize: 34),
                ),
              ),

              if (!uiState.isRealizedMode)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      currentDonut.totalPnlText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: currentDonut.pnlColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppDimens.p16),

              SizedBox(
                height: AppDimens.donutSectionHeight,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: PortfolioDonut(
                    data: currentDonut,
                    onTransaction: onTransaction,
                    onLegendTap: onLegendTap,
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.p24),

              if (recentLots.isNotEmpty)
                RecentLotsSection(
                  lots: recentLots,
                  onShowAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  onDelete: (id) => _showDeleteConfirmDialog(context, vmNotifier, id),
                  onEdit: (id) => EditTransactionSheet.show(context, ref, transactionId: id), // [FIXED]: Artık sayfayı açıyor
                ),
              const SizedBox(height: AppDimens.p40),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, HomeViewModel vmNotifier, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(AppStrings.messages.deleteWarningTitle, style: AppTextStyles.h3),
        content: Text(
            AppStrings.messages.deleteWarningBody,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)
        ),
        actions: [
          TextButton(
            child: Text(
                AppStrings.common.cancel.toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text(
                AppStrings.common.delete.toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.lossAccent)
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vmNotifier.deleteTransaction(id);
            },
          ),
        ],
      ),
    );
  }
}