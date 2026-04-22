
import 'package:yastik_alti/domain/models/dtos/portfolio_snapshot.dart';
import 'package:yastik_alti/domain/models/dtos/realized_profit.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';

/// A Composite DTO that holds the entire state of the portfolio.
/// This prevents "argument explosion" in the UI layer.
class PortfolioData {
  final PortfolioSnapshot snapshot;
  final PortfolioRealizedSummary? realizedSummary;
  final List<Transaction> transactions;
  final Map<String, List<Map<String, dynamic>>> allocationsMap;
  final bool isLoading;
  final String? errorMessage;

  const PortfolioData({
    required this.snapshot,
    required this.realizedSummary,
    required this.transactions,
    required this.allocationsMap,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Factory for an empty/loading state
  factory PortfolioData.initial() {
    return PortfolioData(
      snapshot: PortfolioSnapshot.empty(),
      realizedSummary: null,
      transactions: [],
      allocationsMap: {},
      isLoading: true,
      errorMessage: null,
    );
  }

  factory PortfolioData.error(String message) {
    return PortfolioData(
      snapshot: PortfolioSnapshot.empty(),
      realizedSummary: null,
      transactions: [],
      allocationsMap: {},
      isLoading: false, // Yüklenme bitti, hata var! Sonsuz loading'i keser.
      errorMessage: message,
    );
  }

  PortfolioData copyWith({
    PortfolioSnapshot? snapshot,
    PortfolioRealizedSummary? realizedSummary,
    List<Transaction>? transactions,
    Map<String, List<Map<String, dynamic>>>? allocationsMap,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PortfolioData(
      snapshot: snapshot ?? this.snapshot,
      realizedSummary: realizedSummary ?? this.realizedSummary,
      transactions: transactions ?? this.transactions,
      allocationsMap: allocationsMap ?? this.allocationsMap,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage, 
    );
  }
}