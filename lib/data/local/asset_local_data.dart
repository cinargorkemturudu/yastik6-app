import 'package:sqflite/sqflite.dart' show ConflictAlgorithm, DatabaseExecutor;
import '../../core/app_log.dart';
import 'db_constants.dart';

class AssetLocalData {
  Future<void> upsertRow(DatabaseExecutor db, Map<String, dynamic> row) async {
    final id = row[DbConstants.colId];

    final count = await db.update(
      DbConstants.tableAssets,
      row,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      await db.insert(
        DbConstants.tableAssets,
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<Map<String, dynamic>?> getRowById(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      DbConstants.tableAssets,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      AppLog.warning('Query returned no results for asset: $id', domain: 'DATABASE');
      return null;
    }
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllRows(DatabaseExecutor db) async {
    return await db.query(DbConstants.tableAssets);
  }

  Future<void> deleteById(DatabaseExecutor db, String id) async {
    await db.delete(
      DbConstants.tableAssets,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAssetsWithActiveTransactions(DatabaseExecutor db) async {
    return await db.rawQuery('''
      SELECT 
        a.${DbConstants.colId} as asset_id, a.${DbConstants.colName}, a.${DbConstants.colSymbol}, a.${DbConstants.colType} as asset_type, a.${DbConstants.colCurrentPrice}, a.${DbConstants.colLastUpdate},
        t.${DbConstants.colId} as tx_id, t.${DbConstants.colType} as tx_type, t.${DbConstants.colAmount}, t.${DbConstants.colPurchasePrice}, t.${DbConstants.colPurchaseDate}, t.${DbConstants.colNote}, t.${DbConstants.colRemainingAmount}
      FROM ${DbConstants.tableAssets} a
      JOIN ${DbConstants.tableTransactions} t ON a.${DbConstants.colId} = t.${DbConstants.colAssetId} 
      WHERE t.${DbConstants.colRemainingAmount} > 0
    ''');
  }
}