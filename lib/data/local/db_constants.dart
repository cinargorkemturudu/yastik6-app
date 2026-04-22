class DbConstants {
  static const String dbName = 'yastik_alti_v4.db';
  
  // --- Tablo İsimleri ---
  static const String tableAssets = 'assets';
  static const String tableTransactions = 'transactions';
  static const String tableAllocations = 'allocations';

  // --- Ortak Sütunlar ---
  static const String colId = 'id';
  static const String colType = 'type';

  // --- Assets (Varlıklar) Sütunları ---
  static const String colName = 'name';
  static const String colSymbol = 'symbol';
  static const String colCurrentPrice = 'current_price';
  static const String colLastUpdate = 'last_update';

  // --- Transactions (İşlemler) Sütunları ---
  static const String colAssetId = 'asset_id';
  static const String colAmount = 'amount';
  static const String colRemainingAmount = 'remaining_amount';
  static const String colPurchasePrice = 'purchase_price';
  static const String colPurchaseDate = 'purchase_date';
  static const String colNote = 'note';

  // --- Allocations (Bağlantılar) Sütunları ---
  static const String colSellTxId = 'sell_transaction_id';
  static const String colBuyTxId = 'buy_transaction_id';
  static const String colQuantity = 'quantity';
}