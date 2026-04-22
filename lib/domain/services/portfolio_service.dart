import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/domain/irepositories/allocation_irepository.dart';
import 'package:yastik_alti/domain/irepositories/asset_irepository.dart';
import 'package:yastik_alti/domain/irepositories/transaction_irepository.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/dtos/asset_holding.dart';
import 'package:yastik_alti/domain/models/dtos/portfolio_snapshot.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/domain/services/portfolio_valuator.dart';
import 'package:yastik_alti/domain/models/dtos/realized_profit.dart';
import 'package:yastik_alti/domain/models/entities/allocation.dart';

class PortfolioService {
  final AssetIRepository _ar;
  final TransactionIRepository _tr;
  final AllocationIRepository _allocRepo;
  final _uuid = const Uuid();

  PortfolioService(this._ar, this._tr, this._allocRepo);

  Future<List<Transaction>> getAllTransactions() async => await _tr.getAll();
  Future<Transaction?> getTransactionById(String id) async => await _tr.getById(id);

  Future<List<AssetHolding>> getHoldings() async {
    final dataMap = await _ar.getAssetsWithTransactions();
    final List<AssetHolding> results = [];

    for (var entry in dataMap.entries) {
      final asset = entry.key;
      final transactions = entry.value;

      Decimal totalAmount = Decimal.zero;
      Decimal totalCost = Decimal.zero;

      for (var tx in transactions) {
        if (tx.remainingAmount <= Decimal.zero) continue;
        totalAmount += tx.remainingAmount;
        totalCost += (tx.remainingAmount * tx.purchasePrice);
      }

      if (totalAmount == Decimal.zero) continue;
      final avgCost = (totalCost.toRational() / totalAmount.toRational()).toDecimal(scaleOnInfinitePrecision: 10);

      results.add(AssetHolding(
        asset: asset,
        totalAmount: totalAmount,
        totalCost: totalCost,
        avgCost: avgCost,
        activeLots: transactions,
      ));
    }
    return results;
  }

  PortfolioSnapshot computeSnapshot({
    required List<AssetHolding> holdings,
    required Map<String, PriceQuote> prices,
  }) {
    return PortfolioValuator.compute(holdings: holdings, prices: prices);
  }

