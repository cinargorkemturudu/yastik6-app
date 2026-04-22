// lib/ui/states/edit_transaction_controller.dart

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/di/providers.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';

/// Represents the UI state of the transaction edit form.
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

/// Manages the state and validation logic for editing an existing transaction.
class EditTransactionController extends Notifier<EditTransactionState> {
  @override
  EditTransactionState build() {
    return EditTransactionState();
  }

  /// Loads the transaction by ID and calculates its allocation lock status.
  Future<void> loadTransaction(String transactionId) async {
    try {
      final portfolioService = ref.read(portfolioServiceProvider);

      // Fetch the specific transaction securely with an O(1) query.
      final tx = await portfolioService.getTransactionById(transactionId);

      if (tx == null) {
        throw Exception(AppStrings.messages.transactionNotFound);
      }

      // Determines if the transaction is locked due to partial or full allocation.
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

  /// Updates the transaction amount if the field is not locked.
  void updateAmount(String val) {
    if (state.isAllocated) return;
    final dec = Decimal.tryParse(val.replaceAll(',', '.')) ?? Decimal.zero;
    state = state.copyWith(amount: dec, clearError: true);
  }

  /// Updates the transaction price if the field is not locked.
  void updatePrice(String val) {
    if (state.isAllocated) return;
    final dec = Decimal.tryParse(val.replaceAll(',', '.')) ?? Decimal.zero;
    state = state.copyWith(price: dec, clearError: true);
  }

  /// Updates the transaction date while preserving the exact time of execution.
  void updateDate(DateTime val) {
    if (state.isAllocated) return;
    final now = DateTime.now();
    final dateWithTime = DateTime(
      val.year,
      val.month,
      val.day,
      now.hour,
      now.minute,
      now.second,
    );
    state = state.copyWith(date: dateWithTime, clearError: true);
  }

  /// Updates the optional transaction note. This field remains unlocked.
  void updateNote(String val) {
    state = state.copyWith(note: val, clearError: true);
  }

  /// Validates the current form state and delegates the update to the service layer.
  Future<bool> saveTransaction() async {
    final original = state.originalTx;

    if (original == null) {
      state = state.copyWith(errorMessage: AppStrings.messages.unexpectedError);
      return false;
    }

    // Prevents submission of zero-values for unallocated transactions.
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

      // Refresh global portfolio state to reflect the latest database modifications.
      ref.read(portfolioProvider.notifier).refreshDb();
      AppLog.insight('transaction_edited', metadata: {'type': original.type.name, 'isAllocated': state.isAllocated.toString()});

      return true;
    } catch (e, stackTrace) {
      AppLog.error("Failed to edit transaction", domain: 'UI_STATE', error: e, stackTrace: stackTrace);

      String errorMessage = AppStrings.messages.transactionFailed;

      // Extract and present domain-level constraints (e.g., Timeline Paradox).
      if (e.toString().contains('Tarih Hatası') || e.toString().contains('Timeline Paradox')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(errorMessage: errorMessage);
      return false;
    }
  }
}