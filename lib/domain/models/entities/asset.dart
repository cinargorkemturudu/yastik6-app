import 'package:decimal/decimal.dart';

enum AssetType { metal, currency, stock, crypto, indicator }

class Asset {
  final String id;
  final String name;
  final String symbol;
  final AssetType type;
  final Decimal currentPrice;

  Decimal get mid => currentPrice;

  final DateTime lastUpdate;

  Asset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.currentPrice,
    required this.lastUpdate,
  });

  Asset copyWith({
    String? id,
    String? name,
    String? symbol,
    AssetType? type,
    Decimal? currentPrice,
    DateTime? lastUpdate,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      currentPrice: currentPrice ?? this.currentPrice,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'type': type.name, // Sadece String isim kaydediliyor
      'current_price': currentPrice.toString(), // Decimal to String for safe SQLite storage
      'last_update': lastUpdate.toIso8601String(),
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String,
      type: AssetType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => AssetType.metal,
      ),
      currentPrice: Decimal.tryParse(map['current_price'].toString()) ?? Decimal.zero,
      lastUpdate: DateTime.parse(map['last_update'] as String),
    );
  }
}