  Future<PortfolioRealizedSummary> getRealizedProfitReport() async {
    try {
      final rawAllocations = await _allocRepo.getAllRealizedProfits();
      final allAssets = await _ar.getAll();
      final assetMap = {for (var a in allAssets) a.id: a};
      Decimal portfolioTotalProfit = Decimal.zero;
      List<RealizedAssetSummary> assetSummaries = [];
      final groupedByAsset = groupBy(rawAllocations, (row) => row['asset_id'] as String);

      for (var entry in groupedByAsset.entries) {
        final asset = assetMap[entry.key];
        if (asset == null) continue;
        Decimal assetTotalProfit = Decimal.zero;
        Decimal assetTotalAmount = Decimal.zero;
        List<RealizedTransaction> transactions = [];
        final groupedByTx = groupBy(entry.value, (row) => row['sell_transaction_id'] as String);

        for (var txEntry in groupedByTx.entries) {
          final txRows = txEntry.value;
          final firstRow = txRows.first;
          Decimal totalQuantity = Decimal.zero;
          Decimal totalCost = Decimal.zero;
          Decimal sellPrice = Decimal.parse(firstRow['sell_price'].toString());

          for (var row in txRows) {
            Decimal q = Decimal.parse(row['quantity'].toString());
            Decimal buyPrice = Decimal.parse(row['buy_price'].toString());
            totalQuantity += q;
            totalCost += (q * buyPrice);
          }

          Decimal profit = (totalQuantity * sellPrice) - totalCost;
          Decimal avgBuyPrice = totalQuantity == Decimal.zero ? Decimal.zero : (totalCost.toRational() / totalQuantity.toRational()).toDecimal(scaleOnInfinitePrecision: 10);
          Decimal profitPct = totalCost == Decimal.zero ? Decimal.zero : (profit.toRational() / totalCost.toRational()).toDecimal(scaleOnInfinitePrecision: 10);

          transactions.add(RealizedTransaction(
            sellTransactionId: txEntry.key,
            date: DateTime.parse(firstRow['sell_date'].toString()),
            amountSold: totalQuantity, // [FIXED] Decimal
            avgBuyPrice: avgBuyPrice, // [FIXED] Decimal
            sellPrice: sellPrice, // [FIXED] Decimal
            profit: profit, // [FIXED] Decimal
            profitPct: profitPct.toDouble(), // [FIXED] Double
          ));
          assetTotalProfit += profit;
          assetTotalAmount += totalQuantity;
        }

        assetSummaries.add(RealizedAssetSummary(
          assetId: asset.id,
          name: asset.name,
          symbol: asset.symbol,
          assetType: asset.type,
          totalProfit: assetTotalProfit, // [FIXED] Decimal
          totalAmountSold: assetTotalAmount, // [FIXED] Decimal
          transactions: transactions,
        ));
        portfolioTotalProfit += assetTotalProfit;
      }

      return PortfolioRealizedSummary(
        totalLifetimeProfit: portfolioTotalProfit, // [FIXED] Decimal
        assetSummaries: assetSummaries,
      );
    } catch (e, stackTrace) {
      AppLog.error('Data Corruption: Failed to calculate realized profits', domain: 'DOMAIN_SERVICE', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateTransaction({
    required Transaction originalTx,
    required Decimal newAmount,
    required Decimal newPrice,
    required DateTime newDate,
    required String? newNote,
  }) async {
    final bool isAllocated = originalTx.remainingAmount < originalTx.amount;
    Transaction updatedTx;

    if (isAllocated) {
      updatedTx = originalTx.copyWith(note: newNote);
      AppLog.info('Update restricted to Note only for allocated transaction: ${originalTx.id}', domain: 'DOMAIN_SERVICE');
    } else {
      final allTxs = await _tr.getByAssetId(originalTx.assetId);
      final sellDates = allTxs
          .where((t) => t.type == TransactionType.sell)
          .map((t) => t.purchaseDate)
          .toList();

      if (sellDates.isNotEmpty) {
        final latestSellDate = sellDates.reduce((a, b) => a.isAfter(b) ? a : b);
        if (newDate.isBefore(latestSellDate)) {
          AppLog.warning('Timeline Paradox prevented. Attempted to move Buy lot before a Sell lot.', domain: 'DOMAIN_SERVICE');
          throw Exception(
              "Tarih Hatası: Bu işlemin tarihi, bu varlığa ait son satış işleminden "
                  "(${latestSellDate.day}/${latestSellDate.month}/${latestSellDate.year}) daha eskiye alınamaz. FIFO sıralaması bozulur."
          );
        }
      }

      updatedTx = originalTx.copyWith(
        amount: newAmount,
        remainingAmount: newAmount,
        purchasePrice: newPrice,
        purchaseDate: newDate,
        note: newNote,
      );
      AppLog.info('Full financial update executed for untouched transaction: ${originalTx.id}', domain: 'DOMAIN_SERVICE');
    }

    await _tr.update(updatedTx);
  }

  Future<void> deleteTransaction(String id) async => await _tr.delete(id);

  Future<void> createAndSaveTransaction({
    required String assetCode,
    required AssetType assetType,
    required Decimal amount,
    required Decimal price,
    required DateTime date,
    required TransactionType type,
    String? note,
    Decimal? currentPrice,
  }) async {
    final cleanCode = assetCode.trim().toUpperCase();

    if (assetType == AssetType.indicator) {
      throw Exception("Gösterge varlıkları için işlem girilemez. Sadece fiyat takibi içindir.");
    }

    final asset = Asset(
      id: cleanCode,
      name: cleanCode,
      symbol: cleanCode,
      type: assetType,
      currentPrice: currentPrice ?? Decimal.zero,
      lastUpdate: DateTime.now(),
    );

    await _ar.save(asset);

    if (type == TransactionType.buy) {
      final tx = Transaction(
        id: _uuid.v4(),
        assetId: cleanCode,
        type: type,
        amount: amount,
        purchasePrice: price,
        purchaseDate: date,
        note: note,
        remainingAmount: amount,
      );
      await _tr.save(tx);
    } else {
      final buyLots = await _tr.getOpenBuyLots(cleanCode);
      Decimal totalAvailable = buyLots.fold(Decimal.zero, (sum, lot) => sum + lot.remainingAmount);

      if (totalAvailable < amount) {
        AppLog.warning('FIFO Validation Failed', domain: 'DOMAIN_SERVICE');
        AppLog.insight('form_validation_failed');
        throw Exception('INSUFFICIENT_BALANCE');
      }

      final sellTx = Transaction(
        id: _uuid.v4(),
        assetId: cleanCode,
        type: type,
        amount: amount,
        purchasePrice: price,
        purchaseDate: date,
        note: note,
        remainingAmount: Decimal.zero,
      );

      Decimal needed = amount;
      final List<Transaction> updatedLots = [];
      final List<Allocation> allocations = [];

      for (var lot in buyLots) {
        if (needed <= Decimal.zero) break;

        Decimal take = (lot.remainingAmount < needed) ? lot.remainingAmount : needed;

        allocations.add(Allocation(
          id: _uuid.v4(),
          sellTransactionId: sellTx.id,
          buyTransactionId: lot.id,
          quantity: take,
        ));

        updatedLots.add(lot.copyWith(remainingAmount: lot.remainingAmount - take));
        needed -= take;
      }

      try {
        await _tr.saveSellOperation(sellTx: sellTx, updatedBuyLots: updatedLots, allocations: allocations);
      } catch (e, stackTrace) {
        AppLog.error('Critical Failure: FIFO atomic save crashed', domain: 'DOMAIN_SERVICE', error: e, stackTrace: stackTrace);
        rethrow;
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> loadAllocationsMap(List<Transaction> transactions) async {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (var tx in transactions) {
      if (tx.type == TransactionType.buy) {
        final sales = await _allocRepo.getLinkedSales(tx.id);
        if (sales.isNotEmpty) map[tx.id] = sales;
      }
    }
    return map;
  }
}