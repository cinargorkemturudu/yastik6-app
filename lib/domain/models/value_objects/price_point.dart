import 'package:decimal/decimal.dart';

class PricePoint {
  final DateTime timestamp;
  final Decimal price;

  const PricePoint({
    required this.timestamp,
    required this.price,
  });
}