import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/domain/services/exchange_service.dart';
import 'package:yastik_alti/domain/assets/asset_catalog.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';

class ConverterState {
  final Decimal amount; // [CHANGED] to Decimal
  final PriceQuote? fromAsset;
  final PriceQuote? toAsset;
  final ExchangeMode mode;
  final DateTime? historicalDate;

  ConverterState({
    Decimal? amount,
    this.fromAsset,
    this.toAsset,
    this.mode = ExchangeMode.bank,
    this.historicalDate,
  }) : amount = amount ?? Decimal.zero;

  ConverterState copyWith({
    Decimal? amount,
    PriceQuote? fromAsset,
    PriceQuote? toAsset,
    ExchangeMode? mode,
    DateTime? historicalDate,
  }) {
    return ConverterState(
      amount: amount ?? this.amount,
      fromAsset: fromAsset ?? this.fromAsset,
      toAsset: toAsset ?? this.toAsset,
      mode: mode ?? this.mode,
      historicalDate: historicalDate ?? this.historicalDate,
    );
  }
}

final converterViewModelProvider =
    NotifierProvider<ConverterViewModel, ConverterState>(
      ConverterViewModel.new,
    );

class ConverterViewModel extends Notifier<ConverterState> {
  @override
  ConverterState build() {
    // 1. PUSU (LISTENER): Arka plandaki fiyat akışını sessizce dinleriz.
    ref.listen(livePriceProvider, (previous, next) {
      final marketState = next.valueOrNull;

      if (marketState != null) {
        // Sadece kullanıcının ekranı hala boşsa (müdahale etmediyse) varsayılanları ata
        if (state.fromAsset == null || state.toAsset == null) {
          PriceQuote? defFrom =
              marketState.priceMap['HAS_ALTIN'] ?? marketState.priceMap['HAS'];
          PriceQuote? defTo =
              marketState.priceMap['TRY'] ?? marketState.priceMap['TRY=X'];

          // State'i anında güncelleyerek UI'ı tetikle
          state = state.copyWith(fromAsset: defFrom, toAsset: defTo);
        }
      }
    });

    // 2. İLK BAKIŞ (SENKRON): Eğer veriler halihazırda önbellekte (cache) varsa,
    // hiç bekletmeden ekranı ilk saniyeden dolu başlat.
    final initialMarketState = ref.read(livePriceProvider).valueOrNull;
    PriceQuote? initialFrom =
        initialMarketState?.priceMap['HAS_ALTIN'] ??
        initialMarketState?.priceMap['HAS'];
    PriceQuote? initialTo =
        initialMarketState?.priceMap['TRY'] ??
        initialMarketState?.priceMap['TRY=X'];

    return ConverterState(fromAsset: initialFrom, toAsset: initialTo);
  }

  ConverterState _enforceFirewall(ConverterState newState) {
    if (newState.mode == ExchangeMode.physical) {
      final fAsset = newState.fromAsset;
      final tAsset = newState.toAsset;

      bool fEligible =
          fAsset == null ||
          AssetCatalog.isPhysicalEligible(fAsset.type, fAsset.assetCode);
      bool tEligible =
          tAsset == null ||
          AssetCatalog.isPhysicalEligible(tAsset.type, tAsset.assetCode);

      if (!fEligible || !tEligible) {
        return newState.copyWith(mode: ExchangeMode.bank);
      }
    }
    return newState;
  }

  void updateAmount(Decimal newAmount) =>
      state = state.copyWith(amount: newAmount);
  void updateHistoricalDate(DateTime date) =>
      state = state.copyWith(historicalDate: date);

  void updateFromAsset(PriceQuote quote) {
    state = _enforceFirewall(state.copyWith(fromAsset: quote));
  }

  void updateToAsset(PriceQuote quote) {
    state = _enforceFirewall(state.copyWith(toAsset: quote));
  }

  void toggleMode(ExchangeMode newMode) {
    final result = _enforceFirewall(state.copyWith(mode: newMode));
    if (result.mode != newMode) {
      AppLog.warning(
        'Physical mode blocked (asset not physical-eligible), reverted to bank mode',
        domain: 'CONVERTER',
      );
    } else {
      AppLog.insight(
        'converter_mode_changed',
        metadata: {'mode': result.mode.name},
      );
    }
    state = result;
  }

  void swapAssets() {
    AppLog.debug('Converter assets swapped', domain: 'CONVERTER');
    state = _enforceFirewall(
      state.copyWith(fromAsset: state.toAsset, toAsset: state.fromAsset),
    );
  }
}

// [FIXED] Now properly returning Decimal and comparing against Decimal.zero
final converterResultProvider = Provider.autoDispose<Decimal>((ref) {
  final state = ref.watch(converterViewModelProvider);
  final marketState = ref.watch(livePriceProvider).valueOrNull;

  if (state.fromAsset == null ||
      state.toAsset == null ||
      state.amount <= Decimal.zero) {
    return Decimal.zero;
  }

  final freshFrom =
      marketState?.priceMap[state.fromAsset!.assetCode] ?? state.fromAsset!;
  final freshTo =
      marketState?.priceMap[state.toAsset!.assetCode] ?? state.toAsset!;

  return ExchangeService.calculateExchange(
    mode: state.mode,
    amount: state.amount,
    fromAsset: freshFrom,
    toAsset: freshTo,
  );
});
