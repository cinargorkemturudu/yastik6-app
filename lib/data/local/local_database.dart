import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/app_log.dart';
import 'db_constants.dart';

class LocalDatabase {
  static const _dbVersion = 3;

  // [YENİ] Strict Singleton Prensibi: Uygulama boyunca tek bir instance olmasını garanti eder.
  LocalDatabase._privateConstructor();
  static final LocalDatabase instance = LocalDatabase._privateConstructor();
  factory LocalDatabase() => instance;

  Database? _database;

  Future<Database> get database async {
    final db = _database;
    if (db != null) return db;

    final newDb = await _initDatabase();
    _database = newDb;
    return newDb;
  }

  // [YENİ] Veritabanı bağlantısını fiziksel olarak kapatıp RAM'den temizler ve baştan açar.
  Future<Database> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    AppLog.info('Database connection reset manually (Cloud Restore).', domain: 'DATABASE');
    return await database; // Yeniden init edilmesini tetikler
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        AppLog.insight('db_created', metadata: {'version': version});

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${DbConstants.tableAssets} (
            ${DbConstants.colId} TEXT PRIMARY KEY,
            ${DbConstants.colName} TEXT NOT NULL,
            ${DbConstants.colSymbol} TEXT NOT NULL,
            ${DbConstants.colType} INTEGER NOT NULL,
            ${DbConstants.colCurrentPrice} TEXT NOT NULL, 
            ${DbConstants.colLastUpdate} TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${DbConstants.tableTransactions}(
            ${DbConstants.colId} TEXT PRIMARY KEY,
            ${DbConstants.colAssetId} TEXT NOT NULL,
            ${DbConstants.colType} TEXT NOT NULL,
            ${DbConstants.colAmount} TEXT NOT NULL,
            ${DbConstants.colRemainingAmount} TEXT NOT NULL,
            ${DbConstants.colPurchasePrice} TEXT NOT NULL,
            ${DbConstants.colPurchaseDate} TEXT NOT NULL,
            ${DbConstants.colNote} TEXT,
            FOREIGN KEY (${DbConstants.colAssetId}) REFERENCES ${DbConstants.tableAssets}(${DbConstants.colId}) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${DbConstants.tableAllocations}(
            ${DbConstants.colId} TEXT PRIMARY KEY,
            ${DbConstants.colSellTxId} TEXT NOT NULL,
            ${DbConstants.colBuyTxId} TEXT NOT NULL,
            ${DbConstants.colQuantity} TEXT NOT NULL,
            FOREIGN KEY (${DbConstants.colSellTxId}) REFERENCES ${DbConstants.tableTransactions}(${DbConstants.colId}) ON DELETE CASCADE,
            FOREIGN KEY (${DbConstants.colBuyTxId}) REFERENCES ${DbConstants.tableTransactions}(${DbConstants.colId}) ON DELETE CASCADE
          )
        ''');

        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLog.insight('db_upgraded', metadata: {'from': oldVersion, 'to': newVersion});

        if (oldVersion < 2) {
          // 1. ADIM: ASSETS TABLOSU GÖÇÜ
          await db.execute('''
            CREATE TABLE assets_new (
              ${DbConstants.colId} TEXT PRIMARY KEY, 
              ${DbConstants.colName} TEXT NOT NULL, 
              ${DbConstants.colSymbol} TEXT NOT NULL, 
              ${DbConstants.colType} INTEGER NOT NULL, 
              ${DbConstants.colCurrentPrice} TEXT NOT NULL, 
              ${DbConstants.colLastUpdate} TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO assets_new 
            SELECT ${DbConstants.colId}, ${DbConstants.colName}, ${DbConstants.colSymbol}, ${DbConstants.colType}, CAST(${DbConstants.colCurrentPrice} AS TEXT), ${DbConstants.colLastUpdate} 
            FROM ${DbConstants.tableAssets}
          ''');
          await db.execute('DROP TABLE ${DbConstants.tableAssets}');
          await db.execute('ALTER TABLE assets_new RENAME TO ${DbConstants.tableAssets}');

          // 2. ADIM: TRANSACTIONS TABLOSU GÖÇÜ
          await db.execute('''
            CREATE TABLE transactions_new (
              ${DbConstants.colId} TEXT PRIMARY KEY, 
              ${DbConstants.colAssetId} TEXT NOT NULL, 
              ${DbConstants.colType} TEXT NOT NULL, 
              ${DbConstants.colAmount} TEXT NOT NULL, 
              ${DbConstants.colRemainingAmount} TEXT NOT NULL, 
              ${DbConstants.colPurchasePrice} TEXT NOT NULL, 
              ${DbConstants.colPurchaseDate} TEXT NOT NULL, 
              ${DbConstants.colNote} TEXT, 
              FOREIGN KEY (${DbConstants.colAssetId}) REFERENCES ${DbConstants.tableAssets}(${DbConstants.colId}) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            INSERT INTO transactions_new 
            SELECT ${DbConstants.colId}, ${DbConstants.colAssetId}, ${DbConstants.colType}, CAST(${DbConstants.colAmount} AS TEXT), CAST(${DbConstants.colRemainingAmount} AS TEXT), CAST(${DbConstants.colPurchasePrice} AS TEXT), ${DbConstants.colPurchaseDate}, ${DbConstants.colNote} 
            FROM ${DbConstants.tableTransactions}
          ''');
          await db.execute('DROP TABLE ${DbConstants.tableTransactions}');
          await db.execute('ALTER TABLE transactions_new RENAME TO ${DbConstants.tableTransactions}');

          // 3. ADIM: ALLOCATIONS TABLOSU GÖÇÜ
          await db.execute('''
            CREATE TABLE allocations_new (
              ${DbConstants.colId} TEXT PRIMARY KEY, 
              ${DbConstants.colSellTxId} TEXT NOT NULL, 
              ${DbConstants.colBuyTxId} TEXT NOT NULL, 
              ${DbConstants.colQuantity} TEXT NOT NULL, 
              FOREIGN KEY (${DbConstants.colSellTxId}) REFERENCES ${DbConstants.tableTransactions}(${DbConstants.colId}) ON DELETE CASCADE, 
              FOREIGN KEY (${DbConstants.colBuyTxId}) REFERENCES ${DbConstants.tableTransactions}(${DbConstants.colId}) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            INSERT INTO allocations_new 
            SELECT ${DbConstants.colId}, ${DbConstants.colSellTxId}, ${DbConstants.colBuyTxId}, CAST(${DbConstants.colQuantity} AS TEXT) 
            FROM ${DbConstants.tableAllocations}
          ''');
          await db.execute('DROP TABLE ${DbConstants.tableAllocations}');
          await db.execute('ALTER TABLE allocations_new RENAME TO ${DbConstants.tableAllocations}');
        }

        if (oldVersion < 3) {
          await _createIndexes(db);
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_asset_id ON ${DbConstants.tableTransactions}(${DbConstants.colAssetId})'
    );
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_allocations_sell_tx_id ON ${DbConstants.tableAllocations}(${DbConstants.colSellTxId})'
    );
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_allocations_buy_tx_id ON ${DbConstants.tableAllocations}(${DbConstants.colBuyTxId})'
    );
  }
}