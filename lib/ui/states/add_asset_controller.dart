import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/di/providers.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';

import 'asset_history_provider.dart';

class AddAssetState {
  final TransactionType transactionType;
  final PriceQuote? selectedAsset;
  final Decimal amount;
  final Decimal price;
  final DateTime date;
  final String? note;
  final String? errorMessage;

  AddAssetState({
    this.transactionType = TransactionType.buy,
    this.selectedAsset,
    Decimal? amount,
    Decimal? price,
    required this.date,
    this.note,
    this.errorMessage,
  })  : amount = amount ?? Decimal.zero,
        price = price ?? Decimal.zero;

  AddAssetState copyWith({
    TransactionType? transactionType,
    PriceQuote? selectedAsset,
    Decimal? amount,
    Decimal? price,
    DateTime? date,
    String? note,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddAssetState(
      transactionType: transactionType ?? this.transactionType,
      selectedAsset: selectedAsset ?? this.selectedAsset,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      date: date ?? this.date,
      note: note ?? this.note,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final addAssetControllerProvider = NotifierProvider<AddAssetController, AddAssetState>(AddAssetController.new);

class AddAssetController extends Notifier<AddAssetState> {
  @override
  AddAssetState build() {
    AppLog.debug('AddAsset controller initialized', domain: 'UI_STATE');
    return AddAssetState(date: DateTime.now());
  }

  List<PriceQuote> get availableQuotes {
    final livePrices = ref.read(livePriceProvider).valueOrNull?.marketAssets ?? [];

    if (state.transactionType == TransactionType.buy) {
      return livePrices;
    } else {
      final portfolio = ref.read(portfolioProvider);
      if (portfolio.snapshot.positions.isEmpty) return [];

      final ownedSymbols = portfolio.snapshot.positions
          .where((p) => p.totalAmount > Decimal.zero)
          .map((p) => p.asset.symbol)
          .toSet();

      return livePrices.where((q) => ownedSymbols.contains(q.assetCode)).toList();
    }
  }

  void updateTransactionType(TransactionType type) {
    AppLog.insight('transaction_type_changed', metadata: {'type': type.name});
    state = state.copyWith(transactionType: type, clearError: true);
  }

  void selectAsset(PriceQuote? quote) {
    final priceValue = quote != null
        ? (state.transactionType == TransactionType.buy ? quote.ask : quote.bid)
        : Decimal.zero;

    state = state.copyWith(
      selectedAsset: quote,
      price: priceValue,
      clearError: true,
    );
  }

  void updateAmount(String val) {
    final dec = AppFormatter.parseInput(val);
    state = state.copyWith(amount: dec, clearError: true);
  }

  void updatePrice(String val) {
    final dec = AppFormatter.parseInput(val);
    state = state.copyWith(price: dec, clearError: true);
  }

  void updateDate(DateTime val) async {
    final now = DateTime.now();
    final dateWithTime = DateTime(
      val.year,
      val.month,
      val.day,
      now.hour,
      now.minute,
      now.second,
    );

    // Önce tarihi güncelle
    state = state.copyWith(date: dateWithTime);

    // [YENİ]: Tarih değişince geçmiş fiyatı otomatik sorgula
    if (state.selectedAsset != null) {
      try {
        final params = HistoricalPriceParams(
            assetCode: state.selectedAsset!.assetCode,
            date: dateWithTime
        );

        // Provider üzerinden o tarihteki fiyatı oku
        final historicalPrice = await ref.read(historicalPriceProvider(params).future);

        if (historicalPrice != null && historicalPrice > Decimal.zero) {
          state = state.copyWith(price: historicalPrice);
          AppLog.info('Historical price auto-synced for ${state.selectedAsset!.assetCode}', domain: 'UI_STATE');
        }
      } catch (e) {
        AppLog.warning('Could not fetch historical price for the selected date.', domain: 'UI_STATE');
      }
    }
  }

  void updateNote(String val) => state = state.copyWith(note: val);

  Future<bool> saveTransaction() async {
    final currentAsset = state.selectedAsset;

    if (currentAsset == null || state.amount <= Decimal.zero || state.price <= Decimal.zero) {
      state = state.copyWith(errorMessage: AppStrings.messages.invalidForm);
      return false;
    }

    try {
      final portfolioService = ref.read(portfolioServiceProvider);

      DateTime finalDate = state.date;
      final now = DateTime.now();

      if (finalDate.year == now.year && finalDate.month == now.month && finalDate.day == now.day) {
        finalDate = DateTime(finalDate.year, finalDate.month, finalDate.day, now.hour, now.minute, now.second);
      }

      await portfolioService.createAndSaveTransaction(
        assetCode: currentAsset.assetCode,
        assetType: currentAsset.type,
        amount: state.amount,
        price: state.price,
        date: finalDate,
        type: state.transactionType,
        note: state.note,
        currentPrice: currentAsset.ask,
      );

      state = AddAssetState(date: DateTime.now());

      ref.read(portfolioProvider.notifier).refreshDb();
      AppLog.insight('transaction_saved', metadata: {'type': state.transactionType.name});

      return true;
    } catch (e, stackTrace) {
      AppLog.error("Transaction save failed", domain: 'UI_STATE', error: e, stackTrace: stackTrace);

      String errorMessage = AppStrings.messages.transactionFailed;
      if (e.toString().contains('INSUFFICIENT_BALANCE')) {
        errorMessage = AppStrings.messages.insufficientBalance;
      }

      state = state.copyWith(errorMessage: errorMessage);
      return false;
    }
  }
}