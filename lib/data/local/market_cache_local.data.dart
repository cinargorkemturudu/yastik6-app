import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/core/app_log.dart';

class MarketCacheLocalData {
  // --- 1. LIVE MARKET CACHE LOGIC ---

  static const String _cacheKey = 'market_data_cache';

  Future<void> saveCache(List<PriceQuote> quotes) async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> jsonList = quotes.map((q) => {
      'assetCode': q.assetCode,
      'name': q.name,
      'type': q.type.name,
      'bid': q.bid.toString(),
      'ask': q.ask.toString(),
      'formattedBid': q.formattedBid,
      'formattedAsk': q.formattedAsk,
      'changeRate': q.changeRate,
      'asOf': q.asOf.toIso8601String(),
      'expiresAt': q.expiresAt.toIso8601String(),
    }).toList();

    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_cacheKey, jsonString);
    AppLog.debug('Market data cached successfully (${quotes.length} items)', domain: 'LOCAL_CACHE');
  }

  Future<List<PriceQuote>> getCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);

    if (jsonString == null) {
      AppLog.debug('No market cache found.', domain: 'LOCAL_CACHE');
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);

      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return PriceQuote(
          assetCode: map['assetCode'],
          name: map['name'],
          type: AssetType.values.firstWhere(
                (e) => e.name == map['type'],
            orElse: () => AssetType.metal,
          ),
          bid: Decimal.parse(map['bid'].toString()),
          ask: Decimal.parse(map['ask'].toString()),
          changeRate: (map['changeRate'] as num).toDouble(),
          asOf: DateTime.parse(map['asOf']),
          expiresAt: DateTime.parse(map['expiresAt']),
        );
      }).toList();
    } catch (e) {
      AppLog.error('Failed to parse market cache. Wiping corrupted cache.', domain: 'LOCAL_CACHE', error: e);
      await prefs.remove(_cacheKey);
      return [];
    }
  }

  // --- 2. CHART CACHING LOGIC (PHASE 3) ---

  Future<void> saveChartCache(String assetCode, String range, List<PricePoint> points) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chart_${assetCode}_$range';

    final List<Map<String, dynamic>> jsonList = points.map((p) => {
      'timestamp': p.timestamp.toIso8601String(), // [FIXED] Swapped 'date' to 'timestamp'
      'price': p.price.toString(),
    }).toList();

    await prefs.setString(key, jsonEncode(jsonList));
    AppLog.debug('Chart cached successfully: $key (${points.length} points)', domain: 'LOCAL_CACHE');
  }

  Future<List<PricePoint>> getChartCache(String assetCode, String range) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chart_${assetCode}_$range';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) {
        final map = item as Map<String, dynamic>;

        // Geriye dönük uyumluluk: Eski veriler 'date' anahtarıyla kaydedilmiş olabilir
        final rawDateString = map['timestamp'] ?? map['date'];

        return PricePoint(
          timestamp: DateTime.parse(rawDateString.toString()), // [FIXED] Swapped 'date' to 'timestamp'
          price: Decimal.parse(map['price'].toString()),
        );
      }).toList();
    } catch (e) {
      AppLog.error('Failed to parse chart cache. Wiping corrupted key: $key', domain: 'LOCAL_CACHE', error: e);
      await prefs.remove(key);
      return [];
    }
  }
}