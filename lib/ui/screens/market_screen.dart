import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]
import 'package:yastik_alti/ui/states/market_view_model.dart';
import 'package:yastik_alti/ui/widgets/cards/market_item_card.dart';
import 'package:yastik_alti/ui/ui_models/market_item_ui_model.dart';
import 'package:yastik_alti/ui/widgets/market_item_details_sheet.dart';

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

    return DefaultTabController(
      length: 6, // [GÜNCELLENDİ] 3 -> 6
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            AppStrings.titles.liveMarkets,
            style: AppTextStyles.h2,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Column(
              children: [
                // --- ARAMA ÇUBUĞU ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p16, vertical: AppDimens.p8), // [DÜZELTİLDİ]
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyLarge,
                    onChanged: (value) => viewModel.updateSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: AppStrings.form.searchAssetHint,
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted),
                      prefixIcon: const Icon(
                          Icons.search, color: AppColors.textMuted),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors
                            .textMuted),
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
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd), // [DÜZELTİLDİ]
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // --- KATEGORİ SEKMELERİ ---
                TabBar(
                  isScrollable: true,
                  // [YENİ] Sekmelerin ekrana sığması için yatay kaydırma aktif
                  tabAlignment: TabAlignment.start,
                  // [YENİ] Sekmeleri sola yaslar
                  indicatorColor: AppColors.textPrimary,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  dividerColor: Colors.transparent,
                  tabs: [
                    const Tab(text: "Tümü"),
                    // Uzun olmasın diye kısa bırakıldı
                    Tab(text: AppStrings.categories.metal),
                    Tab(text: AppStrings.categories.currency),
                    Tab(text: AppStrings.categories.stock),
                    // [YENİ EKLENDİ]
                    Tab(text: AppStrings.categories.crypto),
                    // [YENİ EKLENDİ]
                    Tab(text: AppStrings.categories.indicator),
                    // [YENİ EKLENDİ]
                  ],
                ),
              ],
            ),
          ),
        ),

        // --- GÖVDE ---
        body: TabBarView(
          children: [
            _buildFilteredList(
                state.isLoading, state.searchQuery, state.allItems),
            _buildFilteredList(
                state.isLoading, state.searchQuery, state.metalItems),
            _buildFilteredList(
                state.isLoading, state.searchQuery, state.currencyItems),
            _buildFilteredList(
                state.isLoading, state.searchQuery, state.stockItems),
            // [YENİ EKLENDİ]
            _buildFilteredList(
                state.isLoading, state.searchQuery, state.cryptoItems),
            // [YENİ EKLENDİ]
            _buildFilteredList(
                state.isLoading, state.searchQuery, state.indicatorItems),
            // [YENİ EKLENDİ]
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredList(bool isLoading, String searchQuery,
      List<MarketItemUiModel> items) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brandBlue));
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty
              ? AppStrings.messages.emptyData
              : AppStrings.messages.noResultsFor(searchQuery),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppDimens.p8, bottom: 80), // [DÜZELTİLDİ] (80 alt alan paddingi olarak bırakıldı)
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
              // Köşe ovalliğinin arkasında beyaz kalmaması için
              builder: (context) => MarketItemDetailsSheet(model: item),
            );
          },
        );
      },
    );
  }
}