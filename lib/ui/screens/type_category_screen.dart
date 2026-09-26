import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';

import '../states/portfolio_provider.dart';
import '../states/live_price_provider.dart';
import '../ui_models/owned_asset_list_item_model.dart';
import '../widgets/cards/asset_accordion_item.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final AssetType? categoryType;
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.categoryType,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  bool _isAtBottom = false;
  final ScrollController _scrollController = ScrollController();
  final double _navbarClearance = 116.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkBottom() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.extentAfter <= 15.0;
    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioData = ref.watch(portfolioProvider);
    final marketState = ref.watch(livePriceProvider).valueOrNull;

    final assetNames = {
      if (marketState != null)
        for (var quote in marketState.marketAssets) quote.assetCode: quote.name,
    };

    if (portfolioData.isLoading && portfolioData.snapshot.positions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = portfolioData.snapshot;

    final positions = snapshot.positions.where((p) {
      if (widget.categoryType == null) return true;
      return p.assetType == widget.categoryType;
    }).toList();

    final Decimal totalValue = positions.fold(
      Decimal.zero,
      (sum, p) => sum + p.currentValue,
    );
    final Decimal totalProfit = positions.fold(
      Decimal.zero,
      (sum, p) => sum + p.profit,
    );

    final items = positions.map((p) {
      final rawName = assetNames[p.asset.symbol] ?? p.asset.name;
      String dTitle;
      String? dSubtitle;

      switch (p.assetType) {
        case AssetType.stock:
          dTitle = rawName;
          dSubtitle = p.asset.symbol;
          break;
        case AssetType.metal:
          dTitle = rawName;
          dSubtitle = null;
          break;
        default:
          dTitle = AppFormatter.cleanAssetCode(p.asset.symbol);
          dSubtitle = rawName
              .replaceAll(' USD', '')
              .replaceAll('(USD)', '')
              .trim();
          break;
      }

      return OwnedAssetListItemModel(
        assetId: p.asset.id,
        type: p.assetType,
        title: rawName,
        amountText: AppFormatter.amount(p.totalAmount, ""),
        currentPriceText: AppFormatter.money(p.currentPrice),
        totalValueText: AppFormatter.money(p.currentValue),
        pnlPercent: AppFormatter.percent(p.profitPct),
        pnlColor: p.profit.toPnlColor(),
        avgCostText: AppFormatter.money(p.averageBuyPrice),
        averageBuyPrice: p.averageBuyPrice,
        pnlValueText: AppFormatter.pnlValue(p.profit),
        displayTitle: dTitle,
        displaySubtitle: dSubtitle,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.categoryName.toUpperCase(), style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- HEADER: TOPLAM DEĞER ---
          Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.p24),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(
                  alpha: AppAlphas.tint,
                ), // Filled with brand blue
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.titles.totalValue.toUpperCase(),
                    style: AppTextStyles.captionBold.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: AppDimens.p16),
                  Text(
                    AppFormatter.money(totalValue),
                    style: AppTextStyles.heroAmount,
                  ),
                  Text(
                    "${AppFormatter.pnlValue(totalProfit)} (${AppStrings.labels.totalPnl})",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: totalProfit.toPnlColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BODY: VARLIK LİSTESİ ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.p16,
                0,
                AppDimens.p16,
                0,
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: _isAtBottom
                        ? _navbarClearance
                        : -1.0, // Off-screen clip fix
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Hollow
                        borderRadius: _isAtBottom
                            ? const BorderRadius.all(Radius.circular(24))
                            : const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                        border: Border.all(
                          color: AppColors.brandBlue.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 14,
                                color: AppColors.brandBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "VARLIK LİSTESİ",
                                style: AppTextStyles.captionBold,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.axis == Axis.vertical) {
                                _checkBottom();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                _navbarClearance + 16,
                              ),
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              itemCount: items.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                return AssetAccordionItem(model: items[index]);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
