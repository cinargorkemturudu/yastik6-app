import 'package:yastik_alti/domain/irepositories/asset_irepository.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';

class AssetService {
  final AssetIRepository repo;

  AssetService(this.repo);

  Future<void> saveAsset(Asset asset) async {
    await repo.save(asset);
  }

  Future<List<Asset>> getAllAsync() async {
    return await repo.getAll();
  }

  Future<Asset?> getAsset(String id) async {
    return await repo.getById(id);
  }
  
  Future<void> deleteAsset(String id) async {
    await repo.delete(id);
  }
}