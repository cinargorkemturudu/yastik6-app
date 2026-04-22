// lib/domain/models/dtos/asset_holding.dart

import 'package:flutter/foundation.dart';
import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';

class AssetHolding {
  final Asset asset;
  final Decimal totalAmount;
  final Decimal totalCost;
  final Decimal avgCost;
  final List<Transaction> activeLots;

  const AssetHolding({
    required this.asset,
    required this.totalAmount,
    required this.totalCost,
    required this.avgCost,
    required this.activeLots,
  });

  factory AssetHolding.empty(Asset asset) {
    return AssetHolding(
      asset: asset,
      totalAmount: Decimal.zero,
      totalCost: Decimal.zero,
      avgCost: Decimal.zero,
      activeLots: const [],
    );
  }

  AssetHolding copyWith({
    Asset? asset,
    Decimal? totalAmount,
    Decimal? totalCost,
    Decimal? avgCost,
    List<Transaction>? activeLots,
  }) {
    return AssetHolding(
      asset: asset ?? this.asset,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCost: totalCost ?? this.totalCost,
      avgCost: avgCost ?? this.avgCost,
      activeLots: activeLots ?? this.activeLots,
    );
  }

  @override
  String toString() {
    return 'AssetHolding(symbol: ${asset.symbol}, amount: $totalAmount, cost: $totalCost, lots: ${activeLots.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AssetHolding &&
        other.asset == asset &&
        other.totalAmount == totalAmount &&
        other.totalCost == totalCost &&
        other.avgCost == avgCost &&
        listEquals(other.activeLots, activeLots);
  }

  @override
  int get hashCode {
    return asset.hashCode ^
    totalAmount.hashCode ^
    totalCost.hashCode ^
    avgCost.hashCode ^
    Object.hashAll(activeLots);
  }
}