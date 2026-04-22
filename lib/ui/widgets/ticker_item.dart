import 'package:flutter/material.dart';
import '../ui_models/current_rates_ticker_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]

class TickerItem extends StatelessWidget {
  final TickerItemUiModel model;
  const TickerItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final changeColor = (model.isPositive ? 1.0 : -1.0).toPnlColor();

    const baseStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
    );

    final title = (model.displayName.isNotEmpty ? model.displayName : model.assetCode);

    return Opacity(
      opacity: model.isStale ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.only(left: AppDimens.p12, right: AppDimens.p12), // [DÜZELTİLDİ]
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              style: baseStyle.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: AppDimens.p6), // [DÜZELTİLDİ]
            Text(
              model.formattedBidAsk,
              style: baseStyle.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppDimens.p6), // [DÜZELTİLDİ]
            Text(
              model.formattedChangePercent,
              style: baseStyle.copyWith(
                color: changeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppDimens.p12), // [DÜZELTİLDİ]
            Text(
              "|",
              style: TextStyle(color: AppColors.textPrimary.withValues(alpha: AppAlphas.bgMedium), fontSize: 12), // [DÜZELTİLDİ]
            ),
          ],
        ),
      ),
    );
  }
}