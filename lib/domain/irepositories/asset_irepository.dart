import 'package:yastik_alti/domain/models/entities/asset.dart';
import '../models/entities/transaction.dart';

abstract class AssetIRepository {
  Future<void> save(Asset asset);
  Future<Asset?>getById(String id);
  Future<List<Asset>>getAll();
  Future<void> delete(String id);
  Future<Map<Asset, List<Transaction>>> getAssetsWithTransactions();}