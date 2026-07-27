import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/ui/states/ticker_preferences_provider.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart'; // [EKLENDİ]
import 'package:yastik_alti/ui/utils/category_helper.dart'; // [EKLENDİ]

class TickerSettingsSheet extends ConsumerStatefulWidget {
  const TickerSettingsSheet({super.key});

  @override
  ConsumerState<TickerSettingsSheet> createState() => _TickerSettingsSheetState();
}

class _TickerSettingsSheetState extends ConsumerState<TickerSettingsSheet> {
  String _searchQuery = '';

  // [MERKEZİ STANDART]: Artık AssetType yerine String (_selectedCategory) kullanılıyor
  String _selectedCategory = AppStrings.categories.all;
  final List<String> _categories = CategoryHelper.coreCategories;

  @override
  Widget build(BuildContext context) {
    final marketAsync = ref.watch(livePriceProvider);
    final preferencesAsync = ref.watch(tickerPreferencesProvider);

    final marketAssets = marketAsync.valueOrNull?.marketAssets ?? [];
    final selectedCodes = preferencesAsync.valueOrNull ?? [];

    final filteredAssets = marketAssets.where((asset) {
      final matchesSearch = asset.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          asset.assetCode.toLowerCase().contains(_searchQuery.toLowerCase());

      // [MERKEZİ STANDART]: Filtreleme kuralı helper'a soruluyor
      final matchesType = CategoryHelper.matchesCategory(asset.type, _selectedCategory);

      return matchesSearch && matchesType;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.p12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: AppAlphas.borderLight),
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            ),
          ),
          const SizedBox(height: AppDimens.p16),

          Text('Şerit Kişiselleştirme', style: AppTextStyles.h3),
          const SizedBox(height: AppDimens.p16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            child: TextField(
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Varlık ara (Örn: Altın, USD)...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: AppDimens.p12),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimens.p8),
                  child: _buildFilterChip(cat),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          const Divider(height: AppDimens.dividerHeight, color: AppColors.surfaceLight),

          Expanded(
            child: preferencesAsync.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: AppDimens.p24, top: AppDimens.p8),
              itemCount: filteredAssets.length,
              itemBuilder: (context, index) {
                final asset = filteredAssets[index];
                final isSelected = selectedCodes.contains(asset.assetCode);

                // [TEMİZLİK]: Diğer ekranlarda kullandığımız USD temizliği buraya da eklendi
                String displayTitle;
                String? displaySubtitle;

                switch (asset.type) {
                  case AssetType.stock:
                    displayTitle = asset.name;
                    displaySubtitle = asset.assetCode;
                    break;
                  case AssetType.metal:
                    displayTitle = asset.name;
                    displaySubtitle = null;
                    break;
                  default:
                    displayTitle = AppFormatter.cleanAssetCode(asset.assetCode);
                    displaySubtitle = asset.name.replaceAll(' USD', '').replaceAll('(USD)', '').trim();
                    break;
                }

                return CheckboxListTile(
                  value: isSelected,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return AppColors.brandBlue;
                    return null;
                  }),
                  checkColor: AppColors.textPrimary,
                  title: Text(displayTitle, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: displaySubtitle != null ? Text(displaySubtitle, style: AppTextStyles.caption) : null,
                  onChanged: (bool? newValue) {
                    ref.read(tickerPreferencesProvider.notifier).toggleAsset(asset.assetCode);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String cat) {
    final isSelected = _selectedCategory == cat;
    return ChoiceChip(
      label: Text(cat),
      selected: isSelected,
      selectedColor: AppColors.brandBlue.withValues(alpha: AppAlphas.bgMedium),
      backgroundColor: AppColors.background,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedCategory = cat),
    );
  }
}