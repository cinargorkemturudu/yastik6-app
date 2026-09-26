import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/states/home_view_model.dart';
import 'package:yastik_alti/ui/ui_models/lot_ui_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:collection/collection.dart';

class LotCard extends ConsumerStatefulWidget {
  final LotUiModel model;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LotCard({super.key, required this.model, this.onEdit, this.onDelete});

  @override
  ConsumerState<LotCard> createState() => _LotCardState();
}

class _LotCardState extends ConsumerState<LotCard> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  bool get _hasNote {
    return widget.model.note != null && widget.model.note!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.model.isSellCard) {
      return _buildSellSlip();
    }

    return AppOutlinedCard(
      onTap: _toggle,
      borderColor: Colors.black,
      backgroundColor: AppColors.brandBlue.withValues(alpha: AppAlphas.tint),
      child: Column(
        children: [
          _buildHeader(context, ref),

          if (_isExpanded) ...[
            const SizedBox(height: AppDimens.p12),
            Divider(
              color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint),
              height: 1,
            ),
            const SizedBox(height: AppDimens.p12),
            _buildExpandedDetails(ref),
          ],
        ],
      ),
    );
  }

  Widget _buildSellSlip() {
    return AppOutlinedCard(
      borderColor: Colors.black,
      backgroundColor: AppColors.brandBlue.withValues(alpha: AppAlphas.tint),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: AppColors.lossAccent,
            size: 16,
          ),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.labels.sell.toUpperCase(),
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.lossAccent,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      " - ${widget.model.dateText}",
                      style: AppTextStyles.captionBold.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _hasNote ? widget.model.note! : widget.model.displayTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "- ${widget.model.originalAmountText}",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.lossAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.model.buyPriceText,
                style: AppTextStyles.captionBold.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isRealizedMode = ref.watch(
      homeViewModelProvider.select((value) => value.isRealizedMode),
    );

    final pnlText = isRealizedMode
        ? widget.model.totalRealizedPnl
        : widget.model.currentUnrealizedPnl;
    final pnlColor = isRealizedMode
        ? widget.model.realizedColor
        : widget.model.unrealizedColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_hasNote) ...[
                Text(
                  widget.model.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionBold.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                widget.model.dateText,
                style: AppTextStyles.captionBold.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppDimens.p8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.model.originalAmountText} ${widget.model.displayTitle}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.model.totalCostText,
                style: AppTextStyles.captionBold.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (pnlText != null)
              Text(
                pnlText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: pnlColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              widget.model.profitPercent,
              style: AppTextStyles.captionBold.copyWith(
                color: pnlColor,
                fontSize: 10,
              ),
            ),
          ],
        ),

        const SizedBox(width: AppDimens.p6),
        Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: AppColors.brandBlue,
          size: 18,
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final position = portfolio.snapshot.positions.firstWhereOrNull(
      (p) => p.asset.symbol == widget.model.symbol,
    );
    final generalAvgCostText = position != null
        ? AppFormatter.money(position.averageBuyPrice)
        : "-";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.p10),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: AppAlphas.overlay),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  AppStrings.labels.activeRemaining.toUpperCase(),
                  widget.model.remainingAmountText,
                  widget.model.currentUnrealizedPnl ?? "-",
                  widget.model.unrealizedColor ?? AppColors.textPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppColors.textPrimary.withValues(
                  alpha: AppAlphas.bgMedium,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  AppStrings.labels.realizedSold.toUpperCase(),
                  widget.model.soldAmountText,
                  widget.model.totalRealizedPnl ?? "0 TL",
                  widget.model.realizedColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimens.p12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${AppStrings.labels.buy}: ${widget.model.buyPriceText}",
                  style: AppTextStyles.captionBold.copyWith(fontSize: 9),
                ),
                Text(
                  "${AppStrings.labels.avgCost} $generalAvgCostText",
                  style: AppTextStyles.captionBold.copyWith(fontSize: 9),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p4),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
              child: LinearProgressIndicator(
                value: widget.model.progressVal,
                backgroundColor: AppColors.lossAccent.withValues(
                  alpha: AppAlphas.bgMedium,
                ),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.profitAccent,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),

        if (widget.model.allocations.isNotEmpty) ...[
          const SizedBox(height: AppDimens.p12),
          ...widget.model.allocations.map(
            (sale) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.p6),
              child: Row(
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right,
                    color: AppColors.brandBlue,
                    size: 12,
                  ),
                  const SizedBox(width: AppDimens.p6),
                  Text(
                    sale.date,
                    style: AppTextStyles.captionBold.copyWith(fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    "-${sale.amount}",
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.lossAccent,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: AppDimens.p8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      sale.profitText,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.captionBold.copyWith(
                        color: sale.profitColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: AppDimens.p4),
        Divider(
          color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onEdit != null)
              TextButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(
                  Icons.edit,
                  size: 12,
                  color: AppColors.brandBlue,
                ),
                label: Text(
                  AppStrings.common.edit.toUpperCase(),
                  style: AppTextStyles.captionBold.copyWith(fontSize: 10),
                ),
              ),
            if (widget.onDelete != null)
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete,
                  size: 12,
                  color: AppColors.brandBlue,
                ),
                label: Text(
                  AppStrings.common.delete.toUpperCase(),
                  style: AppTextStyles.captionBold.copyWith(fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String subTitle,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.captionBold.copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            subTitle,
            style: AppTextStyles.captionBold.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
