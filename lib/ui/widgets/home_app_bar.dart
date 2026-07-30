import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/domain/models/dtos/market_state.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketAsync = ref.watch(livePriceProvider);
    final marketState = marketAsync.valueOrNull ?? MarketState.initial();

    final health = marketState.healthStatus;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Text(
        "Yastık6 ™",
        style: AppTextStyles.h2.copyWith(letterSpacing: -0.5),
      ),
      actions: [
        _buildHealthIndicator(context, health, marketState),
        const SizedBox(width: AppDimens.p12), // [DÜZELTİLDİ]
      ],
    );
  }

  Widget _buildHealthIndicator(BuildContext context, DataHealthStatus health, MarketState state) {
    IconData icon;
    Color color;

    switch (health) {
      case DataHealthStatus.healthy:
        icon = Icons.cloud_done_rounded;
        color = AppColors.profitAccent;
        break;
      case DataHealthStatus.degraded:
        icon = Icons.warning_amber_rounded;
        color = Colors.orangeAccent;
        break;
      case DataHealthStatus.offline:
        icon = Icons.cloud_off_rounded;
        color = AppColors.lossAccent;
        break;
    }

    return GestureDetector(
      onTap: () => _showDiagnosticDialog(context, health, state),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.p8), // [DÜZELTİLDİ]
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppAlphas.hover), // [DÜZELTİLDİ]
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: AppDimens.iconMd), // [DÜZELTİLDİ]
      ),
    );
  }

  void _showDiagnosticDialog(BuildContext context, DataHealthStatus health, MarketState state) {
    showDialog(
      context: context,
      builder: (ctx) {
        final timeFormat = DateFormat('HH:mm:ss');

        final categoryUpdates = <AssetType, DateTime>{};
        final staleCategories = <AssetType>{};

        for (final asset in state.marketAssets) {
          if (!categoryUpdates.containsKey(asset.type) || asset.asOf.isAfter(categoryUpdates[asset.type]!)) {
            categoryUpdates[asset.type] = asset.asOf;
          }
          if (asset.isStale) {
            staleCategories.add(asset.type);
          }
        }

        String titleText;
        IconData titleIcon;
        Color titleColor;
        String bodyText;

        if (health == DataHealthStatus.healthy) {
          titleText = AppStrings.titles.systemHealthy;
          titleIcon = Icons.cloud_done_rounded;
          titleColor = AppColors.profitAccent;
          bodyText = AppStrings.messages.systemHealthyBody;
        } else if (health == DataHealthStatus.offline) {
          titleText = AppStrings.titles.connectionLost;
          titleIcon = Icons.cloud_off_rounded;
          titleColor = AppColors.lossAccent;
          bodyText = AppStrings.messages.offlineBody;
        } else {
          titleText = AppStrings.titles.delayedData;
          titleIcon = Icons.warning_amber_rounded;
          titleColor = Colors.orangeAccent;

          final staleNames = staleCategories.map((t) => AssetVisualMapper.categoryNameOf(t)).join(', ');
          bodyText = "${AppStrings.messages.degradedBodyPrefix}$staleNames";
        }

        return AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Row(
            children: [
              Icon(titleIcon, color: titleColor),
              const SizedBox(width: AppDimens.p8), // [DÜZELTİLDİ]
              Text(
                titleText,
                style: AppTextStyles.h3,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bodyText,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.p16), // [DÜZELTİLDİ]

              if (categoryUpdates.isNotEmpty)
                Column(
                  children: categoryUpdates.entries.map((entry) {
                    final isCategoryStale = staleCategories.contains(entry.key);
                    final rowColor = isCategoryStale ? Colors.orangeAccent : AppColors.textPrimary;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.p8), // [DÜZELTİLDİ]
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              AssetVisualMapper.categoryNameOf(entry.key),
                              style: AppTextStyles.bodyMedium.copyWith(color: rowColor, fontWeight: FontWeight.w600)
                          ),
                          Text(
                              timeFormat.format(entry.value.toLocal()),
                              style: AppTextStyles.caption.copyWith(color: rowColor) // [DÜZELTİLDİ]
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.common.ok.toUpperCase(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.brandBlue)),
            ),
          ],
        );
      },
    );
  }
}