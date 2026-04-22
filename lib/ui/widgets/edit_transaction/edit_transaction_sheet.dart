// lib/ui/widgets/edit_transaction/edit_transaction_sheet.dart

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

/// A secure BottomSheet wrapper for the transaction editing module.
class EditTransactionSheet extends ConsumerWidget {
  const EditTransactionSheet({super.key});

  /// Triggers the edit flow by initializing the controller and displaying the BottomSheet.
  static void show(BuildContext context, WidgetRef ref, {required String transactionId}) {
    // 1. Ignite the Engine: Start fetching data securely before the sheet fully animates up.
    ref.read(editTransactionControllerProvider.notifier).loadTransaction(transactionId);

    // 2. Open the Sheet.
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
    final assetType = portfolio.snapshot.positions
        .where((p) => p.asset.id == state.originalTx?.assetId)
        .firstOrNull?.asset.type ?? AssetType.metal;

    return GestureDetector(
      // Dismiss the keyboard when tapping outside the form fields.
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
                // Drag Handle
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: AppAlphas.borderLight),
                        borderRadius: BorderRadius.circular(AppDimens.radiusXs)
                    )
                ),
                const SizedBox(height: AppDimens.p24),

                // THE STATIC HEADER
                // This replaces the interactive AssetPicker from the Add flow, 
                // as users cannot mutate the asset type of an existing transaction.
                AppOutlinedCard(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  child: Row(
                    children: [
                      if (state.originalTx != null) ...[
                        SizedBox(
                          width: 32, height: 32,
                          child: AssetVisualMapper.getAvatar(
                            assetCode: state.originalTx!.assetId,
                            type: assetType, // THE FIX: Parameter added
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
                        // Visual indicator that the asset type itself is permanently locked
                        const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
                      ] else ...[
                        const SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.p16),

                // THE SECURE FORM
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