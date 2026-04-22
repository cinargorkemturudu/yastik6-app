import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final converterViewModelProvider = NotifierProvider<ConverterViewModel, ConverterState>(ConverterViewModel.new);

class ConverterViewModel extends Notifier<ConverterState> {
  @override
  ConverterState build() {
    final marketState = ref.read(livePriceProvider).valueOrNull;

    PriceQuote? defFrom = marketState?.priceMap['USDTRY=X'] ?? marketState?.priceMap['USD'];
    PriceQuote? defTo = marketState?.priceMap['GRAM_ALTIN'] ?? marketState?.priceMap['GA'];

    return ConverterState(fromAsset: defFrom, toAsset: defTo);
  }

  ConverterState _enforceFirewall(ConverterState newState) {
    if (newState.mode == ExchangeMode.physical) {
      final fAsset = newState.fromAsset;
      final tAsset = newState.toAsset;

      bool fEligible = fAsset == null || AssetCatalog.isPhysicalEligible(fAsset.type, fAsset.assetCode);
      bool tEligible = tAsset == null || AssetCatalog.isPhysicalEligible(tAsset.type, tAsset.assetCode);

      if (!fEligible || !tEligible) {
        return newState.copyWith(mode: ExchangeMode.bank);
      }
    }
    return newState;
  }

  void updateAmount(Decimal newAmount) => state = state.copyWith(amount: newAmount);
  void updateHistoricalDate(DateTime date) => state = state.copyWith(historicalDate: date);

  void updateFromAsset(PriceQuote quote) {
    state = _enforceFirewall(state.copyWith(fromAsset: quote));
  }

  void updateToAsset(PriceQuote quote) {
    state = _enforceFirewall(state.copyWith(toAsset: quote));
  }

  void toggleMode(ExchangeMode newMode) {
    state = _enforceFirewall(state.copyWith(mode: newMode));
  }

  void swapAssets() {
    state = _enforceFirewall(state.copyWith(
        fromAsset: state.toAsset,
        toAsset: state.fromAsset
    ));
  }
}

// [FIXED] Now properly returning Decimal and comparing against Decimal.zero
final converterResultProvider = Provider.autoDispose<Decimal>((ref) {
  final state = ref.watch(converterViewModelProvider);
  final marketState = ref.watch(livePriceProvider).valueOrNull;

  if (state.fromAsset == null || state.toAsset == null || state.amount <= Decimal.zero) {
    return Decimal.zero;
  }

  final freshFrom = marketState?.priceMap[state.fromAsset!.assetCode] ?? state.fromAsset!;
  final freshTo = marketState?.priceMap[state.toAsset!.assetCode] ?? state.toAsset!;

  return ExchangeService.calculateExchange(
    mode: state.mode,
    amount: state.amount,
    fromAsset: freshFrom,
    toAsset: freshTo,
  );
});