import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/ui_models/market_item_ui_model.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart';
import '../../utils/app_safe_text.dart';
import 'app_asset_list_tile.dart';

class MarketItemCard extends StatelessWidget {
  final MarketItemUiModel model;
  final VoidCallback onTap;

  const MarketItemCard({
    super.key,
    required this.model,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppAssetListTile(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p4),
      onTap: onTap,
      leading: SizedBox(
        width: 36,
        height: 36,
        child: FittedBox(
          child: AssetVisualMapper.getAvatar(
            assetCode: model.assetCode,
            type: model.type,
          ),
        ),
      ),
      title: AppSafeText(
        model.displayTitle,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
        maxLines: 2,
        flex: false, // ListTile ana başlığı kendi sardığı için kapalı tutuyoruz
      ),
      subtitle: Row(
        children: [
          if (model.displaySubtitle != null) ...[
            // [DÜZELTİLDİ]: Row içinde taşmayı önlemek için AppSafeText (varsayılan flex: true) kullanıldı!
            AppSafeText(
              model.displaySubtitle!,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(width: 6),
            Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Icon(model.trendIcon, color: model.trendColor, size: 14),
          const SizedBox(width: 2),
          Text(
            model.changeRateText,
            style: AppTextStyles.captionBold.copyWith(color: model.trendColor, fontSize: 11),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text("${AppStrings.labels.buy}: ", style: AppTextStyles.caption.copyWith(fontSize: 10)),
              Text(model.formattedBid, style: AppTextStyles.priceLarge.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text("${AppStrings.labels.sell}: ", style: AppTextStyles.caption.copyWith(fontSize: 10)),
              Text(model.formattedAsk, style: AppTextStyles.priceLarge.copyWith(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}