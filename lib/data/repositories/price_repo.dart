import 'package:yastik_alti/data/remote/remote_market_data.dart';
import 'package:yastik_alti/domain/irepositories/price_irepository.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/core/app_log.dart';

import '../local/market_cache_local.data.dart';

class PriceRepo implements PriceIRepository {
  final RemoteMarketData _remote;
  final MarketCacheLocalData _cache;

  PriceRepo(this._remote, this._cache);

  @override
  Future<List<PriceQuote>> getCachedAll() => _cache.getCache();

  @override
  Future<List<PriceQuote>> getLatestAll() async {
    try {
      final freshData = await _remote.fetchLatestAll();

      if (freshData.isNotEmpty) {
        // Ağ başarılıysa arka planda önbelleği güncelle
        await _cache.saveCache(freshData);
      }

      return freshData;
    } catch (e) {
      AppLog.warning('Ağ hatası: $e. Önbelleğe düşülüyor...', domain: 'REPO');

      final cachedData = await _cache.getCache();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Hem internet yok hem de önbellek boşsa hata fırlat
      rethrow;
    }
  }

  @override
  Future<List<PricePoint>> getHistory(String assetCode, String range) async {
    try {
      final freshData = await _remote.fetchHistory(assetCode: assetCode, range: range);

      if (freshData.isNotEmpty) {
        // Ağ başarılıysa grafiği önbelleğe kaydet
        await _cache.saveChartCache(assetCode, range, freshData);
      }

      return freshData;
    } catch (e) {
      AppLog.warning('Ağ hatası: $e. $assetCode ($range) için grafik önbelleğine düşülüyor...', domain: 'REPO');

      // İnternet yoksa, önbellekteki grafiği çek
      final cachedData = await _cache.getChartCache(assetCode, range);
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Hem internet yok hem de önbellek boşsa, UI'daki "Grafik Yüklenemedi" mesajı için hatayı fırlat
      rethrow;
    }
  }
}