import 'package:yastik_alti/domain/irepositories/price_irepository.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';

class PriceService {
  final PriceIRepository _repo;

  PriceService(this._repo);

  /// Tüm piyasayı getirir (Live Ticker ve Cache için)
  Future<List<PriceQuote>> getLatestAll() {
    return _repo.getLatestAll();
  }

  /// Grafik verisi (History Screen için)
  Future<List<PricePoint>> getHistory(String code, String range) {
    return _repo.getHistory(code, range);
  }
}