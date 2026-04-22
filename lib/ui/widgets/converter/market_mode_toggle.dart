import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/services/exchange_service.dart';
import 'package:yastik_alti/domain/assets/asset_catalog.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]

import '../../../domain/models/value_objects/price_quote.dart';

class MarketModeToggle extends StatelessWidget {
  final ExchangeMode currentMode;
  final Function(ExchangeMode) onModeChanged;
  final PriceQuote? fromAsset;
  final PriceQuote? toAsset;

  const MarketModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.fromAsset,
    this.toAsset,
  });

  @override
  Widget build(BuildContext context) {
    bool isPhysicalAllowed = true;
    if (fromAsset != null) isPhysicalAllowed &= AssetCatalog.isPhysicalEligible(fromAsset!.type, fromAsset!.assetCode);
    if (toAsset != null) isPhysicalAllowed &= AssetCatalog.isPhysicalEligible(toAsset!.type, toAsset!.assetCode);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.p4), // [DÜZELTİLDİ]
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd), // [DÜZELTİLDİ]
          ),
          child: Row(
            children: [
              Expanded(child: _buildSegment(AppStrings.converter.modeBank, ExchangeMode.bank, true)),
              Expanded(child: _buildSegment(AppStrings.converter.modePhysical, ExchangeMode.physical, isPhysicalAllowed)),
            ],
          ),
        ),
        if (!isPhysicalAllowed)
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.p8), // [DÜZELTİLDİ]
            child: Text(
              AppStrings.converter.modeWarning,
              style: AppTextStyles.captionBold.copyWith(color: AppColors.lossAccent),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSegment(String title, ExchangeMode mode, bool isEnabled) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: isEnabled ? () => onModeChanged(mode) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p12), // [DÜZELTİLDİ]
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm), // [DÜZELTİLDİ]
          border: isSelected ? Border.all(color: AppColors.textPrimary.withValues(alpha: AppAlphas.hover)) : null, // [DÜZELTİLDİ]
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isEnabled ? (isSelected ? AppColors.brandBlue : AppColors.textSecondary) : AppColors.textFaint,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}