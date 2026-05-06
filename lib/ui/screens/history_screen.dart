import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/mappers/universal_portfolio_mapper.dart';
import 'package:yastik_alti/ui/ui_models/lot_ui_model.dart';
import 'package:yastik_alti/ui/widgets/cards/lot_card.dart';

import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/domain/models/dtos/market_state.dart';

// [YENİ] Edit akışı ve state yönetimi için gerekli importlar[cite: 3]
import 'package:yastik_alti/ui/widgets/edit_transaction/edit_transaction_sheet.dart';
import 'package:yastik_alti/ui/states/home_view_model.dart';

// Tasarım Sistemi ve Sözlük
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';

// Sıralama Seçenekleri
enum SortOption {
  dateDesc("En Yeni"),
  dateAsc("En Eski"),
  amountDesc("En Yüksek Tutar"),
  amountAsc("En Düşük Tutar");

  final String label;
  const SortOption(this.label);
}

class HistoryScreen extends ConsumerStatefulWidget {
  final AssetType? initialFilter;
  const HistoryScreen({super.key, this.initialFilter});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  AssetType? _selectedTypeFilter;
  SortOption _selectedSort = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _selectedTypeFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final portfolioData = ref.watch(portfolioProvider);
    final marketState = ref.watch(livePriceProvider).valueOrNull ?? MarketState.initial();

    if (portfolioData.isLoading && portfolioData.transactions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
      );
    }

    final allTransactions = portfolioData.transactions;
    final allocationsMap = portfolioData.allocationsMap;

    final Map<String, AssetType> assetTypesMap = {};
    final Map<String, String> assetNamesMap = {};

    for (var quote in marketState.marketAssets) {
      assetTypesMap[quote.assetCode] = quote.type;
      assetNamesMap[quote.assetCode] = quote.name;
    }

    var allLots = UniversalPortfolioMapper.toHistoryLots(
      allTransactions: allTransactions,
      allocationsMap: allocationsMap,
      assetFilter: null,
      assetTypes: assetTypesMap,
      filterType: HistoryFilterType.all,
      assetNames: assetNamesMap,
    );

    if (_selectedTypeFilter != null) {
      allLots = allLots.where((l) => l.type == _selectedTypeFilter).toList();
    }

    _applySorting(allLots);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.titles.history.toUpperCase(),
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: AppColors.textPrimary),
            color: AppColors.inputFill,
            onSelected: (val) => setState(() => _selectedSort = val),
            itemBuilder: (context) => SortOption.values.map((option) => PopupMenuItem(
              value: option,
              child: Text(
                option.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedSort == option ? AppColors.brandBlue : AppColors.textPrimary,
                  fontWeight: _selectedSort == option ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: allLots.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppDimens.p16, AppDimens.p8, AppDimens.p16, AppDimens.p40),
              itemCount: allLots.length,
              itemBuilder: (context, index) {
                final lot = allLots[index];
                return LotCard(
                  model: lot,
                  // [FIXED]: Edit ve Delete akışları bağlandı[cite: 3]
                  onEdit: () => EditTransactionSheet.show(context, ref, transactionId: lot.transactionId),
                  onDelete: () => _showDeleteConfirmDialog(context, lot.transactionId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p12),
      child: Row(
        children: [
          _buildChoiceChip("Tümü", null),
          const SizedBox(width: AppDimens.p8),
          _buildChoiceChip(AppStrings.categories.metal, AssetType.metal),
          const SizedBox(width: AppDimens.p8),
          _buildChoiceChip(AppStrings.categories.currency, AssetType.currency),
          const SizedBox(width: AppDimens.p8),
          _buildChoiceChip("Hisse", AssetType.stock),
          const SizedBox(width: AppDimens.p8),
          _buildChoiceChip("Kripto", AssetType.crypto),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, AssetType? type) {
    final bool isSelected = _selectedTypeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _selectedTypeFilter = type);
        }
      },
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.brandBlue.withValues(alpha: AppAlphas.bgMedium),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.brandBlue.withValues(alpha: AppAlphas.borderActive) : AppColors.textMuted.withValues(alpha: AppAlphas.hover),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // [YENİ] Silme onayı için yardımcı dialog[cite: 3]
  void _showDeleteConfirmDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(AppStrings.messages.deleteWarningTitle, style: AppTextStyles.h3),
        content: Text(
            AppStrings.messages.deleteWarningBody,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)
        ),
        actions: [
          TextButton(
            child: Text(AppStrings.common.cancel.toUpperCase(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text(AppStrings.common.delete.toUpperCase(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.lossAccent)),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(homeViewModelProvider.notifier).deleteTransaction(id);
            },
          ),
        ],
      ),
    );
  }

  void _applySorting(List<LotUiModel> lots) {
    switch (_selectedSort) {
      case SortOption.dateDesc:
        lots.sort((a, b) => b.sortDate.compareTo(a.sortDate));
        break;
      case SortOption.dateAsc:
        lots.sort((a, b) => a.sortDate.compareTo(b.sortDate));
        break;
      case SortOption.amountDesc:
        lots.sort((a, b) => b.amountValue.compareTo(a.amountValue));
        break;
      case SortOption.amountAsc:
        lots.sort((a, b) => a.amountValue.compareTo(b.amountValue));
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 48, color: AppColors.textFaint),
          const SizedBox(height: AppDimens.p16),
          Text(
            AppStrings.messages.emptyData,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}