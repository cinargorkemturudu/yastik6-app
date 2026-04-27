import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/ui_models/owned_asset_list_item_model.dart';
import 'package:yastik_alti/ui/widgets/app_clickable_wrapper.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/widgets/asset_history_chart.dart';
import 'package:yastik_alti/ui/states/asset_history_provider.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';

class AssetAccordionItem extends ConsumerStatefulWidget {
  final OwnedAssetListItemModel model;

  const AssetAccordionItem({
    super.key,
    required this.model,
  });

  @override
  ConsumerState<AssetAccordionItem> createState() => _AssetAccordionItemState();
}

class _AssetAccordionItemState extends ConsumerState<AssetAccordionItem> {
  bool _isExpanded = false;
  PricePoint? _hoveredPoint;

  String _selectedRange = '1M';

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  String _getRangeParam(String uiRange) {
    switch (uiRange) {
      case '1D': return 'Day';
      case '1W': return 'Week';
      case '1M': return 'Month';
      case '3M': return 'ThreeMonths';
      case '1Y': return 'Year';
      default: return 'Month';
    }
  }

  Widget _buildRangeChip(String label, String rangeValue) {
    final isSelected = _selectedRange == rangeValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.brandBlue.withValues(alpha: AppAlphas.bgMedium),
      backgroundColor: AppColors.surface,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelStyle: AppTextStyles.captionBold.copyWith(
        color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
      ),
      onSelected: (_) => setState(() => _selectedRange = rangeValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mantık blokları (isStock, isMetal vs.) buradan tamamen kaldırıldı!

    return AppOutlinedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // --- HEADER (Summary Data) ---
          AppClickableWrapper(
            onTap: _toggle,
            borderRadius: AppDimens.radiusMd,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // DOĞRUDAN MODELDEN OKUNUYOR
                          "${widget.model.amountText} ${widget.model.displayTitle}",
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // DOĞRUDAN MODELDEN OKUNUYOR
                            if (widget.model.displaySubtitle != null) ...[
                              Text(widget.model.displaySubtitle!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 11)),
                              const SizedBox(width: 4),
                              Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                            ],
                            const Icon(Icons.show_chart, color: AppColors.textMuted, size: 12),
                            const SizedBox(width: AppDimens.p4),
                            Text(
                              widget.model.currentPriceText,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.model.totalValueText,
                        style: AppTextStyles.h3.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              widget.model.pnlColor == AppColors.profit ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 10,
                              color: widget.model.pnlColor
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "${widget.model.pnlValueText} (${widget.model.pnlPercent})",
                            style: AppTextStyles.captionBold.copyWith(color: widget.model.pnlColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- EXPANDED BODY (Details & Real Live Chart) ---
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.p12, 0, AppDimens.p12, AppDimens.p16),
              child: Column(
                children: [
                  Divider(color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint), height: 1),
                  const SizedBox(height: AppDimens.p12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailStat(AppStrings.labels.avgCost, widget.model.avgCostText),
                      _buildDetailStat(
                          AppStrings.labels.totalPnl,
                          widget.model.pnlValueText,
                          color: widget.model.pnlColor
                      ),
                    ],
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
                  const SizedBox(height: AppDimens.p16),

                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final params = AssetHistoryParams(
                            assetCode: widget.model.assetId,
                            range: _getRangeParam(_selectedRange)
                        );
                        final historyAsync = ref.watch(assetHistoryProvider(params));
                        final portfolioData = ref.watch(portfolioProvider);

                        return historyAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
                          error: (e, s) => Center(
                              child: Text(AppStrings.messages.chartLoadFailed, style: AppTextStyles.caption.copyWith(color: AppColors.loss))
                          ),
                          data: (data) {
                            final assetTxs = portfolioData.transactions
                                .where((tx) => tx.assetId == widget.model.assetId)
                                .toList();

                            final chartTxs = assetTxs.map((tx) => ChartTransactionPoint(
                              date: tx.purchaseDate,
                              isBuy: tx.type == TransactionType.buy,
                              amount: tx.amount.toDouble(),
                              price: tx.purchasePrice.toDouble(),
                            )).toList();

                            return AssetHistoryChart(
                              data: data,
                              transactions: chartTxs,
                              color: AppColors.getAssetColor(widget.model.assetId),
                              selectedRange: _selectedRange,
                              onScrub: (point) {
                                if (_hoveredPoint?.timestamp != point?.timestamp) {
                                  setState(() => _hoveredPoint = point);
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13
          ),
        ),
      ],
    );
  }
}