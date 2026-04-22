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

    List<ChartPoint> cleanPoints = [];

    for (var point in rawData) {
      if (point.price <= Decimal.zero) continue; // [FIXED]

      cleanPoints.add(ChartPoint(point.timestamp, point.price.toDouble())); // [FIXED]
    }

    if (cleanPoints.length < period) return cleanPoints;

    List<ChartPoint> smoothedPoints = [];

    for (int i = 0; i < cleanPoints.length; i++) {
      if (i < period - 1) {
        double sum = 0;
        for (int j = 0; j <= i; j++) {
          sum += cleanPoints[j].price;
        }
        smoothedPoints.add(ChartPoint(cleanPoints[i].date, sum / (i + 1)));
      } else {
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += cleanPoints[i - j].price;
        }
        smoothedPoints.add(ChartPoint(cleanPoints[i].date, sum / period));
      }
    }

    return smoothedPoints;
  }
}