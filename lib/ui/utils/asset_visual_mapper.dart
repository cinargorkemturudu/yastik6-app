import 'package:flutter/material.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';

import '../theme/app_strings.dart';

class _VisualConstants {
  static const double avatarSize = 40.0;
  static const double avatarRadius = avatarSize / 2;
  static const double iconSize = 22.0;
  static const double bgOpacity = 0.12;
  static const String fallbackCountryCode = 'tr';
  static const String fallbackLetter = '?';

  static const Color ethereumBlue = Color(0xFF627EEA);
}

class AssetVisualMapper {
  AssetVisualMapper._();

  static const Map<String, String> _currencyToCountryMap = {
    'USD': 'us',
    'GBP': 'gb',
    'CHF': 'ch',
    'JPY': 'jp',
    'CAD': 'ca',
    'AUD': 'au',
    'SAR': 'sa',
  };

  static Widget getAvatar({
    required String assetCode,
    required AssetType type,
  }) {
    switch (type) {
      case AssetType.currency:
        final cleanCode = assetCode.toUpperCase();
        if (cleanCode.contains('EUR')) {
          return _buildIconAvatar(MdiIcons.currencyEur, AppColors.brandBlue);
        }
        final countryCode = _resolveCountryCode(assetCode);
        return CircleFlag(countryCode, size: _VisualConstants.avatarSize);

      case AssetType.crypto:
        return _resolveCryptoAvatar(assetCode);

      case AssetType.metal:
        final metalColor = _resolveMetalColor(assetCode);
        return _buildIconAvatar(MdiIcons.gold, metalColor);

      case AssetType.indicator:
        return _buildIconAvatar(Icons.query_stats, AppColors.textMuted);

      case AssetType.stock:
        return _buildTextAvatar(assetCode);
    }
  }

  static Widget _resolveCryptoAvatar(String code) {
    final cleanCode = code.toUpperCase();

    if (cleanCode.contains('ETH')) {
      return _buildIconAvatar(MdiIcons.ethereum, _VisualConstants.ethereumBlue);
    }
    else if (cleanCode.contains('BTC')) {
      return _buildIconAvatar(MdiIcons.bitcoin, AppColors.crypto);
    }

    return _buildIconAvatar(Icons.currency_exchange, AppColors.textPrimary);
  }

  static Color _resolveMetalColor(String code) {
    final cleanCode = code.toUpperCase();
    if (cleanCode.contains('GÜMÜŞ') || cleanCode.contains('XAG')) {
      return AppColors.silver;
    }
    return AppColors.metal;
  }

  static String _resolveCountryCode(String code) {
    final cleanCode = code.toUpperCase();
    for (final entry in _currencyToCountryMap.entries) {
      if (cleanCode.contains(entry.key)) {
        return entry.value;
      }
    }
    return _VisualConstants.fallbackCountryCode;
  }

  static Widget _buildIconAvatar(IconData icon, Color color) {
    return CircleAvatar(
      radius: _VisualConstants.avatarRadius,
      // [DÜZELTİLDİ]: withOpacity -> withValues
      backgroundColor: color.withValues(alpha: _VisualConstants.bgOpacity),
      child: Icon(icon, color: color, size: _VisualConstants.iconSize),
    );
  }

  static Widget _buildTextAvatar(String code) {
    final letter = code.isNotEmpty
        ? code[0].toUpperCase()
        : _VisualConstants.fallbackLetter;

    return CircleAvatar(
      radius: _VisualConstants.avatarRadius,
      backgroundColor: AppColors.surfaceLight,
      child: Text(
        letter,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  static String categoryNameOf(AssetType type) {
    switch (type) {
      case AssetType.metal:
        return AppStrings.categories.metal;
      case AssetType.currency:
        return AppStrings.categories.currency;
      case AssetType.stock:
        return AppStrings.categories.stock;
      case AssetType.crypto:
        return AppStrings.categories.crypto;
      case AssetType.indicator:
        return AppStrings.categories.indicator;
    }
  }
}