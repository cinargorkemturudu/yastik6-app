import 'package:decimal/decimal.dart';

class Allocation {
  final String id;
  final String sellTransactionId;
  final String buyTransactionId;
  final Decimal quantity;

  const Allocation({
    required this.id,
    required this.sellTransactionId,
    required this.buyTransactionId,
    required this.quantity,
  });

  Allocation copyWith({
    String? id,
    String? sellTransactionId,
    String? buyTransactionId,
    Decimal? quantity,
  }) {
    return Allocation(
      id: id ?? this.id,
      sellTransactionId: sellTransactionId ?? this.sellTransactionId,
      buyTransactionId: buyTransactionId ?? this.buyTransactionId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sell_transaction_id': sellTransactionId,
      'buy_transaction_id': buyTransactionId,
      'quantity': quantity.toString(), // Decimal to String
    };
  }

  factory Allocation.fromMap(Map<String, dynamic> map) {
    return Allocation(
      id: map['id'] as String,
      sellTransactionId: map['sell_transaction_id'] as String,
      buyTransactionId: map['buy_transaction_id'] as String,
      quantity: Decimal.parse(map['quantity'].toString()),
    );
  }
}