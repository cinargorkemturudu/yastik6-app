import 'package:flutter/material.dart';
import '../ui_models/current_rates_ticker_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import '../utils/app_formatter.dart';

class TickerItem extends StatelessWidget {
  final TickerItemUiModel model;
  const TickerItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final changeColor = model.isNeutral
        ? const Color(0xFF9E9E9E)
        : (model.isPositive ? const Color(0xFF4CAF50) : const Color(0xFFE53935));

    const baseStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
    );

    final percentText = model.isNeutral
        ? '%0,00'
        : AppFormatter.signedPercent(model.changePercent / 100);

    return Opacity(
      opacity: model.isStale ? 0.4 : 1.0,
      child: Container(
        // Padding daraltıldı (p12 -> p8)
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              model.displayTitle,
              style: baseStyle.copyWith(fontWeight: FontWeight.w800),
            ),
            // İç boşluklar daraltıldı (p6 -> p4)
            const SizedBox(width: AppDimens.p4),
            Text(
              model.formattedBidAsk,
              style: baseStyle.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppDimens.p4),

            // Nötr değilse ok işaretini ve boşluğunu göster
            if (!model.isNeutral) ...[
              Text(
                model.trendArrow,
                style: baseStyle.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
            ],

            Text(
              percentText,
              style: baseStyle.copyWith(
                color: changeColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Ayırıcı çizgi öncesi boşluk daraltıldı (p12 -> p8)
            const SizedBox(width: AppDimens.p8),
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