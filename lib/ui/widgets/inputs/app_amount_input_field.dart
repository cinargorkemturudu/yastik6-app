import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [YENİ EKLENDİ]: TextInputFormatter için gerekli
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';

import '../../utils/font_scale.dart';

class AppAmountInputField extends StatelessWidget {
  final String? label;
  final TextEditingController textController;
  final FocusNode? focusNode;
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
    this.focusNode,
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
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textController,
                  builder: (context, value, child) {
                    double currentFontSize = FontScaleUtil.getScaledFontSize(
                      textLength: value.text.length,
                      baseFontSize: activeTextStyle.fontSize ?? 24.0,
                    );

                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      enabled: enabled,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      textAlign: textAlign,

                      // [YENİ EKLENDİ]: Görsel Virgül/Nokta Manipülasyonu
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          // Kullanıcının yazdığı metindeki virgülleri anında noktaya çevirir.
                          // Karakter sayısı değişmediği için imleç (cursor) konumu bozulmaz.
                          return newValue.copyWith(
                            text: newValue.text.replaceAll(',', '.'),
                          );
                        }),
                      ],

                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0',
                        hintStyle:
                        defaultTextStyle.copyWith(color: AppColors.textMuted),
                      ),
                      style: activeTextStyle.copyWith(fontSize: currentFontSize),
                      onChanged: onChanged,
                    );
                  },
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