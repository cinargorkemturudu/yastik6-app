import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/dtos/portfolio_snapshot.dart';
import 'package:yastik_alti/domain/models/dtos/realized_profit.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import '../ui_models/lot_ui_model.dart';
import '../ui_models/portfolio_donut_model.dart';
import '../utils/app_formatter.dart';
import '../theme/app_colors.dart';
import '../theme/app_strings.dart';

enum HistoryFilterType { all, buyOnly, sellOnly }

class UniversalPortfolioMapper {

  static List<LotUiModel> toLotUiModels({
    required List<AssetPosition> positions,
    required Map<String, List<Map<String, dynamic>>> allocationsMap,
    required Map<String, String> assetNames,
    AssetType? assetFilter,
  }) {
    final List<LotUiModel> lots = [];

    for (final pos in positions) {
      if (assetFilter != null && pos.asset.type != assetFilter) continue;

      for (final lotProfit in pos.lots) {
        final tx = lotProfit.transaction;

        final rawAllocations = List<Map<String, dynamic>>.from(allocationsMap[tx.id] ?? []);
        rawAllocations.sort((a, b) {
          final dateA = DateTime.parse(a['sell_date'].toString());
          final dateB = DateTime.parse(b['sell_date'].toString());
          return dateB.compareTo(dateA);
        });

        final allocationUiModels = rawAllocations.map((row) {
          final date = DateTime.parse(row['sell_date'].toString());
          final amount = Decimal.parse(row['used_amount'].toString());
          final sellPrice = Decimal.parse(row['sell_price'].toString());
          final profit = (sellPrice - tx.purchasePrice) * amount;

          return SubTransactionUiModel(
            date: AppFormatter.date(date),
            amount: AppFormatter.amount(amount.toDouble(), pos.asset.symbol), // [FIXED]
            price: AppFormatter.money(sellPrice.toDouble()), // [FIXED]
            profitText: AppFormatter.pnlValue(profit.toDouble()), // [FIXED]
            profitColor: profit.toDouble().toPnlColor(), // [FIXED]
          );
        }).toList();

        lots.add(LotUiModel(
          transactionId: tx.id,
          dateText: AppFormatter.date(tx.purchaseDate),
          sortDate: tx.purchaseDate,
          note: tx.note,
          assetName: assetNames[pos.asset.symbol] ?? pos.asset.name,
          symbol: pos.asset.symbol,
          type: pos.asset.type,
          amountValue: tx.remainingAmount, // [FIXED] Decimal
          originalAmountText: AppFormatter.amount(tx.amount.toDouble(), pos.asset.symbol), // [FIXED]
          remainingAmountText: AppFormatter.amount(tx.remainingAmount.toDouble(), pos.asset.symbol), // [FIXED]
          soldAmountText: AppFormatter.amount((tx.amount - tx.remainingAmount).toDouble(), pos.asset.symbol), // [FIXED]
          buyPriceText: AppFormatter.money(tx.purchasePrice.toDouble()), // [FIXED]
          totalCostText: AppFormatter.money(lotProfit.cost.toDouble()), // [FIXED]
          profitPercent: AppFormatter.signedPercent(lotProfit.profitPct),
          currentUnrealizedPnl: AppFormatter.pnlValue(lotProfit.profit.toDouble()), // [FIXED]
          unrealizedColor: lotProfit.profit.toDouble().toPnlColor(), // [FIXED]
          totalRealizedPnl: null,
          realizedColor: null,
          progressVal: tx.amount == Decimal.zero ? 0.0 : (tx.remainingAmount.toRational() / tx.amount.toRational()).toDouble(),
          isSellCard: false,
          allocations: allocationUiModels,
        ));
      }
    }

    lots.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return lots;
  }

  static List<LotUiModel> toHistoryLots({
    required List<Transaction> allTransactions,
    required Map<String, List<Map<String, dynamic>>> allocationsMap,
    required Map<String, AssetType> assetTypes,
    required AssetType? assetFilter,
    required HistoryFilterType filterType,
    required Map<String, String> assetNames,
  }) {
    return allTransactions.where((tx) {
      if (filterType == HistoryFilterType.buyOnly && tx.type == TransactionType.sell) return false;
      if (filterType == HistoryFilterType.sellOnly && tx.type == TransactionType.buy) return false;
      return true;
    }).map((tx) => LotUiModel(
      transactionId: tx.id,
      dateText: AppFormatter.date(tx.purchaseDate),
      sortDate: tx.purchaseDate,
      assetName: assetNames[tx.assetId] ?? tx.assetId,
      symbol: tx.assetId,
      type: assetTypes[tx.assetId] ?? AssetType.stock,
      amountValue: tx.amount, // [FIXED] Decimal
      originalAmountText: AppFormatter.amount(tx.amount.toDouble(), tx.assetId), // [FIXED]
      remainingAmountText: AppFormatter.amount(tx.remainingAmount.toDouble(), tx.assetId), // [FIXED]
      soldAmountText: AppFormatter.amount(0.0, tx.assetId), // [FIXED]
      buyPriceText: AppFormatter.money(tx.purchasePrice.toDouble()), // [FIXED]
      totalCostText: AppFormatter.money((tx.amount * tx.purchasePrice).toDouble()), // [FIXED]
      profitPercent: "",
      currentUnrealizedPnl: "",
      unrealizedColor: AppColors.textPrimary,
      progressVal: 1.0,
      isSellCard: tx.type == TransactionType.sell,
    )).toList();
  }

