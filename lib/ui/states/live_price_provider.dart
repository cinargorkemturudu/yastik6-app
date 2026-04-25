import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/di/providers.dart';
import 'package:yastik_alti/domain/models/dtos/market_state.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import '../../domain/assets/asset_catalog.dart';
import '../../domain/models/entities/asset.dart';

final livePriceProvider = AsyncNotifierProvider<LivePriceNotifier, MarketState>(LivePriceNotifier.new);

class LivePriceNotifier extends AsyncNotifier<MarketState> {
  Timer? _timer;

  @override
  Future<MarketState> build() async {
    AppLog.debug('LivePriceNotifier built: Starting price service', domain: 'STATE');
    AppLog.insight('live_price_service_started');

    ref.onDispose(() {
      AppLog.debug('LivePriceNotifier disposed: Canceling timer', domain: 'STATE');
      _timer?.cancel();
    });

    final service = ref.read(priceServiceProvider);

    // 1. ANINDA UI ÇİZİMİ İÇİN ÖNBELLEĞİ YÜKLE
    final cachedQuotes = await service.getCachedAll();
    if (cachedQuotes.isNotEmpty) {
      AppLog.info('Loaded ${cachedQuotes.length} items from offline cache.', domain: 'STATE');
      state = AsyncData(_buildMarketState(cachedQuotes));
    }

    // 2. ARKAPLANDA CANLI VERİ DÖNGÜSÜNÜ BAŞLAT
    _timer ??= Timer.periodic(const Duration(seconds: 20), (_) => _refresh());

    // 3. İLK AĞ İSTEĞİNİ YAP
    return _fetchData();
  }

  Future<MarketState> _fetchData() async {
    final service = ref.read(priceServiceProvider);
    List<PriceQuote> quotes = await service.getLatestAll();
    return _buildMarketState(quotes);
  }

  // Yardımcı metod: USD dönüşümlerini ve state oluşturmayı tek yerden yapar
  MarketState _buildMarketState(List<PriceQuote> quotes) {
    PriceQuote? usdQuote;
    try {
      usdQuote = quotes.firstWhere((q) => q.assetCode == 'USD' || q.assetCode == 'USDTRY=X');
    } catch (e) {
      AppLog.error(
        'USD kuru bulunamadı! Yabancı varlıklar (Kripto, Ons) TL\'ye çevrilemeyecek.',
        domain: 'STATE',
      );
    }

    final Decimal usdRate = usdQuote?.midPrice ?? Decimal.one;

    if (usdRate > Decimal.one) {
      quotes = quotes.map((q) {
        if (AssetCatalog.isPricedInUsd(q.assetCode)) {
          if (q.type != AssetType.indicator) {
            return q.toConvertedTry(usdRate);
          }
        }
        return q;
      }).toList();
    }

    return MarketState(
      marketAssets: quotes,
      priceMap: {for (var q in quotes) q.assetCode: q},
      lastUpdate: DateTime.now(),
    );
  }

  Future<void> _refresh() async {
    AppLog.debug('Polling new prices from API (20s interval)', domain: 'STATE');

    try {
      final newData = await _fetchData();
      state = AsyncData(newData);

      AppLog.info('Market state updated successfully with ${newData.marketAssets.length} assets', domain: 'STATE');
      AppLog.insight('live_price_refreshed');
    } catch (e, stack) {
      AppLog.warning('Failed to fetch new prices, preserving old state', domain: 'STATE');
      AppLog.error('Price refresh error', domain: 'STATE', error: e, stackTrace: stack);
      AppLog.insight('live_price_refresh_failed');
    }
  }
}