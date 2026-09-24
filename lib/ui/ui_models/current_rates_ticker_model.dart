import 'package:decimal/decimal.dart';
import '../utils/app_formatter.dart';

class CurrentRatesTickerModel {
  final List<TickerItemUiModel> items;

  const CurrentRatesTickerModel({
    required this.items,
  });
}

class TickerItemUiModel {
  final String assetCode;
  final String displayName;
  final Decimal bid;
  final Decimal ask;
  final DateTime asOf;
  final double changePercent;
  final bool isStale;

  const TickerItemUiModel({
    required this.assetCode,
    required this.displayName,
    required this.bid,
    required this.ask,
    required this.asOf,
    required this.changePercent,
    required this.isStale,
  });

  // 1. NEUTRAL LOGIC: Matches the 0.005 rounding threshold from the formatter
  bool get isNeutral => changePercent.abs() < 0.005;
  bool get isPositive => changePercent >= 0.005;

  // 2. ARROW INDICATOR: Returns directional arrows, or a dash for neutral
  String get trendArrow {
    if (isNeutral) return '▬';
    return isPositive ? '▲' : '▼';
  }

  // PRESENTATION LOGIC: Centralized naming for the Ticker
  String get displayTitle {
    final cleanedCode = AppFormatter.cleanAssetCode(assetCode);
    if (cleanedCode == assetCode && displayName.isNotEmpty) {
      return displayName.toUpperCase();
    }
    return cleanedCode.toUpperCase();
  }

  String get formattedBid => AppFormatter.amount(bid, assetCode);
  String get formattedAsk => AppFormatter.amount(ask, assetCode);
  String get formattedBidAsk => 'Al $formattedBid / Sat $formattedAsk';

  // 3. COMBINED FORMATTING: Appends the arrow to the percentage string
  String get formattedChangePercent {
    final percentStr = AppFormatter.signedPercent(changePercent / 100);
    if (isNeutral) {
      // Replaces the +0.00% or -0.00% with a clean neutral format
      return '▬ %0,00';
    }
    return '$trendArrow $percentStr';
  }

  TickerItemUiModel copyWith({
    String? assetCode,
    String? displayName,
    Decimal? bid,
    Decimal? ask,
    DateTime? asOf,
    double? changePercent,
    bool? isStale,
  }) {
    return TickerItemUiModel(
      assetCode: assetCode ?? this.assetCode,
      displayName: displayName ?? this.displayName,
      bid: bid ?? this.bid,
      ask: ask ?? this.ask,
      asOf: asOf ?? this.asOf,
      changePercent: changePercent ?? this.changePercent,
      isStale: isStale ?? this.isStale,
    );
  }
}