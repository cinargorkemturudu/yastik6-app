import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';

import '../states/portfolio_provider.dart';
import '../states/live_price_provider.dart';
import '../ui_models/owned_asset_list_item_model.dart';
import '../widgets/cards/asset_accordion_item.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final AssetType? categoryType;
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.categoryType,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioData = ref.watch(portfolioProvider);

    final marketState = ref.watch(livePriceProvider).valueOrNull;
    final assetNames = {
      if (marketState != null)
        for (var quote in marketState.marketAssets) quote.assetCode: quote.name
    };

    if (portfolioData.isLoading && portfolioData.snapshot.positions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = portfolioData.snapshot;

    final positions = snapshot.positions.where((p) {
      if (categoryType == null) return true;
      return p.assetType == categoryType;
    }).toList();

    final double totalValue = positions.fold(0.0, (sum, p) => sum + p.currentValue.toDouble());
    final double totalProfit = positions.fold(0.0, (sum, p) => sum + p.profit.toDouble());

    final items = positions.map((p) => OwnedAssetListItemModel(
      assetId: p.asset.id,
      type: p.assetType,
      title: assetNames[p.asset.symbol] ?? p.asset.name,
      amountText: p.totalAmount.toDouble().toStringAsFixed(2),
      currentPriceText: AppFormatter.money(p.currentPrice.toDouble()),
      totalValueText: AppFormatter.money(p.currentValue.toDouble()),
      pnlPercent: AppFormatter.percent(p.profitPct),
      pnlColor: p.profit.toDouble().toPnlColor(),
      avgCostText: AppFormatter.money(p.averageBuyPrice.toDouble()),
      pnlValueText: AppFormatter.pnlValue(p.profit.toDouble()),
    )).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          categoryName.toUpperCase(),
          style: AppTextStyles.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.p24),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.02),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint),
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.titles.totalValue.toUpperCase(),
                  style: AppTextStyles.captionBold.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: AppDimens.p8),
                Text(
                  AppFormatter.money(totalValue),
                  style: AppTextStyles.heroAmount,
                ),
                Text(
                  "${AppFormatter.pnlValue(totalProfit)} (${AppStrings.labels.totalPnl})",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: totalProfit.toPnlColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: positions.isEmpty
                ? Center(
              child: Text(
                AppStrings.messages.emptyData,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textFaint),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(AppDimens.p16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return AssetAccordionItem(model: items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}