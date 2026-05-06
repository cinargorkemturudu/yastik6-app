// lib/domain/models/dtos/realized_profit.dart

import 'package:flutter/foundation.dart';
import 'package:decimal/decimal.dart';
import '../entities/asset.dart';
import 'portfolio_report_base.dart';

class RealizedTransaction {
  final String sellTransactionId;
  final DateTime date;
  final Decimal amountSold;
  final Decimal avgBuyPrice;
  final Decimal sellPrice;
  final Decimal profit;
  final double profitPct;

  const RealizedTransaction({
    required this.sellTransactionId,
    required this.date,
    required this.amountSold,
    required this.avgBuyPrice,
    required this.sellPrice,
    required this.profit,
    required this.profitPct,
  });

  RealizedTransaction copyWith({
    String? sellTransactionId,
    DateTime? date,
    Decimal? amountSold,
    Decimal? avgBuyPrice,
    Decimal? sellPrice,
    Decimal? profit,
    double? profitPct,
  }) {
    return RealizedTransaction(
      sellTransactionId: sellTransactionId ?? this.sellTransactionId,
      date: date ?? this.date,
      amountSold: amountSold ?? this.amountSold,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      profit: profit ?? this.profit,
      profitPct: profitPct ?? this.profitPct,
    );
  }

  @override
  String toString() {
    return 'RealizedTransaction(date: $date, profit: $profit, pct: $profitPct)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RealizedTransaction &&
        other.sellTransactionId == sellTransactionId &&
        other.date == date &&
        other.amountSold == amountSold &&
        other.avgBuyPrice == avgBuyPrice &&
        other.sellPrice == sellPrice &&
        other.profit == profit &&
        other.profitPct == profitPct;
  }

  @override
  int get hashCode {
    return sellTransactionId.hashCode ^
    date.hashCode ^
    amountSold.hashCode ^
    avgBuyPrice.hashCode ^
    sellPrice.hashCode ^
    profit.hashCode ^
    profitPct.hashCode;
  }
}

class RealizedAssetSummary implements ReportItemBase {
  final String assetId;
  final String name;
  final String symbol;

  @override
  final AssetType assetType;

  final Decimal totalProfit;
  final Decimal totalAmountSold;
  final List<RealizedTransaction> transactions;

  @override
  String get displayTitle => name;

  @override
  Decimal get donutValue => totalProfit.abs(); // Decimal has an .abs() method

  @override
  Decimal get itemPnlTl => totalProfit;

  @override
  Decimal get itemCostBasis {
    return transactions.fold(Decimal.zero, (sum, tx) => sum + (tx.amountSold * tx.avgBuyPrice));
  }

  @override
  double get itemPnlPct {
    final cost = itemCostBasis;
    // [FIXED] Division done securely in Rational space before casting to double
    return cost == Decimal.zero ? 0.0 : (totalProfit.toRational() / cost.toRational()).toDouble();
  }

  const RealizedAssetSummary({
    required this.assetId,
    required this.name,
    required this.symbol,
    required this.assetType,
    required this.totalProfit,
    required this.totalAmountSold,
    required this.transactions,
  });

  AssetType get type => assetType;

  RealizedAssetSummary copyWith({
    String? assetId,
    String? name,
    String? symbol,
    AssetType? assetType,
    Decimal? totalProfit,
    Decimal? totalAmountSold,
    List<RealizedTransaction>? transactions,
  }) {
    return RealizedAssetSummary(
      assetId: assetId ?? this.assetId,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      assetType: assetType ?? this.assetType,
      totalProfit: totalProfit ?? this.totalProfit,
      totalAmountSold: totalAmountSold ?? this.totalAmountSold,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  String toString() {
    return 'RealizedAssetSummary(symbol: $symbol, type: ${assetType.name}, totalProfit: $totalProfit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RealizedAssetSummary &&
        other.assetId == assetId &&
        other.name == name &&
        other.symbol == symbol &&
        other.assetType == assetType &&
        other.totalProfit == totalProfit &&
        other.totalAmountSold == totalAmountSold &&
        listEquals(other.transactions, transactions);
  }

  @override
  int get hashCode {
    return assetId.hashCode ^
    name.hashCode ^
    symbol.hashCode ^
    assetType.hashCode ^
    totalProfit.hashCode ^
    totalAmountSold.hashCode ^
    Object.hashAll(transactions);
  }
}

class PortfolioRealizedSummary implements PortfolioReportBase {
  final Decimal totalLifetimeProfit;
  final List<RealizedAssetSummary> assetSummaries;

  @override
  Decimal get totalDisplayValue => totalLifetimeProfit;

  @override
  Decimal get totalPnlTl => totalLifetimeProfit;

  @override
  double get totalPnlPct {
    final totalCost = assetSummaries.fold(Decimal.zero, (sum, s) => sum + s.itemCostBasis);
    // [FIXED] Division done securely in Rational space before casting to double
    return totalCost == Decimal.zero ? 0.0 : (totalLifetimeProfit.toRational() / totalCost.toRational()).toDouble();
  }

  @override
  List<ReportItemBase> get reportItems => assetSummaries;

  const PortfolioRealizedSummary({
    required this.totalLifetimeProfit,
    required this.assetSummaries,
  });

  PortfolioRealizedSummary copyWith({
    Decimal? totalLifetimeProfit,
    List<RealizedAssetSummary>? assetSummaries,
  }) {
    return PortfolioRealizedSummary(
      totalLifetimeProfit: totalLifetimeProfit ?? this.totalLifetimeProfit,
      assetSummaries: assetSummaries ?? this.assetSummaries,
    );
  }

  @override
  String toString() {
    return 'PortfolioRealizedSummary(totalLifetimeProfit: $totalLifetimeProfit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PortfolioRealizedSummary &&
        other.totalLifetimeProfit == totalLifetimeProfit &&
        listEquals(other.assetSummaries, assetSummaries);
  }

  @override
  int get hashCode => totalLifetimeProfit.hashCode ^ Object.hashAll(assetSummaries);
}