import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';

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
  });

  factory MarketItemUiModel.fromQuote(PriceQuote quote) {
    // Ensuring changeRate handles double operations cleanly
    final double changeRateDouble = quote.changeRate.toDouble();
    final rawDecimal = changeRateDouble / 100;

    IconData icon = Icons.remove;
    if (changeRateDouble > 0) icon = Icons.arrow_drop_up;
    if (changeRateDouble < 0) icon = Icons.arrow_drop_down;

    return MarketItemUiModel(
      assetCode: quote.assetCode,
      name: quote.name,
      ask: quote.ask,
      bid: quote.bid,
      type: quote.type,
      formattedAsk: quote.formattedAsk,
      formattedBid: quote.formattedBid,
      changeRateText: AppFormatter.signedPercent(rawDecimal),
      trendColor: changeRateDouble.toPnlColor(),
      trendIcon: icon,
    );
  }
}