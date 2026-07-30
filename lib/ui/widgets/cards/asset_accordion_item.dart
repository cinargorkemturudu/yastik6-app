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
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p4, vertical: 0),
      labelStyle: AppTextStyles.captionBold.copyWith(
        color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
      ),
      onSelected: (_) => setState(() => _selectedRange = rangeValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfit = widget.model.pnlColor != AppColors.lossAccent;
    final Color dailyColor = widget.model.pnlColor;
    final IconData dailyIcon = isProfit ? Icons.arrow_upward : Icons.arrow_downward;
    final String dailyChangeText = widget.model.pnlPercent;

    return AppOutlinedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // --- HEADER: 3 SÜTUNLU KONSOLİDE YAPI ---
          AppClickableWrapper(
            onTap: _toggle,
            borderRadius: AppDimens.radiusMd,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Kısım: Sembol/İsim ve Fiyat/Günlük Değişim
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [DÜZELTİLDİ]: Sol tarafı tamamen Expanded içine aldık
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.model.displayTitle,
                              style: AppTextStyles.h2.copyWith(fontSize: 18, letterSpacing: 0.5),
                              maxLines: 2, // 2 satırdan sonrasını keser
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDimens.p2),
                            if (widget.model.displaySubtitle != null)
                              Text(
                                widget.model.displaySubtitle!,
                                style: AppTextStyles.caption.copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppDimens.p12), // Sağ sütunla araya nefes boşluğu

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              widget.model.currentPriceText,
                              style: AppTextStyles.priceLarge.copyWith(fontSize: 16)
                          ),
                          const SizedBox(height: AppDimens.p4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p6, vertical: AppDimens.p2),
                            decoration: BoxDecoration(
                              color: dailyColor.withValues(alpha: AppAlphas.bgLight),
                              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(dailyIcon, color: dailyColor, size: AppDimens.iconXs),
                                const SizedBox(width: AppDimens.p2),
                                Text(
                                    dailyChangeText,
                                    style: AppTextStyles.captionBold.copyWith(color: dailyColor, fontSize: 11)
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.p12),
                  Divider(color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint), height: AppDimens.dividerHeight),
                  const SizedBox(height: AppDimens.p12),

                  // Alt Kısım: 3 Sütunlu İstatistikler 
                  // [DÜZELTİLDİ]: Her bir istatistik sütunu Expanded ile sarıldı, sayılar büyüse bile taşamaz.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLabeledStat(
                          AppStrings.form.amount,
                          widget.model.amountText,
                          AppColors.textPrimary,
                          subText: widget.model.totalValueText,
                          alignment: CrossAxisAlignment.start,
                        ),
                      ),
                      Expanded(
                        child: _buildLabeledStat(
                          AppStrings.labels.avgCost,
                          widget.model.avgCostText,
                          AppColors.textPrimary,
                          alignment: CrossAxisAlignment.center,
                        ),
                      ),
                      Expanded(
                        child: _buildLabeledStat(
                          AppStrings.labels.totalPnl,
                          widget.model.pnlValueText,
                          widget.model.pnlColor,
                          subText: widget.model.pnlPercent,
                          alignment: CrossAxisAlignment.end, // En sağdaki sütunu sağa dayıyoruz
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // --- EXPANDED BODY: CANLI GRAFİK ---
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.p12, 0, AppDimens.p12, AppDimens.p16),
              child: Column(
                children: [
                  Divider(color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint), height: AppDimens.dividerHeight),
                  const SizedBox(height: AppDimens.p12),

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
                              amount: tx.amount,
                              price: tx.purchasePrice,
                            )).toList();

                            return AssetHistoryChart(
                              data: data,
                              transactions: chartTxs,
                              color: AppColors.getAssetColor(widget.model.assetId),
                              selectedRange: _selectedRange,
                              onScrub: (point) {
                                if (_hoveredPoint?.timestamp != point?.timestamp) {
                                  Future.microtask(() {
                                    if (mounted) setState(() => _hoveredPoint = point);
                                  });
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

  // Özel alignment alacak şekilde güncellendi
  Widget _buildLabeledStat(String label, String value, Color valueColor, {String? subText, required CrossAxisAlignment alignment}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
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
          fit: BoxFit.scaleDown, // Sayı çok devasa olursa fontu küçültür, yan sütuna taşmaz
          child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold
              )
          ),
        ),
        if (subText != null) ...[
          const SizedBox(height: AppDimens.p2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
                subText,
                style: AppTextStyles.caption.copyWith(
                    color: valueColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500
                )
            ),
          ),
        ]
      ],
    );
  }
}