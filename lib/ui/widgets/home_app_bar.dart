// home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/domain/models/dtos/market_state.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/current_rates_ticker_section.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  // [DÜZELTİLDİ]: Ticker yüksekliği (36.0) AppBar boyutuna eklendi
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 36.0);

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
        icon: const Icon(Icons.menu, color: AppColors.brandBlue),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: SvgPicture.asset(
        'assets/asset_1.svg', // Dosya isminin boşluksuz ve küçük harf olduğundan emin olun
        width: 130.0,
        fit: BoxFit.contain,
      ),
      actions: [
        _buildHealthIndicator(context, health, marketState),
        const SizedBox(width: AppDimens.p12),
      ],
      // [EKLENDİ]: Ticker şeridi AppBar'ın bottom alanına sabitlendi
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(36.0),
        child: CurrentRatesTickerSection(),
      ),
    );
  }

  Widget _buildHealthIndicator(BuildContext context, DataHealthStatus health, MarketState state) {
    IconData icon;
    Color color;

    switch (health) {
      case DataHealthStatus.healthy:
        icon = Icons.cloud_done_rounded;
        color = AppColors.brandBlue;
        break;
      case DataHealthStatus.degraded:
        icon = Icons.warning_amber_rounded;
        color = Colors.orangeAccent;
        break;
      case DataHealthStatus.offline:
        icon = Icons.cloud_off_rounded;
        color = Colors.grey;
        break;
    }

    return GestureDetector(
      onTap: () => _showDiagnosticDialog(context, health, state),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.p8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppAlphas.hover),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: AppDimens.iconMd),
      ),
    );
  }

  void _showDiagnosticDialog(BuildContext context, DataHealthStatus health, MarketState state) {
    showDialog(
      context: context,
      builder: (ctx) {
        final timeFormat = DateFormat('HH:mm:ss');

        // Grab pre-calculated data directly from the state
        final categoryUpdates = state.categoryLastUpdates;
        final staleCategories = state.staleCategories;

        String titleText;
        IconData titleIcon;
        Color titleColor;
        String bodyText;

        if (health == DataHealthStatus.healthy) {
          titleText = AppStrings.titles.systemHealthy;
          titleIcon = Icons.cloud_done_rounded;
          titleColor = AppColors.brandBlue;
          bodyText = AppStrings.messages.systemHealthyBody;
        } else if (health == DataHealthStatus.offline) {
          titleText = AppStrings.titles.connectionLost;
          titleIcon = Icons.cloud_off_rounded;
          titleColor = Colors.grey;
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
              const SizedBox(width: AppDimens.p8),
              Expanded( // [EKLENDİ]: Metin taşmalarını önlemek için
                child: Text(
                  titleText,
                  style: AppTextStyles.h3,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bodyText,
                style: AppTextStyles.captionBold,
              ),
              const SizedBox(height: AppDimens.p16),

              if (categoryUpdates.isNotEmpty)
                Column(
                  children: categoryUpdates.entries.map((entry) {
                    final isCategoryStale = staleCategories.contains(entry.key);

                    final rowColor = isCategoryStale ? Colors.orangeAccent : AppColors.textPrimary;

                    final rowStyle = isCategoryStale
                        ? AppTextStyles.bodyMedium.copyWith(color: rowColor, fontWeight: FontWeight.w700)
                        : AppTextStyles.bodyMedium;

                    final timeStyle = isCategoryStale
                        ? AppTextStyles.captionBold.copyWith(color: rowColor)
                        : AppTextStyles.caption;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.p8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AssetVisualMapper.categoryNameOf(entry.key),
                            style: rowStyle,
                          ),
                          Text(
                            timeFormat.format(entry.value.toLocal()),
                            style: timeStyle,
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