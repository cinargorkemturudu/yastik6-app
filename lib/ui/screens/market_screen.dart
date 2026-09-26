import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/states/market_view_model.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/ui/widgets/cards/market_item_card.dart';
import 'package:yastik_alti/ui/ui_models/market_item_ui_model.dart';
import 'package:yastik_alti/ui/widgets/market_item_details_sheet.dart';
import 'package:yastik_alti/ui/utils/category_helper.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketViewModelProvider);
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final marketState = ref.watch(livePriceProvider).valueOrNull;
    final neverSynced = marketState?.lastUpdate == null;
    final lastAttemptFailed = (marketState?.consecutiveFailures ?? 0) > 0;

    final categories = CategoryHelper.marketCategories;

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(AppStrings.titles.liveMarkets, style: AppTextStyles.h2),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p16,
                    vertical: AppDimens.p8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyLarge,
                    onChanged: (value) => viewModel.updateSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: AppStrings.form.searchAssetHint,
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                viewModel.updateSearchQuery("");
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.brandBlue,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  dividerColor: Colors.transparent,
                  tabs: categories.map((cat) => Tab(text: cat)).toList(),
                ),
              ],
            ),
          ),
        ),
        body: Container(
          margin: const EdgeInsets.only(top: AppDimens.p8),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(
              alpha: AppAlphas.tint,
            ), // Filling preserved
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(
              color: Colors.black,
              width: 1.0,
            ), // Black contour
          ),
          child: TabBarView(
            children: categories.map((cat) {
              final assetType = CategoryHelper.toAssetType(cat);
              final filteredItems = state.allItems.where((item) {
                if (assetType == null) return true;
                return item.type == assetType;
              }).toList();

              return _buildFilteredList(
                state.isLoading,
                state.searchQuery,
                filteredItems,
                neverSynced: neverSynced,
                lastAttemptFailed: lastAttemptFailed,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredList(
    bool isLoading,
    String searchQuery,
    List<MarketItemUiModel> items, {
    required bool neverSynced,
    required bool lastAttemptFailed,
  }) {
    if (isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandBlue),
      );

    if (items.isEmpty) {
      String message;
      if (searchQuery.isNotEmpty) {
        message = AppStrings.messages.noResultsFor(searchQuery);
      } else if (neverSynced && lastAttemptFailed) {
        message = AppStrings.messages.neverSyncedError;
      } else if (neverSynced) {
        message = AppStrings.messages.firstSyncPending;
      } else {
        message = AppStrings.messages.emptyData;
      }

      return Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppDimens.p16, bottom: 120),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MarketItemCard(
          model: item,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => MarketItemDetailsSheet(model: item),
            );
          },
        );
      },
    );
  }
}
