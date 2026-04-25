import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

// Local Data Sources
import 'package:yastik_alti/data/local/allocation_local_data.dart';
import 'package:yastik_alti/data/local/asset_local_data.dart';
import 'package:yastik_alti/data/local/transaction_local_data.dart';

// Remote Data Sources
import 'package:yastik_alti/data/remote/remote_market_data.dart';

// Repositories (Impl)
import 'package:yastik_alti/data/repositories/allocation_repo.dart';
import 'package:yastik_alti/data/repositories/asset_repo.dart';
import 'package:yastik_alti/data/repositories/price_repo.dart';
import 'package:yastik_alti/data/repositories/transaction_repo.dart';

// Repositories (Interfaces)
import 'package:yastik_alti/domain/irepositories/allocation_irepository.dart';
import 'package:yastik_alti/domain/irepositories/asset_irepository.dart';
import 'package:yastik_alti/domain/irepositories/price_irepository.dart';
import 'package:yastik_alti/domain/irepositories/transaction_irepository.dart';

// Services
import 'package:yastik_alti/domain/services/portfolio_service.dart';
import 'package:yastik_alti/domain/services/price_service.dart';

import '../core/env.dart';
import '../data/local/market_cache_local.data.dart';

// --- CORE INFRASTRUCTURE ---

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Database must be overridden in main.dart');
});

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final baseUrlProvider = Provider<String>((ref) {
  return Env.baseUrl;
});

// --- DATA SOURCES ---

final remoteHaremDataProvider = Provider<RemoteMarketData>((ref) {
  final client = ref.watch(httpClientProvider);
  final baseUrl = ref.watch(baseUrlProvider);

  return RemoteMarketData(
    client: client,
    baseUrl: baseUrl,
  );
});

// Local Data Sources (SQLite Helpers)
final assetLocalDataProvider = Provider((ref) => AssetLocalData());
final transactionLocalDataProvider = Provider((ref) => TransactionLocalData());
final allocationLocalDataProvider = Provider((ref) => AllocationLocalData());
final marketCacheLocalDataProvider = Provider((ref) => MarketCacheLocalData()); // <-- YENİ EKLENDİ

// --- REPOSITORIES ---

final priceRepoProvider = Provider<PriceIRepository>((ref) {
  final remote = ref.watch(remoteHaremDataProvider);
  final cache = ref.watch(marketCacheLocalDataProvider); // <-- YENİ EKLENDİ
  return PriceRepo(remote, cache); // <-- GÜNCELLENDİ
});

final assetRepoProvider = Provider<AssetIRepository>((ref) {
  final local = ref.watch(assetLocalDataProvider);
  final db = ref.watch(databaseProvider);
  return AssetRepo(local, db);
});

final allocationRepoProvider = Provider<AllocationIRepository>((ref) {
  final local = ref.watch(allocationLocalDataProvider);
  final db = ref.watch(databaseProvider);
  return AllocationRepo(local, db);
});

final transactionRepoProvider = Provider<TransactionIRepository>((ref) {
  final txLocal = ref.watch(transactionLocalDataProvider);
  final allocLocal = ref.watch(allocationLocalDataProvider);
  final db = ref.watch(databaseProvider);
  return TransactionRepo(txLocal, allocLocal, db);
});

// --- SERVICES ---

final priceServiceProvider = Provider<PriceService>((ref) {
  final repo = ref.watch(priceRepoProvider);
  return PriceService(repo);
});

final portfolioServiceProvider = Provider<PortfolioService>((ref) {
  final assetRepo = ref.watch(assetRepoProvider);
  final txRepo = ref.watch(transactionRepoProvider);
  final allocRepo = ref.watch(allocationRepoProvider);

  return PortfolioService(assetRepo, txRepo, allocRepo);
});