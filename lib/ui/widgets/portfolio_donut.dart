import 'dart:math';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/ui_models/portfolio_donut_model.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import '../../domain/models/entities/asset.dart';
import 'app_clickable_wrapper.dart';

class PortfolioDonut extends StatelessWidget {
  final PortfolioDonutModel? data;
  final Function(TransactionType, AssetType?) onTransaction;
  final VoidCallback onLegendTap;
  final AssetType? currentFilter;

  const PortfolioDonut({
    super.key,
    required this.data,
    required this.onTransaction,
    required this.onLegendTap,
    this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    final currentData = data ?? PortfolioDonutModel(
        totalTl: Decimal.zero, totalPnlTl: Decimal.zero, totalPnlPct: 0,
        totalValueText: "0,00 TL", totalPnlText: "0,00 TL (%0,00)",
        pnlColor: AppColors.textPrimary, items: []
    );
    final bool isEmpty = currentData.totalTl <= Decimal.zero;

    return RepaintBoundary(
      child: SizedBox(
        height: AppDimens.donutSectionHeight,
        child: Row(
          children: [
            SizedBox(
              width: AppDimens.donutSize,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(AppDimens.donutSize),
                      painter: _PortfolioDonutPainter(currentData, isEmpty),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TransactionButton(
                          icon: Icons.remove,
                          color: AppColors.lossAccent,
                          onTap: () => onTransaction(TransactionType.sell, currentFilter),
                        ),
                        const SizedBox(width: AppDimens.p12),
                        _TransactionButton(
                          icon: Icons.add,
                          color: AppColors.profitAccent,
                          onTap: () => onTransaction(TransactionType.buy, currentFilter),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isEmpty || currentData.items.isNotEmpty) ...[
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: _Legend(
                  items: currentData.items,
                  onTap: onLegendTap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<PortfolioDonutItem> items;
  final VoidCallback onTap;

  const _Legend({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sortedItems = List<PortfolioDonutItem>.from(items)
      ..sort((a, b) => b.tlValue.compareTo(a.tlValue));

    // [GÜNCELLENDİ] Ekranda artık 3 yerine 4 öğe gösteriliyor
    final displayItems = sortedItems.take(4).toList();
    final hasMore = sortedItems.length > 4;

    return AppClickableWrapper(
      onTap: onTap,
      borderRadius: AppDimens.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p4, horizontal: AppDimens.p4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...displayItems.map((i) => _buildLegendItem(i)),
            if (hasMore)
              Padding(
                  padding: const EdgeInsets.only(left: AppDimens.p16, top: AppDimens.p2),
                  child: Text("...", style: AppTextStyles.h1.copyWith(height: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(PortfolioDonutItem i) {
    return Padding(
      // [GÜNCELLENDİ] 4 öğenin sığması için dikey boşluklar sıkıştırıldı (bottom overflow önlendi)
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: i.color, shape: BoxShape.circle)
          ),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppFormatter.cleanAssetCode(i.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 12, height: 1.0),
                ),
                const SizedBox(height: 1),
                Text(
                  "${AppFormatter.pnlValue(i.pnlTl)} (${AppFormatter.percent(i.pnlPct)})",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionBold.copyWith(color: i.pnlTl.toPnlColor(), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.p4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${AppFormatter.amount(i.tlValue, "")} TL",
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              if (i.quantity > Decimal.zero)
                Text(
                  "${AppFormatter.amount(i.quantity, "")} adet",
                  style: AppTextStyles.caption.copyWith(fontSize: 9),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TransactionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimens.fabSize,
        height: AppDimens.fabSize,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: AppAlphas.borderActive), width: AppDimens.borderWidth),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Icon(icon, color: color, size: AppDimens.iconLg),
      ),
    );
  }
}

class _PortfolioDonutPainter extends CustomPainter {
  final PortfolioDonutModel data;
  final bool isEmpty;

  _PortfolioDonutPainter(this.data, this.isEmpty);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = AppDimens.donutStroke..strokeCap = StrokeCap.round;

    if (isEmpty) {
      paint.color = AppColors.textPrimary.withValues(alpha: AppAlphas.bgLight);
      canvas.drawCircle(center, radius - 8, paint);
      return;
    }

    final total = data.items.fold<double>(0, (s, x) => s + x.tlValue.toDouble());
    if (total <= 0) {
      paint.color = AppColors.textPrimary.withValues(alpha: AppAlphas.bgLight);
      canvas.drawCircle(center, radius - 8, paint);
      return;
    }

    double start = -pi / 2;
    for (final item in data.items) {
      if (item.tlValue <= Decimal.zero) continue;
      final sweep = (item.tlValue.toDouble() / total) * 2 * pi;
      paint.color = item.color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 8), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PortfolioDonutPainter oldDelegate) => oldDelegate.data != data || oldDelegate.isEmpty != isEmpty;
}