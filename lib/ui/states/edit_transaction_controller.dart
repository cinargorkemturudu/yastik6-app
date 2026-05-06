import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/di/providers.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
// [EKLENDİ]: Tarihsel fiyat sorgusu için gerekli parametreler
import 'asset_history_provider.dart';

class EditTransactionState {
  final Transaction? originalTx;
  final bool isAllocated;
  final Decimal amount;
  final Decimal price;
  final DateTime date;
  final String? note;
  final String? errorMessage;
  final bool isLoading;

  EditTransactionState({
    this.originalTx,
    this.isAllocated = false,
    Decimal? amount,
    Decimal? price,
    DateTime? date,
    this.note,
    this.errorMessage,
    this.isLoading = true,
  })  : amount = amount ?? Decimal.zero,
        price = price ?? Decimal.zero,
        date = date ?? DateTime.now();

  EditTransactionState copyWith({
    Transaction? originalTx,
    bool? isAllocated,
    Decimal? amount,
    Decimal? price,
    DateTime? date,
    String? note,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return EditTransactionState(
      originalTx: originalTx ?? this.originalTx,
      isAllocated: isAllocated ?? this.isAllocated,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      date: date ?? this.date,
      note: note ?? this.note,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final editTransactionControllerProvider = NotifierProvider<EditTransactionController, EditTransactionState>(EditTransactionController.new);

class EditTransactionController extends Notifier<EditTransactionState> {
  @override
  EditTransactionState build() {
    return EditTransactionState();
  }

  Future<void> loadTransaction(String transactionId) async {
    try {
      final portfolioService = ref.read(portfolioServiceProvider);
      final tx = await portfolioService.getTransactionById(transactionId);

      if (tx == null) {
        throw Exception(AppStrings.messages.transactionNotFound);
      }

      final isAllocated = tx.remainingAmount < tx.amount;

      state = state.copyWith(
        originalTx: tx,
        isAllocated: isAllocated,
        amount: tx.amount,
        price: tx.purchasePrice,
        date: tx.purchaseDate,
        note: tx.note,
        isLoading: false,
      );

      AppLog.debug('EditTransactionState loaded for ${tx.id}. Allocated: $isAllocated', domain: 'UI_STATE');
    } catch (e, stackTrace) {
      AppLog.error("Failed to load transaction for editing", domain: 'UI_STATE', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        errorMessage: AppStrings.messages.unexpectedError,
        isLoading: false,
      );
    }
  }

  void updateAmount(String val) {
    if (state.isAllocated) return;
    final dec = AppFormatter.parseInput(val);
    state = state.copyWith(amount: dec, clearError: true);
  }

  void updatePrice(String val) {
    if (state.isAllocated) return;
    final dec = AppFormatter.parseInput(val);
    state = state.copyWith(price: dec, clearError: true);
  }

  // [DÜZELTİLDİ]: Tarih değişince o tarihin fiyatını otomatik getiren asenkron akış
  void updateDate(DateTime val) async {
    if (state.isAllocated) return;
    final now = DateTime.now();
    final dateWithTime = DateTime(
      val.year, val.month, val.day,
      now.hour, now.minute, now.second,
    );

    // Önce tarihi güncelle
    state = state.copyWith(date: dateWithTime, clearError: true);

    // Varlık kilitli değilse geçmiş fiyatı sorgula
    if (state.originalTx != null) {
      try {
        final params = HistoricalPriceParams(
          assetCode: state.originalTx!.assetId,
          date: dateWithTime,
        );

        final historicalPrice = await ref.read(historicalPriceProvider(params).future);

        if (historicalPrice != null && historicalPrice > Decimal.zero) {
          state = state.copyWith(price: historicalPrice);
          AppLog.info('Historical price auto-synced for edit', domain: 'UI_STATE');
        }
      } catch (e) {
        AppLog.warning('Could not fetch historical price for edit date.', domain: 'UI_STATE');
      }
    }
  }

  void updateNote(String val) {
    state = state.copyWith(note: val, clearError: true);
  }

  Future<bool> saveTransaction() async {
    final original = state.originalTx;

    if (original == null) {
      state = state.copyWith(errorMessage: AppStrings.messages.unexpectedError);
      return false;
    }

    if (!state.isAllocated && (state.amount <= Decimal.zero || state.price <= Decimal.zero)) {
      state = state.copyWith(errorMessage: AppStrings.messages.invalidForm);
      return false;
    }

    try {
      final portfolioService = ref.read(portfolioServiceProvider);

      await portfolioService.updateTransaction(
        originalTx: original,
        newAmount: state.amount,
        newPrice: state.price,
        newDate: state.date,
        newNote: state.note,
      );

      ref.read(portfolioProvider.notifier).refreshDb();
      AppLog.insight('transaction_edited', metadata: {'type': original.type.name, 'isAllocated': state.isAllocated.toString()});

      return true;
    } catch (e, stackTrace) {
      AppLog.error("Failed to edit transaction", domain: 'UI_STATE', error: e, stackTrace: stackTrace);
      String errorMessage = AppStrings.messages.transactionFailed;

      if (e.toString().contains('Tarih Hatası') || e.toString().contains('Timeline Paradox')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(errorMessage: errorMessage);
      return false;
    }
  }
}