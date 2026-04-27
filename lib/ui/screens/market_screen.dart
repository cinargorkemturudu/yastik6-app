import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/states/market_view_model.dart';
import 'package:yastik_alti/ui/widgets/cards/market_item_card.dart';
import 'package:yastik_alti/ui/ui_models/market_item_ui_model.dart';
import 'package:yastik_alti/ui/widgets/market_item_details_sheet.dart';
import 'package:yastik_alti/ui/utils/category_helper.dart'; // [EKLENDİ]

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

    // [MERKEZİ STANDART]: Kategoriler dinamik olarak Helper'dan alınıyor
    final categories = CategoryHelper.marketCategories;

    return DefaultTabController(
      length: categories.length, // Dinamik sekme sayısı
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
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p8),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyLarge,
                    onChanged: (value) => viewModel.updateSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: AppStrings.form.searchAssetHint,
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.updateSearchQuery("");
                          FocusScope.of(context).unfocus();
                        },
                      ) : null,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.textPrimary,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  dividerColor: Colors.transparent,
                  // [DİNAMİK SEKMELER]
                  tabs: categories.map((cat) => Tab(text: cat)).toList(),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          // [DİNAMİK LİSTELEME]: Seçilen kategoriye uyanlar filtrelenip çiziliyor
          children: categories.map((cat) {
            final filteredItems = state.allItems
                .where((item) => CategoryHelper.matchesCategory(item.type, cat))
                .toList();
            return _buildFilteredList(state.isLoading, state.searchQuery, filteredItems);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilteredList(bool isLoading, String searchQuery, List<MarketItemUiModel> items) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.brandBlue));

    if (items.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty ? AppStrings.messages.emptyData : AppStrings.messages.noResultsFor(searchQuery),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppDimens.p8, bottom: 80),
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