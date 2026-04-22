import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/states/converter_view_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/converter/market_mode_toggle.dart';
import 'package:yastik_alti/ui/widgets/converter/opportunity_cost_card.dart';
import 'package:yastik_alti/ui/widgets/inputs/app_amount_input_field.dart';
import 'package:yastik_alti/ui/widgets/universal_asset_picker_sheet.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  late final TextEditingController _sellAmountCtrl;
  late final TextEditingController _buyAmountCtrl;

  @override
  void initState() {
    super.initState();
    final initialAmount = ref.read(converterViewModelProvider).amount;
    _sellAmountCtrl = TextEditingController(text: initialAmount > Decimal.zero ? initialAmount.toString() : '');
    _buyAmountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _sellAmountCtrl.dispose();
    _buyAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(converterViewModelProvider);
    final viewModel = ref.read(converterViewModelProvider.notifier);
    final result = ref.watch(converterResultProvider);

    ref.listen<Decimal>(converterResultProvider, (previous, next) {
      if (previous != next) {
        _buyAmountCtrl.text = next.toDouble().toStringAsFixed(4);
      }
    });

    ref.listen(converterViewModelProvider, (prev, next) {
      if (prev?.amount != next.amount) {
        final currentTextValue = Decimal.tryParse(_sellAmountCtrl.text.replaceAll(',', '.')) ?? Decimal.zero;

        if (currentTextValue != next.amount) {
          final newString = next.amount > Decimal.zero ? next.amount.toString() : '';
          _sellAmountCtrl.value = TextEditingValue(
            text: newString,
            selection: TextSelection.collapsed(offset: newString.length),
          );
        }
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(AppStrings.navigation.converter, style: AppTextStyles.h2),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MarketModeToggle(
                currentMode: state.mode,
                onModeChanged: viewModel.toggleMode,
                fromAsset: state.fromAsset,
                toAsset: state.toAsset,
              ),
              const SizedBox(height: AppDimens.p24),

              _buildAssetCard(
                context, ref,
                title: AppStrings.converter.sellAsset,
                quote: state.fromAsset,
                isInput: true,
                controller: _sellAmountCtrl,
                onAmountChanged: (val) => viewModel.updateAmount(Decimal.tryParse(val.replaceAll(',', '.')) ?? Decimal.zero),
                onAssetSelected: viewModel.updateFromAsset,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.swap_vert, color: AppColors.brandBlue, size: 32),
                    onPressed: viewModel.swapAssets,
                  ),
                ),
              ),

              _buildAssetCard(
                context, ref,
                title: AppStrings.converter.buyAsset,
                quote: state.toAsset,
                isInput: false,
                controller: _buyAmountCtrl,
                onAssetSelected: viewModel.updateToAsset,
              ),
              const SizedBox(height: AppDimens.p24),

              if (state.fromAsset != null && state.toAsset != null)
                OpportunityCostCard(
                  amount: state.amount.toDouble(),
                  fromAsset: state.fromAsset!,
                  toAsset: state.toAsset!,
                  currentResult: result.toDouble(),
                  selectedDate: state.historicalDate,
                  onDateSelected: viewModel.updateHistoricalDate,
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, WidgetRef ref, {
    required String title,
    required PriceQuote? quote,
    required bool isInput,
    required TextEditingController controller,
    Function(String)? onAmountChanged,
    required Function(PriceQuote) onAssetSelected,
  }) {
    return AppAmountInputField(
      label: title,
      textController: controller,
      enabled: isInput,
      textAlign: TextAlign.right,
      textStyle: AppTextStyles.heroAmount.copyWith(
          fontSize: 24,
          color: isInput ? AppColors.textPrimary : AppColors.brandBlue
      ),
      onChanged: onAmountChanged,
      prefixWidget: GestureDetector(
        onTap: () => _showAssetPicker(context, ref, onAssetSelected),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p12, vertical: AppDimens.p8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Row(
            children: [
              if (quote != null) ...[
                SizedBox(
                  width: 20, height: 20,
                  child: AssetVisualMapper.getAvatar(assetCode: quote.assetCode, type: quote.type),
                ),
                const SizedBox(width: AppDimens.p8),
              ],
              Text(quote?.assetCode ?? AppStrings.common.select, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: AppDimens.p4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
      footer: quote != null
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(quote.name, style: AppTextStyles.caption),
          Text("${AppStrings.labels.buy}: ${quote.formattedBid} / ${AppStrings.labels.sell}: ${quote.formattedAsk}", style: AppTextStyles.caption),
        ],
      )
          : null,
    );
  }

  void _showAssetPicker(BuildContext context, WidgetRef ref, Function(PriceQuote) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalAssetPickerSheet(onSelected: onSelected),
    );
  }
}