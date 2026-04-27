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

  bool get isPositive => changePercent >= 0;

  // PRESENTATION LOGIC: Centralized naming for the Ticker
  String get displayTitle {
    final cleanedCode = AppFormatter.cleanAssetCode(assetCode);
    if (cleanedCode == assetCode && displayName.isNotEmpty) {
      return displayName.toUpperCase();
    }
    return cleanedCode.toUpperCase();
  }

  String get formattedBid => AppFormatter.amount(bid.toDouble(), assetCode);
  String get formattedAsk => AppFormatter.amount(ask.toDouble(), assetCode);
  String get formattedBidAsk => 'Al $formattedBid / Sat $formattedAsk';

  String get formattedChangePercent {
    return AppFormatter.signedPercent(changePercent / 100);
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