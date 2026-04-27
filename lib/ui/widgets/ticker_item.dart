import 'package:flutter/material.dart';
import '../ui_models/current_rates_ticker_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';

class TickerItem extends StatelessWidget {
  final TickerItemUiModel model;
  const TickerItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    // Logic delegated to AppFormatter via model
    final changeColor = (model.isPositive ? 1.0 : -1.0).toPnlColor();

    const baseStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
    );

    return Opacity(
      opacity: model.isStale ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              model.displayTitle, // Consuming pre-formatted title from model
              style: baseStyle.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: AppDimens.p6),
            Text(
              model.formattedBidAsk,
              style: baseStyle.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppDimens.p6),
            Text(
              model.formattedChangePercent,
              style: baseStyle.copyWith(
                color: changeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Text(
              "|",
              style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: AppAlphas.bgMedium),
                  fontSize: 12
              ),
            ),
          ],
        ),
      ),
    );
  }
}