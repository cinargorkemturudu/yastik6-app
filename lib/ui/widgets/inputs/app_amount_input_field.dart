// lib/ui/widgets/inputs/app_amount_input_field.dart

import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';

class AppAmountInputField extends StatelessWidget {
  final String? label;
  final TextEditingController textController;
  final Function(String)? onChanged;
  final String? suffixText;
  final Widget? prefixWidget;
  final Widget? footer;
  final bool enabled;
  final TextAlign textAlign;
  final TextStyle? textStyle;

  const AppAmountInputField({
    super.key,
    this.label,
    required this.textController,
    this.onChanged,
    this.suffixText,
    this.prefixWidget,
    this.footer,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // 1. State Mutation (Styling based on active/locked state)
    final defaultTextStyle = textStyle ??
        AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold);
    final activeTextStyle = defaultTextStyle.copyWith(
      color: enabled ? AppColors.textPrimary : AppColors.textMuted,
    );

    // 2. The Chassis (Structure)
    return AppOutlinedCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12, vertical: AppDimens.p8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) Text(label!, style: AppTextStyles.caption),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // PREFIX MOUNT
              if (prefixWidget != null) ...[
                prefixWidget!,
                const SizedBox(width: AppDimens.p12),
              ],

              // THE CORE ENGINE (TextField)
              Expanded(
                child: TextField(
                  controller: textController,
                  enabled: enabled,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  textAlign: textAlign,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle:
                    defaultTextStyle.copyWith(color: AppColors.textMuted),
                  ),
                  style: activeTextStyle,
                  onChanged: onChanged,
                ),
              ),

              // SUFFIX MOUNT
              if (suffixText != null) ...[
                const SizedBox(width: AppDimens.p8),
                Text(
                  suffixText!,
                  style: AppTextStyles.captionBold.copyWith(
                    color:
                    enabled ? AppColors.textSecondary : AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),

          // FOOTER MOUNT
          if (footer != null) ...[
            const SizedBox(height: AppDimens.p12),
            footer!,
          ]
        ],
      ),
    );
  }
}