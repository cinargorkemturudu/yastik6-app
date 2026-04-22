import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/di/providers.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/mappers/universal_portfolio_mapper.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/ui/ui_models/lot_ui_model.dart';
import 'package:yastik_alti/ui/ui_models/portfolio_donut_model.dart';

import 'live_price_provider.dart';

class HomeUiState {
  final AssetType? filterType;
  final bool isRealizedMode;

  const HomeUiState({this.filterType, this.isRealizedMode = false});

  HomeUiState copyWith({AssetType? filterType, bool? isRealizedMode}) {
    return HomeUiState(
      filterType: filterType,
      isRealizedMode: isRealizedMode ?? this.isRealizedMode,
    );
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeUiState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeUiState> {
  @override
  HomeUiState build() => const HomeUiState();

  void setFilter(AssetType? type) {
    if (state.filterType != type) {
      AppLog.debug('User changed portfolio filter to: ${type?.name ?? 'ALL'}',
          domain: 'UI_STATE');
      AppLog.insight('portfolio_filter_changed',
          metadata: {'filter': type?.name ?? 'ALL'});

      state =
          HomeUiState(filterType: type, isRealizedMode: state.isRealizedMode);
    }
  }

  void toggleRealizedMode() {
    final newMode = !state.isRealizedMode;
    AppLog.debug(
        'User toggled profit mode to: ${newMode ? 'Realized' : 'Active'}',
        domain: 'UI_STATE');
    AppLog.insight('profit_mode_toggled', metadata: {'is_realized': newMode});

    state = state.copyWith(isRealizedMode: newMode);
  }


  Future<void> deleteTransaction(String id) async {
    AppLog.debug('User Intent: Delete Transaction ($id)', domain: 'UI_ACTION');
    AppLog.insight('user_intent_delete_tx');

    try {
      await ref.read(portfolioServiceProvider).deleteTransaction(id);

      AppLog.info(
          'Transaction deleted successfully. Requesting engine refresh.',
          domain: 'UI_ACTION');
      ref.read(portfolioProvider.notifier).refreshDb();
    } catch (e, stack) {
      AppLog.error('Failed to delete transaction $id', domain: 'UI_ACTION',
          error: e,
          stackTrace: stack);
      AppLog.insight('user_intent_delete_tx_failed');
      rethrow;
    }
  }
}

final homeDisplayLotsProvider = Provider<List<LotUiModel>>((ref) {
  final data = ref.watch(portfolioProvider);
  final uiState = ref.watch(homeViewModelProvider);

  // [DEĞİŞTİRİLDİ]: İsim sözlüğünü dışarıya taşıdık ki Aktif Portföy de kullanabilsin
  final marketState = ref.watch(livePriceProvider).valueOrNull;
  final assetNames = {
    if (marketState != null)
      for (var quote in marketState.marketAssets) quote.assetCode: quote.name
  };

  if (uiState.isRealizedMode && data.realizedSummary != null) {
    return UniversalPortfolioMapper.toRealizedLotUiModels(
      summary: data.realizedSummary!,
      assetNames: assetNames,
      assetFilter: uiState.filterType,
    );
  }

  // [DEĞİŞTİRİLDİ]: Aktif portföy için de taze isim sözlüğünü enjekte ediyoruz
  return UniversalPortfolioMapper.toLotUiModels(
    positions: data.snapshot.positions,
    allocationsMap: data.allocationsMap,
    assetNames: assetNames,
    assetFilter: uiState.filterType,
  );
});

final homeDonutModelProvider = Provider<PortfolioDonutModel?>((ref) {
  final data = ref.watch(portfolioProvider);
  final uiState = ref.watch(homeViewModelProvider);

  final marketState = ref.watch(livePriceProvider).valueOrNull;
  final assetNames = {
    if (marketState != null)
      for (var quote in marketState.marketAssets) quote.assetCode: quote.name
  };

  if (uiState.isRealizedMode && data.realizedSummary != null) {
    return UniversalPortfolioMapper.toRealizedDonutModel(
      data.realizedSummary!,
      uiState.filterType,
      assetNames,
    );
  }

  return UniversalPortfolioMapper.toDonutModel(data.snapshot, uiState.filterType, assetNames);
});