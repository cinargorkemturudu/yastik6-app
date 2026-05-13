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

  // Kripto Marka Renkleri
  static const Color ethereumBlue = Color(0xFF627EEA);
  static const Color litecoinSilver = Color(0xFF345D9D);
  static const Color dogeGold = Color(0xFFC2A633);
  static const Color solanaPurple = Color(0xFF9945FF);
  static const Color avaxRed = Color(0xFFE84142);
  static const Color bnbYellow = Color(0xFFF3BA2F);
  static const Color xrpDark = Color(0xFF23292F);
  static const Color tetherGreen = Color(0xFF26A17B);
  static const Color adaBlue = Color(0xFF0033AD);
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
    'TRY': 'tr',
  };

  // --- MERKEZİ İSİMLENDİRME HARİTASI ---
  static const Map<String, String> _assetNames = {
    'USD': 'Amerikan Doları',
    'EUR': 'Euro',
    'GBP': 'İngiliz Sterlini',
    'CHF': 'İsviçre Frangı',
    'CAD': 'Kanada Doları',
    'TRY': 'Türk Lirası',
    'AUD': 'Avustralya Doları',
    'SAR': 'Suudi Arabistan Riyali',
    'JPY': 'Japon Yeni',
  };

  /// Varlık kodunu alıp merkezi haritadaki tam ismi döndürür.
  /// Eğer haritada yoksa, API'den gelen temizlenmiş ismi (fallbackName) kullanır.
  static String getName(String code, String fallbackName) {
    return _assetNames[code] ?? fallbackName;
  }

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

    // 1. MdiIcons Destekli Majörler (İkon + Renk)
    // StartsWith kullanarak SOLUSDT gibi paritelerde sondaki USDT'nin eşleşmesini engelliyoruz.
    if (cleanCode.startsWith('BTC')) return _buildIconAvatar(MdiIcons.bitcoin, AppColors.crypto);
    if (cleanCode.startsWith('ETH')) return _buildIconAvatar(MdiIcons.ethereum, _VisualConstants.ethereumBlue);
    if (cleanCode.startsWith('LTC')) return _buildIconAvatar(MdiIcons.litecoin, _VisualConstants.litecoinSilver);

    // 2. Yeni Nesil Yıldızlar (Marka Rengi + Baş Harf)
    if (cleanCode.startsWith('USDT')) return _buildColoredTextAvatar(code, _VisualConstants.tetherGreen);
    if (cleanCode.startsWith('BNB')) return _buildColoredTextAvatar(code, _VisualConstants.bnbYellow);
    if (cleanCode.startsWith('SOL')) return _buildColoredTextAvatar(code, _VisualConstants.solanaPurple);
    if (cleanCode.startsWith('AVAX')) return _buildColoredTextAvatar(code, _VisualConstants.avaxRed);
    if (cleanCode.startsWith('XRP')) return _buildColoredTextAvatar(code, _VisualConstants.xrpDark);
    if (cleanCode.startsWith('ADA')) return _buildColoredTextAvatar(code, _VisualConstants.adaBlue);
    if (cleanCode.startsWith('DOGE')) return _buildColoredTextAvatar(code, _VisualConstants.dogeGold);

    // 3. Geri Kalan Tüm Altcoin Ordusu (Jenerik Stilize Harf)
    return _buildTextAvatar(code);
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
      backgroundColor: color.withValues(alpha: _VisualConstants.bgOpacity),
      child: Icon(icon, color: color, size: _VisualConstants.iconSize),
    );
  }

  // Hisse senetleri ve bilinmeyen altcoinler için standart avatar
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

  // Yeni nesil kriptolar için marka renkli özel avatar
  static Widget _buildColoredTextAvatar(String code, Color color) {
    final letter = code.isNotEmpty ? code[0].toUpperCase() : _VisualConstants.fallbackLetter;

    return CircleAvatar(
      radius: _VisualConstants.avatarRadius,
      backgroundColor: color.withValues(alpha: _VisualConstants.bgOpacity),
      child: Text(
        letter,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: color),
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