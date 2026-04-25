import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';

abstract class PriceIRepository {
  /// Tüm piyasa verilerini çeker (Snapshot)
  Future<List<PriceQuote>> getLatestAll();

  Future<List<PriceQuote>> getCachedAll();

  /// Belirli bir varlık için tarihsel verileri çeker (Grafik için)
  /// [range]: '1G', '1H', '1A' gibi backend'in beklediği parametre
  Future<List<PricePoint>> getHistory(String assetCode, String range);
}