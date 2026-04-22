import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/states/asset_history_provider.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]

class OpportunityCostCard extends ConsumerWidget {
  final double amount;
  final PriceQuote fromAsset;
  final PriceQuote toAsset;
  final double currentResult;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const OpportunityCostCard({
    super.key,
    required this.amount,
    required this.fromAsset,
    required this.toAsset,
    required this.currentResult,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd), // [DÜZELTİLDİ]
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: AppAlphas.hover)), // [DÜZELTİLDİ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16), // [DÜZELTİLDİ]
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.converter.opportunityCost.toUpperCase(),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) onDateSelected(picked);
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.brandBlue),
                      const SizedBox(width: AppDimens.p4), // [DÜZELTİLDİ]
                      Text(
                        selectedDate != null
                            ? DateFormat('dd.MM.yyyy').format(selectedDate!)
                            : AppStrings.converter.selectDate,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: AppDimens.p16), // [DÜZELTİLDİ]

            // --- BODY ---
            if (selectedDate == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.p8), // [DÜZELTİLDİ]
                  child: Text(
                    AppStrings.messages.emptyPastDate,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textFaint),
                  ),
                ),
              )
            else
              _buildAnalysisResult(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(WidgetRef ref) {
    final fromPriceAsync = ref.watch(historicalPriceProvider(HistoricalPriceParams(assetCode: fromAsset.assetCode, date: selectedDate!)));
    final toPriceAsync = ref.watch(historicalPriceProvider(HistoricalPriceParams(assetCode: toAsset.assetCode, date: selectedDate!)));

    if (fromPriceAsync.isLoading || toPriceAsync.isLoading) {
      return const Center(
        child: Padding(
            padding: EdgeInsets.all(AppDimens.p16), // [DÜZELTİLDİ]
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandBlue)
        ),
      );
    }

    final pastFromPrice = fromPriceAsync.valueOrNull;
    final pastToPrice = toPriceAsync.valueOrNull;

    if (pastFromPrice == null || pastToPrice == null) {
      return Text(AppStrings.messages.noPastDataFound,
          style: AppTextStyles.caption.copyWith(color: AppColors.lossAccent));
    }

    double pastResult = amount * (pastFromPrice / pastToPrice);
    double netDiff = currentResult - pastResult;
    double percentDiff = pastResult == 0 ? 0 : (netDiff / pastResult) * 100;

    bool isProfit = percentDiff >= 0;
    Color trendColor = isProfit ? AppColors.profitAccent : AppColors.lossAccent;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p12), // [DÜZELTİLDİ]
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: AppAlphas.overlay), // [DÜZELTİLDİ]
        borderRadius: BorderRadius.circular(AppDimens.radiusSm), // [DÜZELTİLDİ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.converter.ifYouTradedThatDay,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimens.p4), // [DÜZELTİLDİ]
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pastResult.toStringAsFixed(4),
                style: AppTextStyles.h2.copyWith(fontSize: 18),
              ),
              const SizedBox(width: AppDimens.p4), // [DÜZELTİLDİ]
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p2), // [DÜZELTİLDİ]
                child: Text(
                  toAsset.assetCode,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppDimens.p4), // [DÜZELTİLDİ]
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p2), // [DÜZELTİLDİ]
                child: Text(AppStrings.converter.youWouldHaveReceived, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12), // [DÜZELTİLDİ]
          Container(height: 1, color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint)), // [DÜZELTİLDİ]
          const SizedBox(height: AppDimens.p12), // [DÜZELTİLDİ]
          Row(
            children: [
              Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: trendColor, size: 20),
              const SizedBox(width: AppDimens.p6), // [DÜZELTİLDİ]
              Text(
                "${AppStrings.converter.difference} ${isProfit ? '+' : ''}${netDiff.toStringAsFixed(4)} (${isProfit ? '+' : ''}${percentDiff.toStringAsFixed(2)}%)",
                style: AppTextStyles.bodyLarge.copyWith(color: trendColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p8), // [DÜZELTİLDİ]
          Text(
            AppStrings.converter.pastAnalysisDisclaimer,
            style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}