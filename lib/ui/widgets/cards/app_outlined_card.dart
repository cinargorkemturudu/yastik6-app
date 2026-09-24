import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';

class AppOutlinedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;

  const AppOutlinedCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: AppDimens.p8),
    this.padding = const EdgeInsets.all(AppDimens.p12),
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          highlightColor: AppColors.textPrimary.withValues(alpha: AppAlphas.faint),
          splashColor: AppColors.textPrimary.withValues(alpha: AppAlphas.hover),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        // Centralized Defaults: Brand Blue Fill & Black Contour
        color: backgroundColor ?? AppColors.brandBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: borderColor ?? Colors.black,
          width: 1.0,
        ),
      ),
      child: content,
    );
  }
}