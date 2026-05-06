import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/states/edit_transaction_controller.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/widgets/inputs/app_amount_input_field.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:collection/collection.dart';
import '../../../domain/models/entities/asset.dart';

class EditTransactionFormStep extends ConsumerStatefulWidget {
  const EditTransactionFormStep({super.key});

  @override
  ConsumerState<EditTransactionFormStep> createState() => _EditTransactionFormStepState();
}

class _EditTransactionFormStepState extends ConsumerState<EditTransactionFormStep> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();

    final state = ref.read(editTransactionControllerProvider);
    final portfolio = ref.read(portfolioProvider);

    // [HASSASİYET]: Varlık tipini bulup hassasiyeti belirliyoruz (Kripto ise 4 hane)
    final assetType = portfolio.snapshot.positions
        .firstWhereOrNull((p) => p.asset.id == state.originalTx?.assetId)
        ?.asset.type ?? AssetType.metal;
    final precision = assetType == AssetType.crypto ? 4 : 2;

    _amountCtrl = TextEditingController(
        text: state.amount > Decimal.zero ? AppFormatter.amount(state.amount, "", precision: precision) : ''
    );
    _priceCtrl = TextEditingController(
        text: state.price > Decimal.zero ? AppFormatter.amount(state.price, "", precision: precision) : ''
    );
    _noteCtrl = TextEditingController(text: state.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editTransactionControllerProvider);
    final controller = ref.read(editTransactionControllerProvider.notifier);
    final portfolio = ref.watch(portfolioProvider);

    final assetType = portfolio.snapshot.positions
        .firstWhereOrNull((p) => p.asset.id == state.originalTx?.assetId)
        ?.asset.type ?? AssetType.metal;
    final precision = assetType == AssetType.crypto ? 4 : 2;

    // [KRİTİK DÜZELTME]: Tarih değiştiğinde Controller'dan gelen yeni fiyatı TextField'a basar
    ref.listen(editTransactionControllerProvider, (prev, next) {
      if (prev?.price != next.price && !next.isAllocated) {
        _priceCtrl.text = next.price > Decimal.zero
            ? AppFormatter.amount(next.price, "", precision: precision)
            : '';
      }
    });

    if (state.isLoading || state.originalTx == null) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.p24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isBuy = state.originalTx!.type == TransactionType.buy;
    final isFormValid = state.amount > Decimal.zero && state.price > Decimal.zero;

    // FIFO Zaman Bariyeri Hesabı
    final barrierDates = portfolio.transactions
        .where((t) => t.assetId == state.originalTx!.assetId && t.id != state.originalTx!.id)
        .where((t) => t.type == TransactionType.sell || t.purchaseDate.isBefore(state.originalTx!.purchaseDate))
        .map((t) => t.purchaseDate).toList();
    DateTime firstDate = barrierDates.isEmpty ? DateTime(2000) : barrierDates.reduce((a, b) => a.isAfter(b) ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isAllocated) ...[
          Container(
            padding: const EdgeInsets.all(AppDimens.p12),
            decoration: BoxDecoration(
              color: AppColors.lossAccent.withValues(alpha: AppAlphas.faint),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.lossAccent.withValues(alpha: AppAlphas.borderLight)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.lossAccent, size: 20),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: Text(
                    AppStrings.messages.editLockedWarning,
                    style: AppTextStyles.caption.copyWith(color: AppColors.lossAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.p16),
        ],
        Row(
          children: [
            Expanded(
              child: AppAmountInputField(
                label: AppStrings.form.amount,
                textController: _amountCtrl,
                suffixText: state.originalTx!.assetId,
                enabled: !state.isAllocated,
                onChanged: controller.updateAmount,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: AppAmountInputField(
                label: isBuy ? AppStrings.form.buyPrice : AppStrings.form.sellPrice,
                textController: _priceCtrl,
                suffixText: 'TL',
                enabled: !state.isAllocated,
                onChanged: controller.updatePrice,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p12),
        AppOutlinedCard(
          onTap: state.isAllocated ? null : () async {
            FocusScope.of(context).unfocus();
            final picked = await showDatePicker(
              context: context,
              initialDate: state.date.isBefore(firstDate) ? firstDate : state.date,
              firstDate: firstDate,
              lastDate: DateTime.now(),
            );
            if (picked != null) controller.updateDate(picked);
          },
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: 14),
          child: Row(
            children: [
              Icon(
                  Icons.calendar_today,
                  color: state.isAllocated ? AppColors.textMuted : AppColors.brandBlue,
                  size: 20
              ),
              const SizedBox(width: AppDimens.p12),
              Text(AppStrings.form.date, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                  DateFormat('dd.MM.yyyy').format(state.date),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: state.isAllocated ? AppColors.textMuted : AppColors.textPrimary,
                  )
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        AppOutlinedCard(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p4),
          child: TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: AppStrings.form.noteOptional,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              icon: const Icon(Icons.edit_note, color: AppColors.textPrimary, size: 20),
            ),
            onChanged: controller.updateNote,
            style: AppTextStyles.bodyMedium,
          ),
        ),
        const SizedBox(height: AppDimens.p24),
        ElevatedButton(
          onPressed: isFormValid && !state.isLoading
              ? () async {
            FocusScope.of(context).unfocus();
            final success = await controller.saveTransaction();
            if (success && context.mounted) {
              Navigator.pop(context);
            } else if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? AppStrings.messages.transactionFailed),
                backgroundColor: AppColors.lossAccent,
              ));
            }
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            disabledBackgroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: AppDimens.p16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
            elevation: 0,
          ),
          child: Text(
            AppStrings.common.update.toUpperCase(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: isFormValid ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}