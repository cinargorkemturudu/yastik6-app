import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/ui/ui_models/market_item_ui_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/asset_history_chart.dart';
import 'package:yastik_alti/ui/states/asset_history_provider.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';

class MarketItemDetailsSheet extends ConsumerStatefulWidget {
  final MarketItemUiModel model;

  const MarketItemDetailsSheet({super.key, required this.model});

  @override
  ConsumerState<MarketItemDetailsSheet> createState() => _MarketItemDetailsSheetState();
}

class _MarketItemDetailsSheetState extends ConsumerState<MarketItemDetailsSheet> {
  String _selectedRange = '1W';
  PricePoint? _hoveredPoint;

  @override
  Widget build(BuildContext context) {
    final rangeParam = _getRangeParam(_selectedRange);
    final params = AssetHistoryParams(assetCode: widget.model.assetCode, range: rangeParam);
    final historyAsync = ref.watch(assetHistoryProvider(params));
    final portfolioData = ref.watch(portfolioProvider);

    final assetColor = AppColors.getAssetColor(widget.model.assetCode);

    final assetTxs = portfolioData.transactions
        .where((tx) => tx.assetId == widget.model.assetCode)
        .toList();

    final List<ChartTransactionPoint> realTransactions = [];
    Decimal? realAvgCost;

    if (assetTxs.isNotEmpty) {
      Decimal totalBuyAmount = Decimal.zero;
      Decimal totalBuyCost = Decimal.zero;

      for (var tx in assetTxs) {
        Decimal txAmount = tx.amount;
        Decimal txPrice = tx.purchasePrice;

        // Safe Decimal division for average cost calculation[cite: 1]
        Decimal currentAvg = totalBuyAmount > Decimal.zero
            ? (totalBuyCost.toRational() / totalBuyAmount.toRational()).toDecimal(scaleOnInfinitePrecision: 10)
            : Decimal.zero;

        Decimal? profit;

        if (tx.type == TransactionType.sell && currentAvg > Decimal.zero) {
          profit = (txPrice - currentAvg) * txAmount;
        }

        realTransactions.add(ChartTransactionPoint(
          date: tx.purchaseDate,
          isBuy: tx.type == TransactionType.buy,
          amount: txAmount, // [FIXED]: Passed Decimal directly as per updated ChartTransactionPoint[cite: 1]
          price: txPrice,  // [FIXED]: Passed Decimal directly
          realizedProfit: profit, // [FIXED]: Removed the '?' suffix[cite: 1]
        ));

        if (tx.type == TransactionType.buy) {
          totalBuyAmount += txAmount;
          totalBuyCost += (txAmount * txPrice);
        }
      }

      if (totalBuyAmount > Decimal.zero) {
        realAvgCost = (totalBuyCost.toRational() / totalBuyAmount.toRational()).toDecimal(scaleOnInfinitePrecision: 10);
      }
    }

    final displayPriceDecimal = _hoveredPoint?.price ?? widget.model.ask;
    final isHovering = _hoveredPoint != null;

    String pnlString = "-";
    Color pnlColor = Colors.white54;

    if (realAvgCost != null) {
      final pnl = displayPriceDecimal - realAvgCost;
      final double pnlRatio = (pnl.toRational() / realAvgCost.toRational()).toDouble();

      // Delegated to AppFormatter for high-precision string representation[cite: 1]
      pnlString = "${AppFormatter.pnlValue(pnl)} (${AppFormatter.signedPercent(pnlRatio)})";
      pnlColor = pnl.toPnlColor(); // [FIXED]: Using the new Decimal extension logic[cite: 1]
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p24),
      child: SizedBox(
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.model.displayTitle, style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (widget.model.displaySubtitle != null)
                          Text(widget.model.displaySubtitle!, style: AppTextStyles.caption.copyWith(color: assetColor)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: AppDimens.p16),

              Container(
                padding: const EdgeInsets.all(AppDimens.p12),
                decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: AppAlphas.borderActive),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatWidget(
                        title: isHovering ? AppStrings.labels.selectedPrice : AppStrings.labels.currentPrice,
                        value: AppFormatter.money(displayPriceDecimal),
                        color: isHovering ? assetColor : AppColors.textPrimary
                    ),
                    _StatWidget(
                        title: AppStrings.labels.avgCost,
                        value: realAvgCost != null ? AppFormatter.money(realAvgCost) : '-',
                        color: AppColors.textSecondary
                    ),
                    _StatWidget(
                        title: AppStrings.labels.unitPnl,
                        value: pnlString,
                        color: pnlColor
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.p16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRangeChip('1G', '1D'), const SizedBox(width: AppDimens.p8),
                    _buildRangeChip('1H', '1W'), const SizedBox(width: AppDimens.p8),
                    _buildRangeChip('1A', '1M'), const SizedBox(width: AppDimens.p8),
                    _buildRangeChip('3A', '3M'), const SizedBox(width: AppDimens.p8),
                    _buildRangeChip('1Y', '1Y'),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.p24),

              Expanded(
                child: historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
                  error: (e, s) => Center(
                      child: Text(AppStrings.messages.chartLoadFailed, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.loss))
                  ),
                  data: (data) {
                    if (data.isEmpty) {
                      return Center(
                          child: Text(AppStrings.messages.noDataForRange, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted))
                      );
                    }
                    return AssetHistoryChart(
                      data: data,
                      transactions: realTransactions,
                      avgCost: realAvgCost, // [FIXED]: Removed the '?' suffix[cite: 1]
                      color: assetColor,
                      selectedRange: _selectedRange,
                      onScrub: (point) {
                        if (_hoveredPoint?.timestamp != point?.timestamp) {
                          setState(() => _hoveredPoint = point);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRangeParam(String uiRange) {
    switch (uiRange) {
      case '1D': return 'Day';
      case '1W': return 'Week';
      case '1M': return 'Month';
      case '3M': return 'ThreeMonths';
      case '1Y': return 'Year';
      default: return 'Week';
    }
  }

  Widget _buildRangeChip(String label, String rangeValue) {
    final isSelected = _selectedRange == rangeValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.brandBlue.withValues(alpha: AppAlphas.bgMedium),
      backgroundColor: AppColors.inputFill,
      showCheckmark: false,
      labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
      ),
      onSelected: (_) => setState(() => _selectedRange = rangeValue),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatWidget({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}