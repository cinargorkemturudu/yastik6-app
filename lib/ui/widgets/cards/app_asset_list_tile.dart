import 'package:flutter/material.dart';
import 'app_outlined_card.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart'; // [EKLENDİ]

class AppAssetListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const AppAssetListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: AppDimens.p8), // [DÜZELTİLDİ]
  });

  @override
  Widget build(BuildContext context) {
    return AppOutlinedCard(
      margin: margin,
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimens.p12), // [DÜZELTİLDİ]
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: AppDimens.p12), // [DÜZELTİLDİ]
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                title,
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  subtitle!,
                ]
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppDimens.p8), // [DÜZELTİLDİ]
            trailing!,
          ]
        ],
      ),
    );
  }
}