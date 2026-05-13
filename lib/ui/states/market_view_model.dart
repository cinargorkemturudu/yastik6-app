import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/ui_models/market_item_ui_model.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';

/// PURE DATA CLASS: Holds pre-calculated, UI-ready lists.
/// No mapping or logic methods allowed here!
class MarketScreenState {
  final bool isLoading;
  final String searchQuery;

  final List<MarketItemUiModel> allItems;
  final List<MarketItemUiModel> metalItems;
  final List<MarketItemUiModel> currencyItems;
  final List<MarketItemUiModel> stockItems;      // [YENİ EKLENDİ]
  final List<MarketItemUiModel> cryptoItems;     // [YENİ EKLENDİ]
  final List<MarketItemUiModel> indicatorItems;  // [YENİ EKLENDİ]

  const MarketScreenState({
    this.isLoading = true,
    this.searchQuery = '',
    this.allItems = const [],
    this.metalItems = const [],
    this.currencyItems = const [],
    this.stockItems = const [],
    this.cryptoItems = const [],
    this.indicatorItems = const [],
  });

  MarketScreenState copyWith({
    bool? isLoading,
    String? searchQuery,
    List<MarketItemUiModel>? allItems,
    List<MarketItemUiModel>? metalItems,
    List<MarketItemUiModel>? currencyItems,
    List<MarketItemUiModel>? stockItems,
    List<MarketItemUiModel>? cryptoItems,
    List<MarketItemUiModel>? indicatorItems,
  }) {
    return MarketScreenState(
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      allItems: allItems ?? this.allItems,
      metalItems: metalItems ?? this.metalItems,
      currencyItems: currencyItems ?? this.currencyItems,
      stockItems: stockItems ?? this.stockItems,
      cryptoItems: cryptoItems ?? this.cryptoItems,
      indicatorItems: indicatorItems ?? this.indicatorItems,
    );
  }
}

final marketViewModelProvider = NotifierProvider<MarketViewModel, MarketScreenState>(
  MarketViewModel.new,
);

class MarketViewModel extends Notifier<MarketScreenState> {
  // We keep the raw quotes privately in the controller. The UI doesn't need them.
  List<PriceQuote> _rawQuotes = [];

  @override
  MarketScreenState build() {
    ref.listen(livePriceProvider, (previous, next) {
      next.when(
        data: (domainMarketState) => _handleNewMarketData(domainMarketState.marketAssets),
        error: (err, stack) => state = state.copyWith(isLoading: false),
        loading: () {},
      );
    }, fireImmediately: true);

    return const MarketScreenState();
  }

  /// Triggers a re-calculation of UI lists based on the new search query.
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _recalculateLists();
  }

  /// Saves the new raw data and triggers a UI list recalculation.
  void _handleNewMarketData(List<PriceQuote> freshQuotes) {
    _rawQuotes = freshQuotes;
    _recalculateLists();
  }

  /// CORE BUSINESS LOGIC: 
  /// Filters the raw data ONCE and generates UI-ready models.
  /// Prevents the UI from doing heavy computation or garbage collection churn during build().
  void _recalculateLists() {
    final query = state.searchQuery.trim().toLowerCase();

    final filteredQuotes = _rawQuotes.where((quote) {
      if (quote.assetCode == 'TRY') return false;
      if (query.isEmpty) return true;
      return quote.name.toLowerCase().contains(query) ||
          quote.assetCode.toLowerCase().contains(query);
    }).toList();

    final allUiModels = filteredQuotes.map((q) => MarketItemUiModel.fromQuote(q)).toList();

    final metalUiModels = allUiModels.where((item) => _getAssetTypeByCode(item.assetCode) == AssetType.metal).toList();
    final currencyUiModels = allUiModels.where((item) => _getAssetTypeByCode(item.assetCode) == AssetType.currency).toList();

    // [YENİ EKLENDİ]
    final stockUiModels = allUiModels.where((item) => _getAssetTypeByCode(item.assetCode) == AssetType.stock).toList();
    final cryptoUiModels = allUiModels.where((item) => _getAssetTypeByCode(item.assetCode) == AssetType.crypto).toList();
    final indicatorUiModels = allUiModels.where((item) => _getAssetTypeByCode(item.assetCode) == AssetType.indicator).toList();

    state = state.copyWith(
      isLoading: false,
      allItems: allUiModels,
      metalItems: metalUiModels,
      currencyItems: currencyUiModels,
      stockItems: stockUiModels,         // [YENİ EKLENDİ]
      cryptoItems: cryptoUiModels,       // [YENİ EKLENDİ]
      indicatorItems: indicatorUiModels, // [YENİ EKLENDİ]
    );
  }

  // Small helper to determine type since UiModel doesn't hold Domain 'Type' directly
  AssetType _getAssetTypeByCode(String code) {
    final rawMatch = _rawQuotes.firstWhere((q) => q.assetCode == code);
    return rawMatch.type;
  }
}