import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/cards/app_asset_list_tile.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/utils/category_helper.dart'; // [EKLENDİ]

class UniversalAssetPickerSheet extends ConsumerStatefulWidget {
  final Function(PriceQuote) onSelected;
  final String title;
  final List<PriceQuote>? customAssetList;
  final String? customEmptyMessage;
  final TransactionType? transactionType;

  const UniversalAssetPickerSheet({
    super.key,
    required this.onSelected,
    this.title = "Varlık Seçin",
    this.customAssetList,
    this.customEmptyMessage,
    this.transactionType,
  });

  @override
  ConsumerState<UniversalAssetPickerSheet> createState() => _UniversalAssetPickerSheetState();
}

class _UniversalAssetPickerSheetState extends ConsumerState<UniversalAssetPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  // [MERKEZİ STANDART]: İlk sekme all olarak seçili
  String _selectedCategory = AppStrings.categories.all;
  final List<String> _categories = CategoryHelper.coreCategories;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceAssets = widget.customAssetList ?? ref.watch(livePriceProvider).valueOrNull?.marketAssets ?? [];

    final filteredAssets = sourceAssets.where((quote) {
      final searchMatches = quote.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quote.assetCode.toLowerCase().contains(_searchQuery.toLowerCase());

      // [MERKEZİ STANDART]: Filtreleme kuralı helper'a soruluyor
      bool categoryMatches = CategoryHelper.matchesCategory(quote.type, _selectedCategory);

      return searchMatches && categoryMatches;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.p12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: AppAlphas.borderLight), borderRadius: BorderRadius.circular(AppDimens.radiusXs))),
              const SizedBox(height: AppDimens.p16),
              Text(widget.title, style: AppTextStyles.h3),
              const SizedBox(height: AppDimens.p16),

              TextField(
                controller: _searchCtrl,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: AppStrings.form.searchAssetHint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                      FocusScope.of(context).unfocus();
                    },
                  ) : null,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppDimens.p16),

              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: AppDimens.p8),
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandBlue : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.brandBlue : AppColors.textPrimary.withValues(alpha: AppAlphas.hover)),
                        ),
                        child: Text(cat, style: AppTextStyles.captionBold.copyWith(color: isSelected ? Colors.white : AppColors.textSecondary)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimens.p16),

              Expanded(
                child: filteredAssets.isEmpty
                    ? Center(
                  child: Text(
                    _searchQuery.isEmpty ? (widget.customEmptyMessage ?? AppStrings.messages.emptyTicker) : AppStrings.messages.noResultsFor(_searchQuery),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: filteredAssets.length,
                  itemBuilder: (context, index) {
                    final quote = filteredAssets[index];
                    final isSellingFlow = widget.transactionType == TransactionType.sell;

                    String displayTitle;
                    String? displaySubtitle;

                    switch (quote.type) {
                      case AssetType.stock:
                        displayTitle = quote.name;
                        displaySubtitle = quote.assetCode;
                        break;
                      case AssetType.metal:
                        displayTitle = quote.name;
                        displaySubtitle = null;
                        break;
                      default:
                        displayTitle = AppFormatter.cleanAssetCode(quote.assetCode);
                        displaySubtitle = quote.name.replaceAll(' USD', '').replaceAll('(USD)', '').trim();
                        break;
                    }

                    final displayPrice = AppFormatter.money(isSellingFlow ? quote.bid.toDouble() : quote.ask.toDouble());
                    final trailingSubtitle = isSellingFlow ? AppStrings.form.currentBuyRate : AppStrings.form.currentSellRate;

                    return AppAssetListTile(
                      margin: const EdgeInsets.only(bottom: AppDimens.p10),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        widget.onSelected(quote);
                      },
                      leading: SizedBox(
                        width: 36, height: 36,
                        child: AssetVisualMapper.getAvatar(assetCode: quote.assetCode, type: quote.type),
                      ),
                      title: Text(displayTitle, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                      subtitle: displaySubtitle != null ? Text(displaySubtitle, style: AppTextStyles.caption) : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(displayPrice, style: AppTextStyles.priceLarge.copyWith(fontWeight: FontWeight.w800)),
                          Text(trailingSubtitle, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}