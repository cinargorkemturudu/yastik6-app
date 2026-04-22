import 'dart:math';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/ui_models/portfolio_donut_model.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'app_clickable_wrapper.dart';

class PortfolioDonut extends StatelessWidget {
  final PortfolioDonutModel? data;
  final Function(TransactionType) onTransaction;
  final VoidCallback onLegendTap;

  const PortfolioDonut({
    super.key,
    required this.data,
    required this.onTransaction,
    required this.onLegendTap,
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
            Expanded(
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
                          onTap: () => onTransaction(TransactionType.sell),
                        ),
                        const SizedBox(width: AppDimens.p12),
                        _TransactionButton(
                          icon: Icons.add,
                          color: AppColors.profitAccent,
                          onTap: () => onTransaction(TransactionType.buy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isEmpty || currentData.items.isNotEmpty) ...[
              const SizedBox(width: AppDimens.p12),
              SizedBox(
                width: AppDimens.donutSize,
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

    final displayItems = sortedItems.take(3).toList();
    final hasMore = sortedItems.length > 3;

    return AppClickableWrapper(
      onTap: onTap,
      borderRadius: AppDimens.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p8, horizontal: AppDimens.p8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...displayItems.map((i) => _buildLegendItem(i)),
            if (hasMore)
              const Padding(
                  padding: EdgeInsets.only(left: AppDimens.p16, top: AppDimens.p4),
                  child: Text("...", style: TextStyle(color: AppColors.textMuted, fontSize: 20, fontWeight: FontWeight.bold, height: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(PortfolioDonutItem i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p6),
      child: Row(
        children: [
          Container(width: AppDimens.legendCircle, height: AppDimens.legendCircle, decoration: BoxDecoration(color: i.color, shape: BoxShape.circle)),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                // [FIXED] AppFormatter.pnlValue expects double here
                Text("${AppFormatter.pnlValue(i.pnlTl.toDouble())} (${AppFormatter.percent(i.pnlPct)})", style: TextStyle(color: i.pnlTl.toDouble().toPnlColor(), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.p6),
          Text(i.tlValue.toDouble().toStringAsFixed(0), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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