import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/states/edit_transaction_controller.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import 'package:yastik_alti/ui/widgets/edit_transaction/edit_transaction_form_step.dart';
import '../../../domain/models/entities/asset.dart';
import '../../states/portfolio_provider.dart';

class EditTransactionSheet extends ConsumerWidget {
  const EditTransactionSheet({super.key});

  static void show(BuildContext context, WidgetRef ref, {required String transactionId}) {
    ref.read(editTransactionControllerProvider.notifier).loadTransaction(transactionId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EditTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editTransactionControllerProvider);
    final portfolio = ref.watch(portfolioProvider);

    // İşlemin ait olduğu varlığın tipini bul (Avatar için)
    final assetType = portfolio.snapshot.positions
        .where((p) => p.asset.id == state.originalTx?.assetId)
        .firstOrNull?.asset.type ?? AssetType.metal;

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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: AppAlphas.borderLight),
                        borderRadius: BorderRadius.circular(AppDimens.radiusXs)
                    )
                ),
                const SizedBox(height: AppDimens.p24),

                // [STATİK BAŞLIK]: İşlem düzenlemede varlık tipi değiştirilemez.
                AppOutlinedCard(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  backgroundColor: state.isAllocated ? AppColors.surface.withValues(alpha: 0.5) : null,
                  child: Row(
                    children: [
                      if (state.originalTx != null) ...[
                        SizedBox(
                          width: 32, height: 32,
                          child: AssetVisualMapper.getAvatar(
                            assetCode: state.originalTx!.assetId,
                            type: assetType,
                          ),
                        ),
                        const SizedBox(width: AppDimens.p12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  state.originalTx!.assetId,
                                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                              ),
                              Text(
                                  state.originalTx!.type == TransactionType.buy
                                      ? AppStrings.labels.buy
                                      : AppStrings.labels.sell,
                                  style: AppTextStyles.caption.copyWith(
                                      color: state.originalTx!.type == TransactionType.buy
                                          ? AppColors.profitAccent
                                          : AppColors.lossAccent
                                  )
                              ),
                            ],
                          ),
                        ),
                        // [GÖRSEL GERİ BİLDİRİM]: Satış yapılmış işlemler için kilit ikonu
                        if (state.isAllocated)
                          const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18)
                        else
                          const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
                      ] else ...[
                        const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.p16),
                const Flexible(
                  child: SingleChildScrollView(
                    child: EditTransactionFormStep(),
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