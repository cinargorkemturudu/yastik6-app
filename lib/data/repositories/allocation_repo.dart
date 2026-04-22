import 'package:sqflite/sqflite.dart'; // REFACTOR: Database tipi için eklendi
import 'package:yastik_alti/data/local/allocation_local_data.dart';
import 'package:yastik_alti/domain/irepositories/allocation_irepository.dart';

class AllocationRepo implements AllocationIRepository {
  final AllocationLocalData _local;
  final Database _db; 
  
  AllocationRepo(this._local, this._db);

  @override
  Future<List<Map<String, dynamic>>> getRealizedProfitByAsset(String assetId) async {
    return await _local.getProfitDetailsByAsset(_db, assetId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllRealizedProfits() async {
    return await _local.getAllProfitDetails(_db);
  }

  @override
  Future<List<Map<String, dynamic>>> getLinkedSales(String buyTxId) async {
    return await _local.getSalesLinkedToBuyLot(_db, buyTxId);
  }
}