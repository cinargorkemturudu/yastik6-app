import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/domain/irepositories/asset_irepository.dart';
import 'package:yastik_alti/data/local/asset_local_data.dart';

class AssetRepo implements AssetIRepository {
  final AssetLocalData _local;
  final Database _db;

  AssetRepo(this._local, this._db);

  @override
  Future<void> save(Asset asset) async {
    await _local.upsertRow(_db, asset.toMap());
  }

  @override
  Future<Asset?> getById(String id) async {
    final row = await _local.getRowById(_db, id);
    if (row == null) return null;
    return Asset.fromMap(row);
  }

  @override
  Future<List<Asset>> getAll() async {
    final rows = await _local.getAllRows(_db);
    return rows.map((x) => Asset.fromMap(x)).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _local.deleteById(_db, id);
  }

  @override
  Future<Map<Asset, List<Transaction>>> getAssetsWithTransactions() async {
    final rawRows = await _local.getAssetsWithActiveTransactions(_db);
    final grouped = groupBy(rawRows, (row) => row['asset_id']);

    final Map<Asset, List<Transaction>> result = {};

    for (var entry in grouped.entries) {
      final rows = entry.value;
      if (rows.isEmpty) continue;

      final firstRow = rows.first;

      final assetTypeStr = firstRow['asset_type'] as String;
      final asset = Asset(
        id: firstRow['asset_id'] as String,
        name: firstRow['name'] as String,
        symbol: firstRow['symbol'] as String,
        type: AssetType.values.firstWhere(
              (e) => e.name == assetTypeStr,
          orElse: () => AssetType.metal,
        ),
        // FIXED: Using Decimal instead of double for currentPrice
        currentPrice: Decimal.tryParse(firstRow['current_price'].toString()) ?? Decimal.zero,
        lastUpdate: DateTime.parse(firstRow['last_update'] as String),
      );

      final List<Transaction> transactions = rows.map((row) {
        final txTypeStr = (row['tx_type'] as String).toUpperCase();
        return Transaction(
          id: row['tx_id'] as String,
          assetId: asset.id,
          type: TransactionType.values.firstWhere(
                (e) => e.name.toUpperCase() == txTypeStr,
            orElse: () => TransactionType.buy,
          ),
          amount: Decimal.parse(row['amount'].toString()),
          purchasePrice: Decimal.parse(row['purchase_price'].toString()),
          purchaseDate: DateTime.parse(row['purchase_date'] as String),
          note: row['note'] as String?,
          remainingAmount: Decimal.parse(row['remaining_amount'].toString()),
        );
      }).toList();

      result[asset] = transactions;
    }

    return result;
  }
}