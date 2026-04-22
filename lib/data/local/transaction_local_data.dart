import 'package:sqflite/sqflite.dart';
import '../../core/app_log.dart';
import '../../domain/models/entities/transaction.dart' as m;
import 'db_constants.dart';

class TransactionLocalData {
  Future<void> upsert(DatabaseExecutor db, m.Transaction tx) async {
    await db.insert(
      DbConstants.tableTransactions,
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(DatabaseExecutor db, m.Transaction tx) async {
    final count = await db.update(
      DbConstants.tableTransactions,
      tx.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [tx.id],
    );

    if (count == 0) {
      AppLog.warning('Transaction update failed: ID ${tx.id} not found', domain: 'DATABASE');
    }
  }

  Future<m.Transaction?> getById(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      AppLog.warning('Transaction not found: $id', domain: 'DATABASE');
      return null;
    }
    return m.Transaction.fromMap(rows.first);
  }

  Future<List<m.Transaction>> getByAssetId(DatabaseExecutor db, String assetId) async {
    final rows = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.colAssetId} = ?',
      whereArgs: [assetId],
      orderBy: '${DbConstants.colPurchaseDate} ASC',
    );
    return rows.map((x) => m.Transaction.fromMap(x)).toList();
  }

  Future<List<m.Transaction>> getAll(DatabaseExecutor db) async {
    final rows = await db.query(DbConstants.tableTransactions);
    return rows.map((x) => m.Transaction.fromMap(x)).toList();
  }

  Future<void> delete(DatabaseExecutor db, String id) async {
    final count = await db.delete(
        DbConstants.tableTransactions,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id]
    );

    if (count == 0) {
      AppLog.warning('Delete skipped: Transaction $id did not exist', domain: 'DATABASE');
    }
  }
}