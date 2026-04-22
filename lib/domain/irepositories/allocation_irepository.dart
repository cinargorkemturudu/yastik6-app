abstract class AllocationIRepository {
  Future<List<Map<String, dynamic>>> getRealizedProfitByAsset(String assetId);
  Future<List<Map<String, dynamic>>> getAllRealizedProfits();
  Future<List<Map<String, dynamic>>> getLinkedSales(String buyTxId);
}