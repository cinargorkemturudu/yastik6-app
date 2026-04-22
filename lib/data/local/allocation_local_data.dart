import 'package:sqflite/sqflite.dart';
import '../../domain/models/entities/allocation.dart';
import 'db_constants.dart';

class AllocationLocalData {
  Future<void> upsert(DatabaseExecutor db, Allocation allocation) async {
    await db.insert(
      DbConstants.tableAllocations,
      allocation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSalesLinkedToBuyLot(DatabaseExecutor db, String buyTxId) async {
    return await db.rawQuery('''
      SELECT 
        a.${DbConstants.colQuantity} as used_amount,
        sell.${DbConstants.colPurchaseDate} as sell_date,
        sell.${DbConstants.colPurchasePrice} as sell_price,
        sell.${DbConstants.colId} as sell_id
      FROM ${DbConstants.tableAllocations} a
      JOIN ${DbConstants.tableTransactions} sell ON a.${DbConstants.colSellTxId} = sell.${DbConstants.colId}
      WHERE a.${DbConstants.colBuyTxId} = ?
      ORDER BY sell.${DbConstants.colPurchaseDate} DESC
    ''', [buyTxId]);
  }

  Future<List<Map<String, dynamic>>> getProfitDetailsByAsset(DatabaseExecutor db, String assetId) async {
    return await db.rawQuery('''
      SELECT
        a.${DbConstants.colQuantity},
        buy.${DbConstants.colPurchasePrice} AS buy_price,
        sell.${DbConstants.colPurchasePrice} AS sell_price,
        sell.${DbConstants.colPurchaseDate} AS sell_date,
        sell.${DbConstants.colId} AS sell_transaction_id
      FROM ${DbConstants.tableAllocations} a
      JOIN ${DbConstants.tableTransactions} buy ON a.${DbConstants.colBuyTxId} = buy.${DbConstants.colId}
      JOIN ${DbConstants.tableTransactions} sell ON a.${DbConstants.colSellTxId} = sell.${DbConstants.colId}
      WHERE buy.${DbConstants.colAssetId} = ?
      ORDER BY sell.${DbConstants.colPurchaseDate} DESC
    ''', [assetId]);
  }

  Future<List<Map<String, dynamic>>> getAllProfitDetails(DatabaseExecutor db) async {
    return await db.rawQuery('''
      SELECT
        a.${DbConstants.colQuantity},
        buy.${DbConstants.colPurchasePrice} AS buy_price,
        buy.${DbConstants.colAssetId} AS asset_id, 
        sell.${DbConstants.colPurchasePrice} AS sell_price,
        sell.${DbConstants.colPurchaseDate} AS sell_date,
        sell.${DbConstants.colId} AS sell_transaction_id
      FROM ${DbConstants.tableAllocations} a
      JOIN ${DbConstants.tableTransactions} buy ON a.${DbConstants.colBuyTxId} = buy.${DbConstants.colId}
      JOIN ${DbConstants.tableTransactions} sell ON a.${DbConstants.colSellTxId} = sell.${DbConstants.colId}
      ORDER BY sell.${DbConstants.colPurchaseDate} DESC
    ''');
  }

  Future<void> deleteBySellTransactionId(DatabaseExecutor db, String sellTxId) async {
    await db.delete(
        DbConstants.tableAllocations,
        where: '${DbConstants.colSellTxId} = ?',
        whereArgs: [sellTxId]
    );
  }
}