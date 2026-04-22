import 'package:decimal/decimal.dart';

enum TransactionType { sell, buy }

class Transaction {
  final String id;
  final String assetId;
  final TransactionType type;
  final Decimal amount;
  final Decimal purchasePrice;
  final DateTime purchaseDate;
  final String? note;
  final Decimal remainingAmount;

  const Transaction({
    required this.id,
    required this.assetId,
    required this.type,
    required this.amount,
    required this.purchasePrice,
    required this.purchaseDate,
    this.note,
    required this.remainingAmount,
  });

  Transaction copyWith({
    String? id,
    String? assetId,
    TransactionType? type,
    Decimal? amount,
    Decimal? purchasePrice,
    DateTime? purchaseDate,
    String? note,
    Decimal? remainingAmount,
  }) {
    return Transaction(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      note: note ?? this.note,
      remainingAmount: remainingAmount ?? this.remainingAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'type': type.name.toUpperCase(),
      // Decimal değerleri veritabanına kayıpsız String olarak yazıyoruz
      'amount': amount.toString(),
      'purchase_price': purchasePrice.toString(),
      'purchase_date': purchaseDate.toIso8601String(),
      'note': note,
      'remaining_amount': remainingAmount.toString(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      assetId: map['asset_id'],
      type: TransactionType.values.firstWhere(
            (e) => e.name.toUpperCase() == map['type'],
      ),
      // Veritabanından gelen String'i tekrar Decimal'e çeviriyoruz
      amount: Decimal.parse(map['amount'].toString()),
      purchasePrice: Decimal.parse(map['purchase_price'].toString()),
      purchaseDate: DateTime.parse(map['purchase_date']),
      note: map['note'],
      remainingAmount: Decimal.parse(map['remaining_amount'].toString()),
    );
  }
}