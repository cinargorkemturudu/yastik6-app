// current_rates_ticker_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/ui/states/ticker_preferences_provider.dart';
import 'package:yastik_alti/ui/ui_models/current_rates_ticker_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import '../../domain/models/dtos/market_state.dart';
import 'current_rates_ticker.dart';

class CurrentRatesTickerSection extends ConsumerWidget {
  const CurrentRatesTickerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketAsync = ref.watch(livePriceProvider);
    final marketState = marketAsync.valueOrNull ?? MarketState.initial();

    final preferencesAsync = ref.watch(tickerPreferencesProvider);
    final selectedAssetCodes = preferencesAsync.valueOrNull ?? [];

    if (marketState.marketAssets.isEmpty && marketAsync.isLoading) {
      return const SizedBox(
        height: 28,
        child: Center(
          child: LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: AppColors.surface,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final filteredAssets = marketState.marketAssets.where((asset) {
      return selectedAssetCodes.contains(asset.assetCode);
    }).toList();

    final items = filteredAssets.map((quote) {
      return TickerItemUiModel(
        assetCode: quote.assetCode,
        displayName: quote.name,
        bid: quote.bid,
        ask: quote.ask,
        asOf: quote.asOf,
        changePercent: quote.changeRate,
        isStale: quote.isStale,
      );
    }).toList(growable: false);

    // [DÜZELTİLDİ]: Segment 2 ayrımı için Ticker'ı sabit yükseklikli bir Container içine alıp, altına %50 opacity mavi border ekledik.
    return Container(
      height: 36.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.brandBlue.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: RepaintBoundary(
        child: CurrentRatesTicker(items: items),
      ),
    );
  }
}