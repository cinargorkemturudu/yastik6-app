import 'package:decimal/decimal.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yastik_alti/data/local/transaction_local_data.dart';
import 'package:yastik_alti/data/local/allocation_local_data.dart';
import 'package:yastik_alti/domain/irepositories/transaction_irepository.dart';
import 'package:yastik_alti/domain/models/entities/allocation.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart' as m;

class TransactionRepo implements TransactionIRepository {
  final TransactionLocalData _txLocal;
  final AllocationLocalData _allocLocal;
  final Database _db;

  TransactionRepo(this._txLocal, this._allocLocal, this._db);

  @override
  Future<void> save(m.Transaction tx) async => _txLocal.upsert(_db, tx);
  
  @override
  Future<void> update(m.Transaction tx) async => _txLocal.update(_db, tx);

  @override
  Future<m.Transaction?> getById(String id) async => _txLocal.getById(_db, id);

  @override
  Future<List<m.Transaction>> getAll() async => _txLocal.getAll(_db);

  @override
  Future<List<m.Transaction>> getByAssetId(String assetId) async =>
      _txLocal.getByAssetId(_db, assetId);

  @override
  Future<void> delete(String id) async => _txLocal.delete(_db, id);

  @override
  Future<List<m.Transaction>> getOpenBuyLots(String assetId) async {
    final all = await _txLocal.getByAssetId(_db, assetId);
    return all.where((t) =>
    t.type == m.TransactionType.buy && t.remainingAmount > Decimal.zero).toList();
  }

  @override
  Future<void> saveSellOperation({
    required m.Transaction sellTx,
    required List<m.Transaction> updatedBuyLots,
    required List<Allocation> allocations,
  }) async {
    await _db.transaction((txn) async {
      await _txLocal.upsert(txn, sellTx);

      for (var buyTx in updatedBuyLots) {
        await _txLocal.update(txn, buyTx);
      }

      for (var alloc in allocations) {
        await _allocLocal.upsert(txn, alloc);
      }
    });
  }
}