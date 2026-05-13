import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import '../../domain/models/entities/asset.dart';

class MarketItemUiModel {
  final String assetCode;
  final String name;
  final Decimal ask;
  final Decimal bid;
  final String formattedAsk;
  final String formattedBid;
  final String changeRateText;
  final Color trendColor;
  final IconData trendIcon;
  final AssetType type;
  final String displayTitle;
  final String? displaySubtitle;

  MarketItemUiModel({
    required this.assetCode,
    required this.name,
    required this.ask,
    required this.bid,
    required this.formattedAsk,
    required this.formattedBid,
    required this.changeRateText,
    required this.trendColor,
    required this.trendIcon,
    required this.type,
    required this.displayTitle,
    required this.displaySubtitle,
  });

  factory MarketItemUiModel.fromQuote(PriceQuote quote) {
    // Calculate the raw decimal value for percentage calculations
    final double changeRateDouble = quote.changeRate;
    final double rawDecimal = changeRateDouble / 100;

    // Determine the appropriate trend indicator icon
    IconData icon = Icons.remove;
    if (changeRateDouble > 0) icon = Icons.arrow_drop_up;
    if (changeRateDouble < 0) icon = Icons.arrow_drop_down;

    // 1. Sanitize the asset code to remove parity artifacts (e.g., "USD/TRY" -> "USD")
    final String cleanCode = AppFormatter.cleanAssetCode(quote.assetCode);

    // 2. Resolve the display name from the visual mapper, falling back to sanitized API name
    final String displayName = AssetVisualMapper.getName(
        cleanCode,
        AppFormatter.cleanAssetName(quote.name)
    );

    // --- PRESENTATION HIERARCHY ---
    String title;
    String? subtitle;

    switch (quote.type) {
      case AssetType.currency:
      // Currencies: Full Name as Title (e.g., "Amerikan Doları"), Code as Subtitle (e.g., "USD")
        title = displayName;
        subtitle = cleanCode;
        break;
      case AssetType.stock:
      // Stocks: Full Name as Title, Ticker Code as Subtitle
        title = displayName;
        subtitle = cleanCode;
        break;
      case AssetType.metal:
      // Metals: Full Name as Title, no Subtitle required
        title = displayName;
        subtitle = null;
        break;
      default:
      // Cryptocurrencies and others: Ticker Code as Title (e.g., "BTC"), Full Name as Subtitle
        title = cleanCode;
        subtitle = displayName;
        break;
    }

    // Assign appropriate decimal precision based on the asset category
    final int precision = quote.type == AssetType.crypto ? 4 : 2;

    return MarketItemUiModel(
      assetCode: quote.assetCode,
      name: quote.name,
      ask: quote.ask,
      bid: quote.bid,
      type: quote.type,
      formattedAsk: "${AppFormatter.amount(quote.ask, "", precision: precision)} TL",
      formattedBid: "${AppFormatter.amount(quote.bid, "", precision: precision)} TL",
      changeRateText: AppFormatter.signedPercent(rawDecimal),
      trendColor: changeRateDouble.toPnlColor(),
      trendIcon: icon,
      displayTitle: title,
      displaySubtitle: subtitle,
    );
  }
}