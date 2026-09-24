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
          amount: txAmount,
          price: txPrice,
          realizedProfit: profit,
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

      pnlString = "${AppFormatter.pnlValue(pnl)} (${AppFormatter.signedPercent(pnlRatio)})";
      pnlColor = pnl.toPnlColor();
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
              Divider(color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint), height: AppDimens.dividerHeight),
              const SizedBox(height: AppDimens.p12),

              // --- STATS BOX REBUILT: 3-Column Expanded Layout ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatWidget(
                      title: isHovering ? AppStrings.labels.selectedPrice : AppStrings.labels.currentPrice,
                      value: AppFormatter.money(displayPriceDecimal),
                      color: isHovering ? assetColor : AppColors.textPrimary,
                      alignment: CrossAxisAlignment.start, // Left aligned
                    ),
                  ),
                  Expanded(
                    child: _StatWidget(
                      title: AppStrings.labels.avgCost,
                      value: realAvgCost != null ? AppFormatter.money(realAvgCost) : '-',
                      color: AppColors.textSecondary,
                      alignment: CrossAxisAlignment.center, // Center aligned
                    ),
                  ),
                  Expanded(
                    child: _StatWidget(
                      title: AppStrings.labels.unitPnl,
                      value: pnlString,
                      color: pnlColor,
                      alignment: CrossAxisAlignment.end, // Right aligned
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.p12),
              Divider(color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint), height: AppDimens.dividerHeight),
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
                      avgCost: realAvgCost,
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
      backgroundColor: Colors.transparent, // [GÜNCELLENDİ]: Removed dark background
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p4, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none, // [GÜNCELLENDİ]: Removed the border to match accordion
      ),
      labelStyle: AppTextStyles.captionBold.copyWith(
        color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
      ),
      onSelected: (_) => setState(() => _selectedRange = rangeValue),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final CrossAxisAlignment alignment; // [EKLENDİ]: Hizalama kontrolü

  const _StatWidget({
    required this.title,
    required this.value,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.captionBold.copyWith(
              color: AppColors.textMuted,
              fontSize: 9,
              letterSpacing: 0.5
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimens.p4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color
              )
          ),
        ),
      ],
    );
  }
}