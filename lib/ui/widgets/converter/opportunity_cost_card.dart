import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/states/asset_history_provider.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';

import '../../utils/app_safe_text.dart';

class OpportunityCostCard extends ConsumerWidget {
  final Decimal amount;
  final PriceQuote fromAsset;
  final PriceQuote toAsset;
  final Decimal currentResult;
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
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: AppAlphas.hover)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppDimens.p16),
            if (selectedDate == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
                  child: Text(
                    AppStrings.messages.emptyPastDate,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textFaint),
                  ),
                ),
              )
            else
            // Pass the unwrapped date explicitly to avoid unwrap errors later
              _buildAnalysisResult(ref, selectedDate!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
              const SizedBox(width: AppDimens.p4),
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
    );
  }

  Widget _buildAnalysisResult(WidgetRef ref, DateTime validDate) {
    final fromPriceAsync = ref.watch(historicalPriceProvider(HistoricalPriceParams(assetCode: fromAsset.assetCode, date: validDate)));
    final toPriceAsync = ref.watch(historicalPriceProvider(HistoricalPriceParams(assetCode: toAsset.assetCode, date: validDate)));

    // 1. Loading State
    if (fromPriceAsync.isLoading || toPriceAsync.isLoading) {
      return const Center(
        child: Padding(
            padding: EdgeInsets.all(AppDimens.p16),
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandBlue)
        ),
      );
    }

    // 2. Error State (Prevents the blank screen if DB/Provider fails)
    if (fromPriceAsync.hasError || toPriceAsync.hasError) {
      debugPrint("Historical Price Error - From: ${fromPriceAsync.error}, To: ${toPriceAsync.error}");
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
          child: Text(
            "Geçmiş veri yüklenirken bir hata oluştu.", // Hardcoded fallback just in case
            style: AppTextStyles.caption.copyWith(color: AppColors.lossAccent),
          ),
        ),
      );
    }

    final Decimal? pastFromPrice = fromPriceAsync.valueOrNull;
    final Decimal? pastToPrice = toPriceAsync.valueOrNull;

    // 3. Null or Invalid Data State
    if (pastFromPrice == null || pastToPrice == null || pastToPrice <= Decimal.zero) {
      return Text(
          AppStrings.messages.noPastDataFound,
          style: AppTextStyles.caption.copyWith(color: AppColors.lossAccent)
      );
    }

    // 4. Parity and Results Calculations
    Decimal parity = (pastFromPrice.toRational() / pastToPrice.toRational()).toDecimal(scaleOnInfinitePrecision: 10);
    Decimal pastResult = amount * parity;

    Decimal netDiff = currentResult - pastResult;
    double percentDiff = pastResult == Decimal.zero
        ? 0.0
        : (netDiff.toRational() / pastResult.toRational()).toDouble();

    bool isProfit = percentDiff >= 0;
    Color trendColor = isProfit ? AppColors.profitAccent : AppColors.lossAccent;

    String displayName;
    switch (toAsset.type) {
      case AssetType.stock:
      case AssetType.metal:
        displayName = toAsset.name;
        break;
      default:
        displayName = AppFormatter.cleanAssetCode(toAsset.assetCode);
        break;
    }

    // 5. Final UI Render
    return Container(
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: AppAlphas.overlay),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.converter.ifYouTradedThatDay,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimens.p4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  AppFormatter.amount(pastResult, ""),
                  style: AppTextStyles.h2.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimens.p4),
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p2),
                child: AppSafeText(
                  displayName,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppDimens.p4),
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.p2),
                child: Text(AppStrings.converter.youWouldHaveReceived, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),
          Container(height: 1, color: AppColors.textPrimary.withValues(alpha: AppAlphas.faint)),
          const SizedBox(height: AppDimens.p12),
          Row(
            children: [
              Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: trendColor, size: 20),
              const SizedBox(width: AppDimens.p6),
              Flexible(
                child: Text(
                  "${AppStrings.converter.difference} ${AppFormatter.signedAmount(netDiff)} (${AppFormatter.signedPercent(percentDiff)})",
                  style: AppTextStyles.bodyLarge.copyWith(color: trendColor, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            AppStrings.converter.pastAnalysisDisclaimer,
            style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}