import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/app_log.dart';
import 'db_constants.dart';

class LocalDatabase {

  // [EDITED] İndeksleri eklediğimiz için versiyonu 2'den 3'e çıkarıyoruz.
  static const _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    final db = _database;
    if (db != null) return db;
    
    final newDb = await _initDatabase();
    _database = newDb;
    return newDb;
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

        // [EDITED] Yeni kullanıcılar için tablolar oluşturulduktan hemen sonra indeksler de oluşturuluyor.
        await _createIndexes(db);
      },
      // Uygulama güncellendiğinde (eski versiyondan yeni versiyona geçişte) çalışacak göç bloğu.
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLog.insight('db_upgraded', metadata: {'from': oldVersion, 'to': newVersion});

        // Eğer kullanıcının cihazındaki veritabanı versiyonu 2'den küçükse bu göç (migration) işlemi yapılacak.
        if (oldVersion < 2) {

          // 1. ADIM: ASSETS TABLOSU GÖÇÜ
          // Yeni şemaya (TEXT) uygun geçici bir tablo oluşturuyoruz.
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
          // Eski tablodaki verileri alıp, SQLite'ın CAST komutu ile güvenli bir şekilde metne dönüştürerek yeni tabloya aktarıyoruz.
          await db.execute('''
            INSERT INTO assets_new 
            SELECT ${DbConstants.colId}, ${DbConstants.colName}, ${DbConstants.colSymbol}, ${DbConstants.colType}, CAST(${DbConstants.colCurrentPrice} AS TEXT), ${DbConstants.colLastUpdate} 
            FROM ${DbConstants.tableAssets}
          ''');
          // Eski tabloyu siliyoruz ve yeni tablonun adını orijinal isimle değiştiriyoruz.
          await db.execute('DROP TABLE ${DbConstants.tableAssets}');
          await db.execute('ALTER TABLE assets_new RENAME TO ${DbConstants.tableAssets}');

          // 2. ADIM: TRANSACTIONS TABLOSU GÖÇÜ
          // Aynı mantığı finansal alanların yoğun olduğu işlemler tablosu için yapıyoruz.
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

        // [EDITED] Versiyon 2'den 3'e geçiş (İndekslerin eklenmesi)
        // Eğer kullanıcı eski bir versiyondan (v1 veya v2) geliyorsa indeksleri onun cihazında da oluşturuyoruz.
        if (oldVersion < 3) {
          await _createIndexes(db);
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // [EDITED] İndeks oluşturma metodunu buraya ekliyoruz.
  Future<void> _createIndexes(Database db) async {
    // Transactions tablosunda asset_id'ye göre filtrelemeyi hızlandırır
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_asset_id ON ${DbConstants.tableTransactions}(${DbConstants.colAssetId})'
    );

    // Allocations tablosunda sell_tx_id ve buy_tx_id'ye göre aramaları hızlandırır (FIFO hesaplamaları için kritik)
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_allocations_sell_tx_id ON ${DbConstants.tableAllocations}(${DbConstants.colSellTxId})'
    );
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_allocations_buy_tx_id ON ${DbConstants.tableAllocations}(${DbConstants.colBuyTxId})'
    );
  }
}