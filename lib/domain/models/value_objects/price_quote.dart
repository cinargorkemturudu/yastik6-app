import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';

class PriceQuote {
  final String assetCode;
  final String name;
  final AssetType type;
  final Decimal bid;
  final Decimal ask;
  final double changeRate;
  final DateTime asOf;
  final DateTime expiresAt;
  final bool isConvertedtoTry;
  final bool isMarketOpen;

  PriceQuote({
    required this.assetCode,
    required this.name,
    required this.type,
    required this.bid,
    required this.ask,
    required this.changeRate,
    required this.asOf,
    required this.expiresAt,
    this.isConvertedtoTry = false,
    this.isMarketOpen = true,
  });

  Decimal get midPrice => (bid + ask) * Decimal.parse('0.5');

  Decimal get spread => ask - bid;

  bool get isStale {
    if (!isMarketOpen) return false;

    final nowUtc = DateTime.now().toUtc();
    return nowUtc.isAfter(expiresAt);
  }
}