  static PortfolioDonutModel toDonutModel(
      PortfolioSnapshot snapshot,
      AssetType? filter,
      Map<String, String> assetNames,
      ) {
    final items = snapshot.positions.where((p) {
      if (p.asset.type == AssetType.indicator) return false;
      if (filter == null) return true;
      return p.asset.type == filter;
    }).toList();

    final Decimal totalTl = filter == null ? snapshot.totalValue : items.fold(Decimal.zero, (sum, i) => sum + i.currentValue);
    final Decimal totalPnlTl = filter == null ? snapshot.totalProfit : items.fold(Decimal.zero, (sum, i) => sum + i.profit);
    final Decimal netCost = totalTl - totalPnlTl;
    final double totalPnlPct = filter == null ? snapshot.totalProfitPct : (netCost > Decimal.zero ? (totalPnlTl.toRational() / netCost.toRational()).toDouble() : 0.0);

    return PortfolioDonutModel(
      totalTl: totalTl, // [FIXED] Decimal
      totalPnlTl: totalPnlTl, // [FIXED] Decimal
      totalPnlPct: totalPnlPct, // Double
      totalValueText: AppFormatter.money(totalTl.toDouble()), // [FIXED]
      totalPnlText: "${AppFormatter.pnlValue(totalPnlTl.toDouble())} (${AppFormatter.signedPercent(totalPnlPct)})", // [FIXED]
      pnlColor: totalPnlTl.toDouble().toPnlColor(), // [FIXED]
      items: items.map((pos) => PortfolioDonutItem(
        type: pos.asset.type,
        title: assetNames[pos.asset.symbol] ?? pos.asset.name,
        tlValue: pos.currentValue, // [FIXED] Decimal
        pnlTl: pos.profit, // [FIXED] Decimal
        pnlPct: pos.profitPct,
        color: AppColors.getAssetColor(pos.asset.symbol),
      )).toList(),
    );
  }

  static PortfolioDonutModel toRealizedDonutModel(PortfolioRealizedSummary summary, AssetType? filter, Map<String, String> assetNames,) {
    final items = summary.assetSummaries.where((s) {
      if (s.assetType == AssetType.indicator) return false;
      if (filter == null) return true;
      return s.assetType == filter;
    }).toList();

    final Decimal totalTl = filter == null ? summary.totalLifetimeProfit : items.fold(Decimal.zero, (sum, i) => sum + i.totalProfit);

    return PortfolioDonutModel(
      totalTl: totalTl, // [FIXED] Decimal
      totalPnlTl: totalTl, // [FIXED] Decimal
      totalPnlPct: summary.totalPnlPct,
      totalValueText: AppFormatter.money(totalTl.toDouble()), // [FIXED]
      totalPnlText: "${AppFormatter.pnlValue(totalTl.toDouble())} (${AppFormatter.signedPercent(summary.totalPnlPct)})", // [FIXED]
      pnlColor: totalTl.toDouble().toPnlColor(), // [FIXED]
      items: items.map((asset) => PortfolioDonutItem(
        type: asset.assetType,
        title: assetNames[asset.symbol] ?? asset.symbol,
        tlValue: asset.totalProfit, // [FIXED] Decimal
        pnlTl: asset.totalProfit, // [FIXED] Decimal
        pnlPct: asset.itemPnlPct,
        color: AppColors.getAssetColor(asset.symbol),
      )).toList(),
    );
  }

  static List<LotUiModel> toRealizedLotUiModels({
    required PortfolioRealizedSummary summary,
    required Map<String, String> assetNames,
    AssetType? assetFilter,
  }) {
    final List<LotUiModel> lots = [];

    for (final assetSummary in summary.assetSummaries) {
      if (assetFilter != null && assetSummary.assetType != assetFilter) continue;

      for (final tx in assetSummary.transactions) {
        lots.add(LotUiModel(
          transactionId: tx.sellTransactionId,
          dateText: AppFormatter.date(tx.date),
          sortDate: tx.date,
          note: AppStrings.labels.profitRealization,
          assetName: assetNames[assetSummary.symbol] ?? assetSummary.symbol,
          symbol: assetSummary.symbol,
          type: assetSummary.assetType,
          amountValue: Decimal.zero, // [FIXED] Decimal
          originalAmountText: AppFormatter.amount(tx.amountSold.toDouble(), assetSummary.symbol), // [FIXED]
          remainingAmountText: "0.00",
          soldAmountText: AppFormatter.amount(tx.amountSold.toDouble(), assetSummary.symbol), // [FIXED]
          buyPriceText: AppFormatter.money(tx.avgBuyPrice.toDouble()), // [FIXED]
          totalCostText: AppFormatter.money((tx.sellPrice * tx.amountSold).toDouble()), // [FIXED]
          profitPercent: AppFormatter.signedPercent(tx.profitPct),
          totalRealizedPnl: AppFormatter.pnlValue(tx.profit.toDouble()), // [FIXED]
          realizedColor: tx.profit.toDouble().toPnlColor(), // [FIXED]
          currentUnrealizedPnl: null,
          unrealizedColor: null,
          progressVal: 0.0,
          isSellCard: false,
        ));
      }
    }

    lots.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return lots;
  }
}