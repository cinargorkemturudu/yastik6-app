import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/states/add_asset_controller.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/widgets/universal_asset_picker_sheet.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import '../../../domain/models/entities/asset.dart';
import '../../theme/app_strings.dart';
import '../../utils/app_formatter.dart';
import 'asset_form_step.dart';

class AddAssetSheet extends ConsumerWidget {
  final bool isFromDonut;
  final AssetType? initialAssetType;

  const AddAssetSheet({
    super.key,
    this.isFromDonut = false,
    this.initialAssetType,
  });

  static void showFlow(
      BuildContext context,
      WidgetRef ref,
      {
        TransactionType type = TransactionType.buy,
        bool isFromDonut = false,
        AssetType? initialAssetType,
      }) {
    final controller = ref.read(addAssetControllerProvider.notifier);
    controller.updateTransactionType(type);
    controller.selectAsset(null);

    // Listeyi filtrelemiyoruz, orijinal haliyle bırakıyoruz
    List<PriceQuote>? computedAssetList;

    if (type == TransactionType.sell) {
      computedAssetList = controller.availableQuotes;
    } else if (type == TransactionType.buy && isFromDonut) {
      final marketState = ref.read(livePriceProvider).valueOrNull;
      if (marketState != null) {
        computedAssetList = marketState.marketAssets.where((q) => q.assetCode != 'TRY').toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalAssetPickerSheet(
        title: type == TransactionType.buy ? AppStrings.converter.buyAsset : AppStrings.converter.sellAsset,
        transactionType: type,
        customAssetList: computedAssetList,
        initialAssetType: initialAssetType, // [EKLENDİ]: Picker'a ilk açılış sekmesini fısıldıyoruz
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
                builder: (ctx) => AddAssetSheet(
                  isFromDonut: isFromDonut,
                  initialAssetType: initialAssetType, // [EKLENDİ]: Seçim yapıldıktan sonra içerideki forma da tüyoyu aktarıyoruz
                ),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: AppAlphas.borderLight), borderRadius: BorderRadius.circular(AppDimens.radiusXs))
                ),
                const SizedBox(height: AppDimens.p24),

                AppOutlinedCard(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  onTap: () {
                    FocusScope.of(context).unfocus();

                    List<PriceQuote>? computedAssetList;
                    if (state.transactionType == TransactionType.sell) {
                      computedAssetList = controller.availableQuotes;
                    } else if (state.transactionType == TransactionType.buy && isFromDonut) {
                      final marketState = ref.read(livePriceProvider).valueOrNull;
                      if (marketState != null) {
                        computedAssetList = marketState.marketAssets.where((q) => q.assetCode != 'TRY').toList();
                      }
                    }

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => UniversalAssetPickerSheet(
                        title: state.transactionType == TransactionType.buy ? AppStrings.converter.buyAsset : AppStrings.converter.sellAsset,
                        transactionType: state.transactionType,
                        customAssetList: computedAssetList,
                        initialAssetType: initialAssetType, // [EKLENDİ]: "Varlığı Değiştir" dendiğinde de doğru sekmeden açılsın
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
                      const SizedBox(width: AppDimens.p12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.selectedAsset!.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                                state.transactionType == TransactionType.buy
                                    ? "${AppStrings.form.currentSellRate}: ${AppFormatter.amount(state.selectedAsset!.ask, "", precision: state.selectedAsset!.type == AssetType.crypto ? 4 : 2)} TL"
                                    : "${AppStrings.form.currentBuyRate}: ${AppFormatter.amount(state.selectedAsset!.bid, "", precision: state.selectedAsset!.type == AssetType.crypto ? 4 : 2)} TL",
                                style: AppTextStyles.caption
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.p16),

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