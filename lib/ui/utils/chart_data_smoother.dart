import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';

class ChartPoint {
  final DateTime date;
  final double price;

  ChartPoint(this.date, this.price);
}

class ChartDataSmoother {
  static List<ChartPoint> processAndSmooth(List<PricePoint> rawData, {int period = 3}) {
    if (rawData.isEmpty) return [];

    // [FIXED] Retain pure PricePoint objects to keep the Decimal values intact
    List<PricePoint> cleanPoints = [];
    for (var point in rawData) {
      if (point.price <= Decimal.zero) continue;
      cleanPoints.add(point);
    }

    // If there aren't enough points to smooth, just cast and return them
    if (cleanPoints.length < period) {
      return cleanPoints.map((p) => ChartPoint(p.timestamp, p.price.toDouble())).toList();
    }

    List<ChartPoint> smoothedPoints = [];

    for (int i = 0; i < cleanPoints.length; i++) {
      if (i < period - 1) {
        // Math is safely done in Decimal space
        Decimal sum = Decimal.zero;
        for (int j = 0; j <= i; j++) {
          sum += cleanPoints[j].price;
        }
        // [FIXED] Used Decimal.fromInt() instead of Rational.fromInt() to fix the import error
        Decimal avg = (sum.toRational() / Decimal.fromInt(i + 1).toRational()).toDecimal(scaleOnInfinitePrecision: 10);
        smoothedPoints.add(ChartPoint(cleanPoints[i].timestamp, avg.toDouble()));
      } else {
        // Math is safely done in Decimal space
        Decimal sum = Decimal.zero;
        for (int j = 0; j < period; j++) {
          sum += cleanPoints[i - j].price;
        }
        // [FIXED] Used Decimal.fromInt() instead of Rational.fromInt() to fix the import error
        Decimal avg = (sum.toRational() / Decimal.fromInt(period).toRational()).toDecimal(scaleOnInfinitePrecision: 10);
        smoothedPoints.add(ChartPoint(cleanPoints[i].timestamp, avg.toDouble()));
      }
    }

    return smoothedPoints;
  }
}