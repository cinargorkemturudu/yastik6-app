import '../models/entities/transaction.dart' as m;
import '../models/entities/allocation.dart';

abstract class TransactionIRepository {
  Future<void> save(m.Transaction tx);
  
  Future<void> update(m.Transaction tx);

  Future<m.Transaction?> getById(String id);

  Future<List<m.Transaction>> getAll();

  Future<List<m.Transaction>> getByAssetId(String assetId);

  Future<void> delete(String id);

  Future<List<m.Transaction>> getOpenBuyLots(String assetId);

  Future<void> saveSellOperation({
    required m.Transaction sellTx,
    required List<m.Transaction> updatedBuyLots,
    required List<Allocation> allocations,
  });

}