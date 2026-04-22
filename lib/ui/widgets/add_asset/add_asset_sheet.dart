import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/states/add_asset_controller.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/widgets/universal_asset_picker_sheet.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import '../../theme/app_strings.dart';
import 'asset_form_step.dart';

class AddAssetSheet extends ConsumerWidget {
  const AddAssetSheet({super.key});

  static void showFlow(BuildContext context, WidgetRef ref, {TransactionType type = TransactionType.buy}) {
    final controller = ref.read(addAssetControllerProvider.notifier);
    controller.updateTransactionType(type);
    controller.selectAsset(null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalAssetPickerSheet(
        title: type == TransactionType.buy ? AppStrings.converter.buyAsset : AppStrings.converter.sellAsset,
        transactionType: type,
        customAssetList: type == TransactionType.sell ? controller.availableQuotes : null,
        customEmptyMessage: type == TransactionType.sell
            ? AppStrings.messages.emptyPortfolioForSell
            : null,
        onSelected: (quote) {
          controller.selectAsset(quote);

          Future.delayed(const Duration(milliseconds: 50), () {
            if (context.mounted) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const AddAssetSheet(),
              );
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addAssetControllerProvider);
    final controller = ref.read(addAssetControllerProvider.notifier);

    if (state.selectedAsset == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)), // [DÜZELTİLDİ]
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p12), // [DÜZELTİLDİ]
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    // [DÜZELTİLDİ: Opasite ve Radius]
                    decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: AppAlphas.borderLight), borderRadius: BorderRadius.circular(AppDimens.radiusXs))
                ),
                const SizedBox(height: AppDimens.p24), // [DÜZELTİLDİ]

                AppOutlinedCard(
                  padding: const EdgeInsets.all(AppDimens.p12), // [DÜZELTİLDİ]
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => UniversalAssetPickerSheet(
                        title: state.transactionType == TransactionType.buy ? AppStrings.converter.buyAsset : AppStrings.converter.sellAsset,
                        transactionType: state.transactionType,
                        customAssetList: state.transactionType == TransactionType.sell ? controller.availableQuotes : null,
                        customEmptyMessage: state.transactionType == TransactionType.sell
                            ? AppStrings.messages.emptyPortfolioForSell
                            : null,
                        onSelected: (quote) => controller.selectAsset(quote),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32, height: 32,
                        child: AssetVisualMapper.getAvatar(assetCode: state.selectedAsset!.assetCode, type: state.selectedAsset!.type),
                      ),
                      const SizedBox(width: AppDimens.p12), // [DÜZELTİLDİ]
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.selectedAsset!.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),                            Text(
                                state.transactionType == TransactionType.buy
                                    ? "${AppStrings.form.currentSellRate}: ${state.selectedAsset!.formattedAsk}"
                                    : "${AppStrings.form.currentBuyRate}: ${state.selectedAsset!.formattedBid}",
                                style: AppTextStyles.caption
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.p16), // [DÜZELTİLDİ]

                Flexible(
                  child: SingleChildScrollView(
                    child: AssetFormStep(quote: state.selectedAsset!),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}