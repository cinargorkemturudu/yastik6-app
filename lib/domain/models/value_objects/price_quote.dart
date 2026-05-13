import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
// [FIXED] Removed the AppFormatter import. Domain should be UI-agnostic.

class PriceQuote {
  final String assetCode;
  final String name;
  final AssetType type;
  final Decimal bid;
  final Decimal ask;
  final double changeRate; // Kept as double (Ratio)
  final DateTime asOf;
  final DateTime expiresAt;
  final bool isConvertedtoTry;

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
  });

  Decimal get midPrice => (bid + ask) * Decimal.parse('0.5');

  Decimal get spread => ask - bid;

  bool get isStale {
    final nowLocal = DateTime.now();
    final asOfLocal = asOf.toLocal();
    final diff = nowLocal.difference(asOfLocal);
    final diffInMinutes = diff.inMinutes;
    final diffInHours = diff.inHours;

    if (type == AssetType.crypto) {
      return diffInMinutes > 30;
    }

    if (type == AssetType.indicator) {
      return diffInHours > 24;
    }

    if (diffInMinutes < 60) return false;

    if (nowLocal.weekday == DateTime.saturday || nowLocal.weekday == DateTime.sunday) {
      return diffInHours > 72;
    }

    if (nowLocal.weekday == DateTime.monday && nowLocal.hour < 10) {
      return diffInHours > 72;
    }

    return diffInHours > 24;
  }
}