import 'package:decimal/decimal.dart'; // [FIXED] Added missing import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/di/providers.dart';

class AssetHistoryParams {
  final String assetCode;
  final String range;

  const AssetHistoryParams({required this.assetCode, required this.range});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AssetHistoryParams &&
              runtimeType == other.runtimeType &&
              assetCode == other.assetCode &&
              range == other.range;

  @override
  int get hashCode => assetCode.hashCode ^ range.hashCode;
}

final assetHistoryProvider = FutureProvider.autoDispose.family<List<PricePoint>, AssetHistoryParams>(
      (ref, params) async {
    final repo = ref.watch(priceRepoProvider);
    return await repo.getHistory(params.assetCode, params.range);
  },
);

class HistoricalPriceParams {
  final String assetCode;
  final DateTime date;

  const HistoricalPriceParams({required this.assetCode, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is HistoricalPriceParams &&
              runtimeType == other.runtimeType &&
              assetCode == other.assetCode &&
              date == other.date;

  @override
  int get hashCode => assetCode.hashCode ^ date.hashCode;
}

// [FIXED] Upgraded from double? to Decimal?
final historicalPriceProvider = FutureProvider.autoDispose.family<Decimal?, HistoricalPriceParams>(
      (ref, params) async {
    final repo = ref.watch(priceRepoProvider);

    final history = await repo.getHistory(params.assetCode, 'Year');

    if (history.isEmpty) return null;

    PricePoint closest = history.first;
    int minDiff = (closest.timestamp.millisecondsSinceEpoch - params.date.millisecondsSinceEpoch).abs();

    for (var point in history) {
      int diff = (point.timestamp.millisecondsSinceEpoch - params.date.millisecondsSinceEpoch).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = point;
      }
    }

    return closest.price; // [FIXED] Return pure Decimal
  },
);