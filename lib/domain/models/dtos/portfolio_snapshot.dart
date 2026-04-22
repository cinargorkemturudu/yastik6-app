// lib/domain/models/dtos/portfolio_snapshot.dart

import 'package:flutter/foundation.dart';
import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'portfolio_report_base.dart';

class LotProfit {
  final Transaction transaction;
  final Asset asset;
  final Decimal cost;
  final Decimal currentValue;
  final Decimal profit;
  final double profitPct;

  const LotProfit({
    required this.transaction,
    required this.asset,
    required this.cost,
    required this.currentValue,
    required this.profit,
    required this.profitPct,
  });

  LotProfit copyWith({
    Transaction? transaction,
    Asset? asset,
    Decimal? cost,
    Decimal? currentValue,
    Decimal? profit,
    double? profitPct,
  }) {
    return LotProfit(
      transaction: transaction ?? this.transaction,
      asset: asset ?? this.asset,
      cost: cost ?? this.cost,
      currentValue: currentValue ?? this.currentValue,
      profit: profit ?? this.profit,
      profitPct: profitPct ?? this.profitPct,
    );
  }

  @override
  String toString() {
    return 'LotProfit(tx: ${transaction.id}, profit: $profit, pct: $profitPct)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LotProfit &&
        other.transaction == transaction &&
        other.asset == asset &&
        other.cost == cost &&
        other.currentValue == currentValue &&
        other.profit == profit &&
        other.profitPct == profitPct;
  }

  @override
  int get hashCode {
    return transaction.hashCode ^
    asset.hashCode ^
    cost.hashCode ^
    currentValue.hashCode ^
    profit.hashCode ^
    profitPct.hashCode;
  }
}

class AssetPosition implements ReportItemBase {
  final Asset asset;
  final Decimal totalAmount;
  final Decimal averageBuyPrice;
  final Decimal currentPrice;
  final Decimal costBasis;
  final Decimal currentValue;
  final Decimal profit;
  final double profitPct;
  final List<LotProfit> lots;

  @override
  AssetType get assetType => asset.type;

  @override
  String get displayTitle => asset.name;

  @override
  Decimal get donutValue => currentValue;

  @override
  Decimal get itemPnlTl => profit;

  @override
  double get itemPnlPct => profitPct;

  @override
  Decimal get itemCostBasis => costBasis;

  const AssetPosition({
    required this.asset,
    required this.totalAmount,
    required this.averageBuyPrice,
    required this.currentPrice,
    required this.costBasis,
    required this.currentValue,
    required this.profit,
    required this.profitPct,
    required this.lots,
  });

  AssetPosition copyWith({
    Asset? asset,
    Decimal? totalAmount,
    Decimal? averageBuyPrice,
    Decimal? currentPrice,
    Decimal? costBasis,
    Decimal? currentValue,
    Decimal? profit,
    double? profitPct,
    List<LotProfit>? lots,
  }) {
    return AssetPosition(
      asset: asset ?? this.asset,
      totalAmount: totalAmount ?? this.totalAmount,
      averageBuyPrice: averageBuyPrice ?? this.averageBuyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      costBasis: costBasis ?? this.costBasis,
      currentValue: currentValue ?? this.currentValue,
      profit: profit ?? this.profit,
      profitPct: profitPct ?? this.profitPct,
      lots: lots ?? this.lots,
    );
  }

  @override
  String toString() {
    return 'AssetPosition(symbol: ${asset.symbol}, amount: $totalAmount, profit: $profit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AssetPosition &&
        other.asset == asset &&
        other.totalAmount == totalAmount &&
        other.averageBuyPrice == averageBuyPrice &&
        other.currentPrice == currentPrice &&
        other.costBasis == costBasis &&
        other.currentValue == currentValue &&
        other.profit == profit &&
        other.profitPct == profitPct &&
        listEquals(other.lots, lots);
  }

  @override
  int get hashCode {
    return asset.hashCode ^
    totalAmount.hashCode ^
    averageBuyPrice.hashCode ^
    currentPrice.hashCode ^
    costBasis.hashCode ^
    currentValue.hashCode ^
    profit.hashCode ^
    profitPct.hashCode ^
    Object.hashAll(lots);
  }
}

class PortfolioSnapshot implements PortfolioReportBase {
  final List<AssetPosition> positions;
  final Decimal totalCost;
  final Decimal totalValue;
  final Decimal totalProfit;
  final double totalProfitPct;

  @override
  Decimal get totalDisplayValue => totalValue;

  @override
  Decimal get totalPnlTl => totalProfit;

  @override
  double get totalPnlPct => totalProfitPct;

  @override
  List<ReportItemBase> get reportItems => positions;

  const PortfolioSnapshot({
    required this.positions,
    required this.totalCost,
    required this.totalValue,
    required this.totalProfit,
    required this.totalProfitPct,
  });

  factory PortfolioSnapshot.empty() {
    return PortfolioSnapshot(
      positions: const [],
      totalCost: Decimal.zero,
      totalValue: Decimal.zero,
      totalProfit: Decimal.zero,
      totalProfitPct: 0.0,
    );
  }

  PortfolioSnapshot copyWith({
    List<AssetPosition>? positions,
    Decimal? totalCost,
    Decimal? totalValue,
    Decimal? totalProfit,
    double? totalProfitPct,
  }) {
    return PortfolioSnapshot(
      positions: positions ?? this.positions,
      totalCost: totalCost ?? this.totalCost,
      totalValue: totalValue ?? this.totalValue,
      totalProfit: totalProfit ?? this.totalProfit,
      totalProfitPct: totalProfitPct ?? this.totalProfitPct,
    );
  }

  @override
  String toString() {
    return 'PortfolioSnapshot(val: $totalValue, profit: $totalProfit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PortfolioSnapshot &&
        other.totalCost == totalCost &&
        other.totalValue == totalValue &&
        other.totalProfit == totalProfit &&
        other.totalProfitPct == totalProfitPct &&
        listEquals(other.positions, positions);
  }

  @override
  int get hashCode {
    return totalCost.hashCode ^
    totalValue.hashCode ^
    totalProfit.hashCode ^
    totalProfitPct.hashCode ^
    Object.hashAll(positions);
  }
}