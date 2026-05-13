import 'package:decimal/decimal.dart';
import 'package:yastik_alti/data/remote/remote_market_data.dart';
import 'package:yastik_alti/domain/irepositories/price_irepository.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/core/app_log.dart';
import '../../domain/models/entities/asset.dart';
import '../local/market_cache_local.data.dart';

// 1. RAM Önbelleği için küçük bir kapsül (Sadece bu dosyada yaşar)
class CachedChartData {
  final List<PricePoint> points;
  final DateTime fetchTime;
  CachedChartData(this.points, this.fetchTime);
}

class PriceRepo implements PriceIRepository {
  final RemoteMarketData _remote;
  final MarketCacheLocalData _cache;

  // L1: RAM Cache Havuzu (Uygulama açık kaldığı sürece yaşar, ışık hızında yanıt verir)
  final Map<String, CachedChartData> _memoryCache = {};

  PriceRepo(this._remote, this._cache);

  @override
  Future<List<PriceQuote>> getCachedAll() => _cache.getCache();

  @override
  Future<List<PriceQuote>> getLatestAll() async {
    try {
      final freshData = await _remote.fetchLatestAll();

      // 1. TRY (Türk Lirası) varlığını statik olarak oluştur
      final tryQuote = PriceQuote(
        assetCode: 'TRY',
        name: 'Türk Lirası',
        type: AssetType.currency,
        bid: Decimal.one,
        ask: Decimal.one,
        changeRate: 0.0,
        asOf: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 365)),
        isConvertedtoTry: false,
      );

      // 2. API'den gelen liste boş olsa da olmasa da TRY'yi en başa ekle
      freshData.insert(0, tryQuote);

      if (freshData.isNotEmpty) {
        // 3. Açıksa arka planda önbelleği güncelle (TRY artık diske de yazılıyor)
        await _cache.saveCache(freshData);
      }
      return freshData;
    } catch (e) {
      AppLog.warning('Ağ hatası: $e. Önbelleğe düşüyor...', domain: 'REPO');
      final cachedData = await _cache.getCache();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      // Hem internet yok hem de önbellek boşsa hata fırlat
      rethrow;
    }
  }

  // [YENİ]: Her grafik aralığı için özel TTL (Yaşam Süresi / Time-to-Live) kuralı
  Duration _getTtlForRange(String range) {
    switch (range) {
      case 'Day': return const Duration(minutes: 1); // Günlük çok hareketli, 1 dk tut
      case 'Week': return const Duration(minutes: 15);
      case 'Month': return const Duration(hours: 2);
      case 'ThreeMonths': return const Duration(hours: 6);
      case 'Year': return const Duration(hours: 24); // Yıllık grafik 1 gün boyunca değişmez
      default: return const Duration(minutes: 5);
    }
  }

  @override
  Future<List<PricePoint>> getHistory(String assetCode, String range) async {
    final cacheKey = '${assetCode}_$range';
    final now = DateTime.now();
    final ttl = _getTtlForRange(range);

    // --- 1. L1 RAM (MEMORY) CACHE KONTROLÜ (Işık Hızı) ---
    // Eğer veri RAM'de varsa ve süresi dolmadıysa, diske bile inmeden anında ver.
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey]!;
      if (now.difference(cached.fetchTime) < ttl) {
        AppLog.debug('[$cacheKey] RAM üzerinden anında servis edildi. (Sıfır I/O)', domain: 'REPO');
        return cached.points;
      }
    }

    // --- 2. L2 DISK CACHE KONTROLÜ (Kalıcı Hafıza) ---
    // Uygulama yeni açıldıysa RAM boştur. Önce diske (cihaz hafızasına) soruyoruz.
    final diskCache = await _cache.getChartCacheWithTime(assetCode, range);
    if (diskCache != null && diskCache.points.isNotEmpty) {
      if (now.difference(diskCache.fetchTime) < ttl) {
        AppLog.debug('[$cacheKey] Diskten okundu ve geçerli. API isteği iptal edildi.', domain: 'REPO');
        _memoryCache[cacheKey] = CachedChartData(diskCache.points, diskCache.fetchTime); // RAM'i ısıt
        return diskCache.points;
      }
    }

    // --- 3. L3 API İSTEĞİ (Cache yoksa veya süresi dolduysa) ---
    try {
      AppLog.info('[$cacheKey] API\'den taze veri çekiliyor...', domain: 'REPO');
      final freshData = await _remote.fetchHistory(assetCode: assetCode, range: range);

      if (freshData.isNotEmpty) {
        // Ağa gittik, aldık. Hem RAM'i hem Diski yeni paketle güncelliyoruz.
        _memoryCache[cacheKey] = CachedChartData(freshData, now);
        await _cache.saveChartCache(assetCode, range, freshData);
      }
      return freshData;
    } catch (e) {
      AppLog.warning('Ağ hatası: $e. $assetCode ($range) için fallback (bayat veri) deneniyor...', domain: 'REPO');

      // GRACEFUL DEGRADATION: Ağ koptuysa veya API çöktüyse, elimizdeki "tarihi geçmiş" veriyi dönüyoruz.
      // Hiç yoktan iyidir, grafik boş kalıp çökeceğine dünkü haliyle görünür.
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey]!.points;
      }
      if (diskCache != null && diskCache.points.isNotEmpty) {
        return diskCache.points;
      }
      rethrow; // Gerçekten gösterecek HİÇBİR ŞEY yoksa hata fırlat.
    }
  }
}