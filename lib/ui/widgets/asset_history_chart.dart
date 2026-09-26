import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/ui/ui_models/owned_asset_list_item_model.dart';
import 'package:yastik_alti/ui/widgets/app_clickable_wrapper.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/widgets/cards/app_outlined_card.dart';
import 'package:yastik_alti/ui/states/asset_history_provider.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/ui/utils/chart_data_smoother.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';

class AssetAccordionItem extends ConsumerStatefulWidget {
  final OwnedAssetListItemModel model;

  const AssetAccordionItem({super.key, required this.model});

  @override
  ConsumerState<AssetAccordionItem> createState() => _AssetAccordionItemState();
}

class _AssetAccordionItemState extends ConsumerState<AssetAccordionItem> {
  bool _isExpanded = false;
  PricePoint? _hoveredPoint;

  String _selectedRange = '1M';

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  String _getRangeParam(String uiRange) {
    switch (uiRange) {
      case '1D':
        return 'Day';
      case '1W':
        return 'Week';
      case '1M':
        return 'Month';
      case '3M':
        return 'ThreeMonths';
      case '1Y':
        return 'Year';
      default:
        return 'Month';
    }
  }

  Widget _buildRangeChip(String label, String rangeValue) {
    final isSelected = _selectedRange == rangeValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.brandBlue.withValues(alpha: AppAlphas.bgMedium),
      backgroundColor: AppColors.surface,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p4,
        vertical: 0,
      ),
      labelStyle: AppTextStyles.captionBold.copyWith(
        color: isSelected ? AppColors.brandBlue : AppColors.textMuted,
      ),
      onSelected: (_) => setState(() => _selectedRange = rangeValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfit = widget.model.pnlColor != AppColors.lossAccent;
    final Color dailyColor = widget.model.pnlColor;
    final IconData dailyIcon = isProfit
        ? Icons.arrow_upward
        : Icons.arrow_downward;
    final String dailyChangeText = widget.model.pnlPercent;

    return AppOutlinedCard(
      padding: EdgeInsets.zero,
      // Explicitly coloring just these cards brand blue
      backgroundColor: AppColors.brandBlue.withValues(alpha: AppAlphas.tint),
      child: Column(
        children: [
          // --- HEADER: 3 SÜTUNLU KONSOLİDE YAPI ---
          AppClickableWrapper(
            onTap: _toggle,
            borderRadius: AppDimens.radiusMd,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.model.displayTitle,
                              style: AppTextStyles.h2.copyWith(
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDimens.p2),
                            if (widget.model.displaySubtitle != null)
                              Text(
                                widget.model.displaySubtitle!,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimens.p12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.model.currentPriceText,
                            style: AppTextStyles.priceLarge.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.p6,
                              vertical: AppDimens.p2,
                            ),
                            decoration: BoxDecoration(
                              color: dailyColor.withValues(
                                alpha: AppAlphas.bgLight,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusXs,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  dailyIcon,
                                  color: dailyColor,
                                  size: AppDimens.iconXs,
                                ),
                                const SizedBox(width: AppDimens.p2),
                                Text(
                                  dailyChangeText,
                                  style: AppTextStyles.captionBold.copyWith(
                                    color: dailyColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.p12),
                  Divider(
                    color: AppColors.textPrimary.withValues(
                      alpha: AppAlphas.faint,
                    ),
                    height: AppDimens.dividerHeight,
                  ),
                  const SizedBox(height: AppDimens.p12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLabeledStat(
                          AppStrings.form.amount,
                          widget.model.amountText,
                          AppColors.textPrimary,
                          subText: widget.model.totalValueText,
                          alignment: CrossAxisAlignment.start,
                        ),
                      ),
                      Expanded(
                        child: _buildLabeledStat(
                          AppStrings.labels.avgCost,
                          widget.model.avgCostText,
                          AppColors.textPrimary,
                          alignment: CrossAxisAlignment.center,
                        ),
                      ),
                      Expanded(
                        child: _buildLabeledStat(
                          AppStrings.labels.totalPnl,
                          widget.model.pnlValueText,
                          widget.model.pnlColor,
                          subText: widget.model.pnlPercent,
                          alignment: CrossAxisAlignment.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- EXPANDED BODY: CANLI GRAFİK ---
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.p12,
                0,
                AppDimens.p12,
                AppDimens.p16,
              ),
              child: Column(
                children: [
                  Divider(
                    color: AppColors.textPrimary.withValues(
                      alpha: AppAlphas.faint,
                    ),
                    height: AppDimens.dividerHeight,
                  ),
                  const SizedBox(height: AppDimens.p12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRangeChip('1G', '1D'),
                        const SizedBox(width: AppDimens.p8),
                        _buildRangeChip('1H', '1W'),
                        const SizedBox(width: AppDimens.p8),
                        _buildRangeChip('1A', '1M'),
                        const SizedBox(width: AppDimens.p8),
                        _buildRangeChip('3A', '3M'),
                        const SizedBox(width: AppDimens.p8),
                        _buildRangeChip('1Y', '1Y'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.p16),

                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final params = AssetHistoryParams(
                          assetCode: widget.model.assetId,
                          range: _getRangeParam(_selectedRange),
                        );
                        final historyAsync = ref.watch(
                          assetHistoryProvider(params),
                        );
                        final portfolioData = ref.watch(portfolioProvider);

                        return historyAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brandBlue,
                            ),
                          ),
                          error: (e, s) => Center(
                            child: Text(
                              AppStrings.messages.chartLoadFailed,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.loss,
                              ),
                            ),
                          ),
                          data: (data) {
                            final assetTxs = portfolioData.transactions
                                .where(
                                  (tx) => tx.assetId == widget.model.assetId,
                                )
                                .toList();

                            final chartTxs = assetTxs
                                .map(
                                  (tx) => ChartTransactionPoint(
                                    date: tx.purchaseDate,
                                    isBuy: tx.type == TransactionType.buy,
                                    amount: tx.amount,
                                    price: tx.purchasePrice,
                                  ),
                                )
                                .toList();

                            return AssetHistoryChart(
                              data: data,
                              transactions: chartTxs,
                              color: AppColors.getAssetColor(
                                widget.model.assetId,
                              ),
                              selectedRange: _selectedRange,
                              avgCost: widget.model.averageBuyPrice,
                              onScrub: (point) {
                                if (_hoveredPoint?.timestamp !=
                                    point?.timestamp) {
                                  Future.microtask(() {
                                    if (mounted)
                                      setState(() => _hoveredPoint = point);
                                  });
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabeledStat(
    String label,
    String value,
    Color valueColor, {
    String? subText,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.captionBold.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimens.p4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (subText != null) ...[
          const SizedBox(height: AppDimens.p2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subText,
              style: AppTextStyles.caption.copyWith(
                color: valueColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ChartTransactionPoint {
  final DateTime date;
  final bool isBuy;
  final Decimal amount;
  final Decimal price;
  final Decimal? realizedProfit;

  ChartTransactionPoint({
    required this.date,
    required this.isBuy,
    required this.amount,
    required this.price,
    this.realizedProfit,
  });
}

class AssetHistoryChart extends StatelessWidget {
  final List<PricePoint> data;
  final List<ChartTransactionPoint> transactions;
  final Decimal? avgCost;
  final Color color;
  final String selectedRange;
  final Function(PricePoint?) onScrub;

  const AssetHistoryChart({
    super.key,
    required this.data,
    this.transactions = const [],
    this.avgCost,
    required this.color,
    required this.selectedRange,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          AppStrings.messages.emptyData,
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    final rawSortedData = List<PricePoint>.from(data)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final smoothData = ChartDataSmoother.processAndSmooth(
      rawSortedData,
      period: 3,
    );

    if (smoothData.length < 2) {
      return Center(
        child: Text(
          AppStrings.messages.noDataForRange,
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    double minPrice = smoothData.first.price;
    double maxPrice = smoothData.first.price;
    for (var p in smoothData) {
      if (p.price < minPrice) minPrice = p.price;
      if (p.price > maxPrice) maxPrice = p.price;
    }

    final priceRange = maxPrice - minPrice == 0 ? 1.0 : maxPrice - minPrice;
    final minY = minPrice - (priceRange * 0.15);
    final maxY = maxPrice + (priceRange * 0.15);

    final startTime = smoothData.first.date.millisecondsSinceEpoch.toDouble();
    final endTime = smoothData.last.date.millisecondsSinceEpoch.toDouble();

    if (startTime == endTime) {
      return Center(
        child: Text(
          AppStrings.messages.noDataForRange,
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    final visibleTxs = transactions.where((t) {
      final ms = t.date.millisecondsSinceEpoch.toDouble();
      return ms >= startTime && ms <= endTime;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final spots = smoothData
        .map((p) => FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.price))
        .toList();

    return LineChart(
      LineChartData(
        minX: startTime,
        maxX: endTime,
        minY: minY,
        maxY: maxY,
        backgroundColor: Colors.transparent,

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: priceRange / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: AppAlphas.faint),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (endTime - startTime) / 4,
              getTitlesWidget: (value, meta) {
                if (value == startTime || value == endTime)
                  return const SizedBox();

                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final format = (selectedRange == 'Day')
                    ? DateFormat('HH:mm')
                    : DateFormat('dd MMM');

                return Padding(
                  padding: const EdgeInsets.only(top: AppDimens.p8),
                  child: Text(
                    format.format(date),
                    style: AppTextStyles.caption,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60, // [FIXED]: Genişletildi
              interval: priceRange / 4,
              getTitlesWidget: (value, meta) {
                // [FIXED]: Sınır değerleri saklanarak dikey sıkışma önlendi
                if (value == meta.min ||
                    value == meta.max ||
                    value <= minY ||
                    value >= maxY) {
                  return const SizedBox.shrink();
                }
                // [FIXED]: Metin yatay taşmaları önlemek için SideTitleWidget içine sarıldı
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    AppFormatter.amountFromDouble(value),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                );
              },
            ),
          ),
        ),

        borderData: FlBorderData(show: false),

        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (avgCost != null &&
                avgCost!.toDouble() >= minY &&
                avgCost!.toDouble() <= maxY)
              HorizontalLine(
                y: avgCost!.toDouble(),
                color: Colors.white.withValues(alpha: AppAlphas.overlay),
                strokeWidth: 1.5,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(
                    right: AppDimens.p4,
                    bottom: AppDimens.p4,
                  ),
                  style: AppTextStyles.captionBold,
                  labelResolver: (_) =>
                      '${AppStrings.labels.avgShort}: ${AppFormatter.amount(avgCost!, "")}',
                ),
              ),
          ],
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: AppAlphas.borderLight),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          if (visibleTxs.isNotEmpty)
            LineChartBarData(
              spots: visibleTxs
                  .map(
                    (t) => FlSpot(
                      t.date.millisecondsSinceEpoch.toDouble(),
                      t.price.toDouble(),
                    ),
                  )
                  .toList(),
              isCurved: false,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final tx = visibleTxs[index];
                  return TransactionDotPainter(
                    isBuy: tx.isBuy,
                    backgroundColor: const Color(0xFF141722),
                    borderColor: AppColors.brandBlue,
                    iconColor: Colors.white,
                    radius: 7.0,
                  );
                },
              ),
            ),
        ],

        lineTouchData: LineTouchData(
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {
                if (!event.isInterestedForInteractions ||
                    touchResponse == null ||
                    touchResponse.lineBarSpots == null) {
                  onScrub(null);
                  return;
                }
                final spot = touchResponse.lineBarSpots!.first;
                if (spot.barIndex == 0) {
                  onScrub(
                    PricePoint(
                      timestamp: DateTime.fromMillisecondsSinceEpoch(
                        spot.x.toInt(),
                      ),
                      price: Decimal.parse(spot.y.toString()),
                    ),
                  );
                }
              },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                Colors.blueGrey.shade900.withValues(alpha: 0.95),
            tooltipPadding: const EdgeInsets.all(AppDimens.p8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                if (touchedSpot.barIndex == 1) {
                  final tx = visibleTxs[touchedSpot.spotIndex];
                  final type = tx.isBuy
                      ? AppStrings.labels.buy.toUpperCase()
                      : AppStrings.labels.sell.toUpperCase();

                  String profitStr = '';
                  if (!tx.isBuy && tx.realizedProfit != null) {
                    profitStr =
                        '\nK/Z: ${AppFormatter.pnlValue(tx.realizedProfit!)}';
                  }

                  return LineTooltipItem(
                    '$type\n${AppFormatter.money(tx.price)}\n${AppFormatter.amount(tx.amount, "")} ${AppStrings.labels.units}$profitStr',
                    AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                final date = DateTime.fromMillisecondsSinceEpoch(
                  touchedSpot.x.toInt(),
                );
                return LineTooltipItem(
                  '${AppFormatter.moneyFromDouble(touchedSpot.y)}\n',
                  AppTextStyles.bodyLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat('dd MMM HH:mm').format(date),
                      style: AppTextStyles.caption,
                    ),
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((_) {
                  return TouchedSpotIndicatorData(
                    const FlLine(
                      color: Colors.white30,
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: color,
                          ),
                    ),
                  );
                }).toList();
              },
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER FOR + AND - BUTTONS ---
class TransactionDotPainter extends FlDotPainter {
  final bool isBuy;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;

  TransactionDotPainter({
    required this.isBuy,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.radius = 7.0,
  });

  @override
  Color get mainColor => backgroundColor;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is! TransactionDotPainter || b is! TransactionDotPainter) {
      return b;
    }
    return TransactionDotPainter(
      isBuy: b.isBuy,
      iconColor: Color.lerp(a.iconColor, b.iconColor, t) ?? b.iconColor,
      backgroundColor:
          Color.lerp(a.backgroundColor, b.backgroundColor, t) ??
          b.backgroundColor,
      borderColor: Color.lerp(a.borderColor, b.borderColor, t) ?? b.borderColor,
      radius: (a.radius + (b.radius - a.radius) * t),
    );
  }

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // 1. Opak Arka Plan
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius, bgPaint);

    // 2. Dış Mavi Kontür Çerçevesi
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(offsetInCanvas, radius, borderPaint);

    // 3. İçerideki Artı / Eksi Simgesi
    final linePaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final lineLength = radius * 0.42;

    // Yatay çizgi
    canvas.drawLine(
      Offset(offsetInCanvas.dx - lineLength, offsetInCanvas.dy),
      Offset(offsetInCanvas.dx + lineLength, offsetInCanvas.dy),
      linePaint,
    );

    // Alış ise (+) dikey çizgiyi ekle
    if (isBuy) {
      canvas.drawLine(
        Offset(offsetInCanvas.dx, offsetInCanvas.dy - lineLength),
        Offset(offsetInCanvas.dx, offsetInCanvas.dy + lineLength),
        linePaint,
      );
    }
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  List<Object?> get props => [
    isBuy,
    iconColor,
    backgroundColor,
    borderColor,
    radius,
  ];
}
