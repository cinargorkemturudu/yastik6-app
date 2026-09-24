import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/states/add_asset_controller.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/widgets/inputs/app_amount_input_field.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';

import '../../../domain/models/entities/asset.dart';

class AssetFormStep extends ConsumerStatefulWidget {
  final PriceQuote quote;
  const AssetFormStep({super.key, required this.quote});

  @override
  ConsumerState<AssetFormStep> createState() => _AssetFormStepState();
}

class _AssetFormStepState extends ConsumerState<AssetFormStep> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(addAssetControllerProvider);
    final precision = widget.quote.type == AssetType.crypto ? 4 : 2;

    _amountCtrl = TextEditingController(
        text: state.amount > Decimal.zero
            ? AppFormatter.amount(state.amount, "", precision: precision)
            : ''
    );
    _priceCtrl = TextEditingController(
        text: state.price > Decimal.zero
            ? AppFormatter.amount(state.price, "", precision: precision)
            : ''
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addAssetControllerProvider);
    final controller = ref.read(addAssetControllerProvider.notifier);
    final portfolio = ref.watch(portfolioProvider);

    ref.listen(addAssetControllerProvider, (prev, next) {
      if (prev?.price != next.price) {
        final precision = widget.quote.type == AssetType.crypto ? 4 : 2;
        _priceCtrl.text = next.price > Decimal.zero
            ? AppFormatter.amount(next.price, "", precision: precision)
            : '';
      }
    });

    final assetTxs = portfolio.transactions.where((t) => t.assetId == widget.quote.assetCode).toList();
    DateTime lastBarrierDate = DateTime(2000);
    if (assetTxs.isNotEmpty) {
      lastBarrierDate = assetTxs.map((t) => t.purchaseDate).reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final isBuy = state.transactionType == TransactionType.buy;
    final isFormValid = state.amount > Decimal.zero && state.price > Decimal.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppAmountInputField(
                label: AppStrings.form.amount,
                textController: _amountCtrl,
                suffixText: widget.quote.assetCode,
                onChanged: controller.updateAmount,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: AppAmountInputField(
                label: isBuy ? AppStrings.form.buyPrice : AppStrings.form.sellPrice,
                textController: _priceCtrl,
                suffixText: 'TL',
                onChanged: controller.updatePrice,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p12),
        AppOutlinedCard(
          onTap: () async {
            FocusScope.of(context).unfocus();
            final picked = await showDatePicker(
              context: context,
              initialDate: state.date.isBefore(lastBarrierDate) ? lastBarrierDate : state.date,
              firstDate: lastBarrierDate,
              lastDate: DateTime.now(),
            );
            if (picked != null) controller.updateDate(picked);
          },
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.brandBlue, size: 20),
              const SizedBox(width: AppDimens.p12),
              Text(AppStrings.form.date, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text(DateFormat('dd.MM.yyyy').format(state.date), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        AppOutlinedCard(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p4),
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: AppStrings.form.noteOptional,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              icon: const Icon(Icons.edit_note, color: AppColors.textMuted, size: 20),
            ),
            onChanged: controller.updateNote,
            style: AppTextStyles.bodyMedium,
          ),
        ),
        const SizedBox(height: AppDimens.p24),
        ElevatedButton(
          onPressed: isFormValid
              ? () async {
            FocusScope.of(context).unfocus();
            final success = await controller.saveTransaction();
            if (success && context.mounted) {
              Navigator.pop(context);
            } else if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage ?? AppStrings.messages.transactionFailed)));
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
            AppStrings.common.save.toUpperCase(),
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