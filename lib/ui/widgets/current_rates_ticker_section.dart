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

    return RepaintBoundary(
      child: CurrentRatesTicker(items: items),
    );
  }
}