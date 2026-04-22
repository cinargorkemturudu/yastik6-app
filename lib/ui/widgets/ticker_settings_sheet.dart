import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/ui/states/ticker_preferences_provider.dart';
import 'package:yastik_alti/ui/ui_models/ticker_preference_item_ui_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]

class TickerSettingsSheet extends ConsumerStatefulWidget {
  const TickerSettingsSheet({super.key});

  @override
  ConsumerState<TickerSettingsSheet> createState() => _TickerSettingsSheetState();
}

class _TickerSettingsSheetState extends ConsumerState<TickerSettingsSheet> {
  String _searchQuery = '';
  AssetType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final marketAsync = ref.watch(livePriceProvider);
    final preferencesAsync = ref.watch(tickerPreferencesProvider);

    final marketAssets = marketAsync.valueOrNull?.marketAssets ?? [];
    final selectedCodes = preferencesAsync.valueOrNull ?? [];

    final filteredAssets = marketAssets.where((asset) {
      final matchesSearch = asset.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          asset.assetCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || asset.type == _selectedType;

      return matchesSearch && matchesType;
    }).toList();

    final uiItems = filteredAssets.map((asset) => TickerPreferenceItemUiModel(
      assetCode: asset.assetCode,
      displayName: asset.name,
      type: asset.type,
      isSelected: selectedCodes.contains(asset.assetCode),
    )).toList();

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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              // [DÜZELTİLDİ]: withOpacity -> withValues
              color: AppColors.textMuted.withValues(alpha: AppAlphas.borderLight),
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            ),
          ),
          const SizedBox(height: AppDimens.p16),

          const Text(
            'Şerit Kişiselleştirme',
            style: AppTextStyles.h3,
          ),
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
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
              children: [
                _buildFilterChip('Tümü', null),
                const SizedBox(width: AppDimens.p8),
                _buildFilterChip('Döviz', AssetType.currency),
                const SizedBox(width: AppDimens.p8),
                _buildFilterChip('Altın/Gümüş', AssetType.metal),
                const SizedBox(width: AppDimens.p8),
                _buildFilterChip('Borsa', AssetType.stock),
                const SizedBox(width: AppDimens.p8),
                _buildFilterChip('Kripto', AssetType.crypto),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          const Divider(height: AppDimens.dividerHeight, color: AppColors.surfaceLight),

          Expanded(
            child: preferencesAsync.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: AppDimens.p24, top: AppDimens.p8),
              itemCount: uiItems.length,
              itemBuilder: (context, index) {
                final item = uiItems[index];
                return CheckboxListTile(
                  value: item.isSelected,
                  // [DÜZELTİLDİ]: activeColor -> fillColor
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.brandBlue;
                    }
                    return null;
                  }),
                  checkColor: AppColors.textPrimary,
                  title: Text(
                      item.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                      item.assetCode,
                      style: AppTextStyles.caption
                  ),
                  onChanged: (bool? newValue) {
                    ref.read(tickerPreferencesProvider.notifier).toggleAsset(item.assetCode);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AssetType? type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      // [DÜZELTİLDİ]: withOpacity -> withValues
      selectedColor: AppColors.brandBlue.withValues(alpha: AppAlphas.bgMedium),
      backgroundColor: AppColors.background,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedType = type),
    );
  }
}