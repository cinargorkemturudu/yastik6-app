import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/states/converter_view_model.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import 'package:yastik_alti/ui/widgets/converter/market_mode_toggle.dart';
import 'package:yastik_alti/ui/widgets/converter/opportunity_cost_card.dart';
import 'package:yastik_alti/ui/widgets/inputs/app_amount_input_field.dart';
import 'package:yastik_alti/ui/widgets/universal_asset_picker_sheet.dart';

import '../states/live_price_provider.dart';
import '../utils/app_safe_text.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  late final TextEditingController _sellAmountCtrl;
  late final TextEditingController _buyAmountCtrl;
  final FocusNode _sellFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    final state = ref.read(converterViewModelProvider);
    final initialAmount = state.amount;
    final initialResult = ref.read(converterResultProvider);

    final sellPrecision = state.fromAsset?.type == AssetType.crypto ? 4 : 2;
    final buyPrecision = state.toAsset?.type == AssetType.crypto ? 4 : 2;

    _sellAmountCtrl = TextEditingController(
      text: initialAmount > Decimal.zero
          ? AppFormatter.amount(initialAmount, "", precision: sellPrecision)
          : '',
    );

    _buyAmountCtrl = TextEditingController(
      text: initialResult > Decimal.zero
          ? AppFormatter.amount(initialResult, "", precision: buyPrecision)
          : '',
    );
  }

  @override
  void dispose() {
    _sellAmountCtrl.dispose();
    _buyAmountCtrl.dispose();
    _sellFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(converterViewModelProvider);
    final viewModel = ref.read(converterViewModelProvider.notifier);
    final result = ref.watch(converterResultProvider);

    ref.listen<Decimal>(converterResultProvider, (previous, next) {
      if (previous != next) {
        final buyPrecision = state.toAsset?.type == AssetType.crypto ? 4 : 2;
        _buyAmountCtrl.text = next > Decimal.zero
            ? AppFormatter.amount(next, "", precision: buyPrecision)
            : '';
      }
    });

    ref.listen(converterViewModelProvider, (prev, next) {
      if (prev?.amount != next.amount) {
        final currentTextValue = AppFormatter.parseInput(_sellAmountCtrl.text);

        if (currentTextValue != next.amount && !_sellFocusNode.hasFocus) {
          final sellPrecision = next.fromAsset?.type == AssetType.crypto
              ? 4
              : 2;
          final newString = next.amount > Decimal.zero
              ? AppFormatter.amount(next.amount, "", precision: sellPrecision)
              : '';
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p8,
          ),
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
                context,
                ref,
                title: AppStrings.converter.sellAsset,
                quote: state.fromAsset,
                isInput: true,
                controller: _sellAmountCtrl,
                focusNode: _sellFocusNode,
                onAmountChanged: (val) =>
                    viewModel.updateAmount(AppFormatter.parseInput(val)),
                onAssetSelected: viewModel.updateFromAsset,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.swap_vert,
                      color: AppColors.brandBlue,
                      size: 32,
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      viewModel.swapAssets();
                    },
                  ),
                ),
              ),
              _buildAssetCard(
                context,
                ref,
                title: AppStrings.converter.buyAsset,
                quote: state.toAsset,
                isInput: false,
                controller: _buyAmountCtrl,
                onAssetSelected: viewModel.updateToAsset,
              ),
              const SizedBox(height: AppDimens.p24),
              if (state.fromAsset != null && state.toAsset != null)
                OpportunityCostCard(
                  amount: state.amount,
                  fromAsset: state.fromAsset!,
                  toAsset: state.toAsset!,
                  currentResult: result,
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

  Widget _buildAssetCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required PriceQuote? quote,
    required bool isInput,
    required TextEditingController controller,
    FocusNode? focusNode,
    Function(String)? onAmountChanged,
    required Function(PriceQuote) onAssetSelected,
  }) {
    String displayTitle = AppStrings.common.select;
    String? displaySubtitle;

    if (quote != null) {
      final String cleanCode = AppFormatter.cleanAssetCode(quote.assetCode);
      final String cleanName = AppFormatter.cleanAssetName(quote.name);
      final String displayName = AssetVisualMapper.getName(
        cleanCode,
        cleanName,
      );

      switch (quote.type) {
        case AssetType.currency:
        case AssetType.stock:
          displayTitle = displayName;
          displaySubtitle = cleanCode;
          break;

        case AssetType.metal:
          displayTitle = displayName;
          displaySubtitle = null;
          break;

        default:
          displayTitle = cleanCode;
          displaySubtitle = displayName;
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: AppAlphas.tint),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      child: AppAmountInputField(
        label: title,
        textController: controller,
        enabled: isInput,
        focusNode: focusNode,
        textAlign: TextAlign.right,
        textStyle: AppTextStyles.heroAmount.copyWith(
          fontSize: 24,
          color: isInput ? AppColors.textPrimary : AppColors.brandBlue,
        ),
        onChanged: onAmountChanged,
        prefixWidget: GestureDetector(
          onTap: () => _showAssetPicker(context, ref, onAssetSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p12,
              vertical: AppDimens.p8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quote != null) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: AssetVisualMapper.getAvatar(
                      assetCode: quote.assetCode,
                      type: quote.type,
                    ),
                  ),
                  const SizedBox(width: AppDimens.p8),
                ],
                AppSafeText(
                  displayTitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppDimens.p4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        footer: quote != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSafeText(
                    displaySubtitle ?? "",
                    style: AppTextStyles.caption.copyWith(height: 1.2),
                    maxLines: 2,
                  ),
                  const SizedBox(width: AppDimens.p12),
                  Text(
                    "${isInput ? 'Alış' : 'Satış'}: ${AppFormatter.amount(isInput ? quote.bid : quote.ask, "", precision: quote.type == AssetType.crypto ? 4 : 2)} TL",
                    style: AppTextStyles.caption,
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _showAssetPicker(
    BuildContext context,
    WidgetRef ref,
    Function(PriceQuote) onSelected,
  ) {
    final marketState = ref.read(livePriceProvider).valueOrNull;
    final marketAssets = marketState?.marketAssets ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalAssetPickerSheet(
        onSelected: onSelected,
        customAssetList: marketAssets,
      ),
    );
  }
}
