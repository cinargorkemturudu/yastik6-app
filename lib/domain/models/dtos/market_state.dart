import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';

enum DataHealthStatus {
  healthy,  // All assets are fresh
  degraded, // Some assets are stale (partial outage)
  offline   // All assets are stale, or network fetch completely failed
}

class MarketState {
  final List<PriceQuote> marketAssets;
  final Map<String, PriceQuote> priceMap;
  final DateTime? lastUpdate;

  const MarketState({
    this.marketAssets = const [],
    this.priceMap = const {},
    this.lastUpdate,
  });

  factory MarketState.initial() {
    return const MarketState();
  }

  DataHealthStatus get healthStatus {
    if (marketAssets.isEmpty) return DataHealthStatus.offline;

    final staleCount = marketAssets.where((q) => q.isStale).length;

    if (staleCount == 0) return DataHealthStatus.healthy;
    if (staleCount == marketAssets.length) return DataHealthStatus.offline;

    return DataHealthStatus.degraded;
  }

  MarketState copyWith({
    List<PriceQuote>? marketAssets,
    Map<String, PriceQuote>? priceMap,
    DateTime? lastUpdate,
  }) {
    return MarketState(
      marketAssets: marketAssets ?? this.marketAssets,
      priceMap: priceMap ?? this.priceMap,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}