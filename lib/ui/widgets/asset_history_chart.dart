import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_dimens.dart';
import 'package:yastik_alti/ui/utils/chart_data_smoother.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';

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
        child: Text(AppStrings.messages.emptyData, style: TextStyle(color: Colors.white.withValues(alpha: AppAlphas.bgMedium))),
      );
    }

    final rawSortedData = List<PricePoint>.from(data)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final smoothData = ChartDataSmoother.processAndSmooth(rawSortedData, period: 3);

    // [FIXED] Architectural Guard Clause: A line chart mathematically requires at least 2 points.
    // If the API returns 1 or 0 points, we gracefully abort the render to prevent FlChart 
    // from crashing on a zero-interval axis, avoiding the "silent failure" trap.
    if (smoothData.length < 2) {
      return Center(
        child: Text(
            AppStrings.messages.noDataForRange,
            style: TextStyle(color: Colors.white.withValues(alpha: AppAlphas.textMuted))
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

    // Secondary safety check just in case the API returns 2 points with the exact same timestamp
    if (startTime == endTime) {
      return Center(
        child: Text(
            AppStrings.messages.noDataForRange,
            style: TextStyle(color: Colors.white.withValues(alpha: AppAlphas.textMuted))
        ),
      );
    }

    final visibleTxs = transactions.where((t) {
      final ms = t.date.millisecondsSinceEpoch.toDouble();
      return ms >= startTime && ms <= endTime;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final spots = smoothData.map((p) => FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.price)).toList();

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
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: AppAlphas.faint), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (endTime - startTime) / 4,
              getTitlesWidget: (value, meta) {
                if (value == startTime || value == endTime) return const SizedBox();

                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final format = (selectedRange == 'Day') ? DateFormat('HH:mm') : DateFormat('dd MMM');

                return Padding(
                  padding: const EdgeInsets.only(top: AppDimens.p8),
                  child: Text(format.format(date), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: priceRange / 4,
              getTitlesWidget: (value, meta) {
                if (value <= minY || value >= maxY) return const SizedBox();
                return Text(
                    AppFormatter.amountFromDouble(value),
                    style: const TextStyle(color: Colors.white54, fontSize: 10)
                );
              },
            ),
          ),
        ),

        borderData: FlBorderData(show: false),

        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (avgCost != null && avgCost!.toDouble() >= minY && avgCost!.toDouble() <= maxY)
              HorizontalLine(
                y: avgCost!.toDouble(),
                color: Colors.white.withValues(alpha: AppAlphas.textMuted),
                strokeWidth: 1.5,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: AppDimens.p4, bottom: AppDimens.p4),
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  labelResolver: (_) => '${AppStrings.labels.avgShort}: ${AppFormatter.amount(avgCost!, "")}',
                ),
              ),
            HorizontalLine(
              y: maxPrice,
              color: Colors.greenAccent.withValues(alpha: AppAlphas.bgMedium),
              strokeWidth: 1,
              label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.bottomLeft,
                  style: TextStyle(color: Colors.greenAccent.withValues(alpha: AppAlphas.textSecondary), fontSize: 9),
                  labelResolver: (_) => '↑ ${AppStrings.labels.maxShort}'
              ),
            ),
            HorizontalLine(
              y: minPrice,
              color: Colors.redAccent.withValues(alpha: AppAlphas.bgMedium),
              strokeWidth: 1,
              label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topLeft,
                  style: TextStyle(color: Colors.redAccent.withValues(alpha: AppAlphas.textSecondary), fontSize: 9),
                  labelResolver: (_) => '↓ ${AppStrings.labels.minShort}'
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
                colors: [color.withValues(alpha: AppAlphas.borderLight), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
          if (visibleTxs.isNotEmpty)
            LineChartBarData(
              spots: visibleTxs.map((t) => FlSpot(t.date.millisecondsSinceEpoch.toDouble(), t.price.toDouble())).toList(),
              isCurved: false,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final tx = visibleTxs[index];
                  return FlDotCirclePainter(
                    radius: 5,
                    color: tx.isBuy ? Colors.greenAccent : Colors.redAccent,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
        ],

        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.lineBarSpots == null) {
              onScrub(null);
              return;
            }
            final spot = touchResponse.lineBarSpots!.first;
            if (spot.barIndex == 0) {
              onScrub(PricePoint(
                timestamp: DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()),
                price: Decimal.parse(spot.y.toString()),
              ));
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.shade900.withValues(alpha: 0.95),
            tooltipPadding: const EdgeInsets.all(AppDimens.p8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {

                if (touchedSpot.barIndex == 1) {
                  final tx = visibleTxs[touchedSpot.spotIndex];
                  final type = tx.isBuy ? AppStrings.labels.buy.toUpperCase() : AppStrings.labels.sell.toUpperCase();

                  String profitStr = '';
                  if (!tx.isBuy && tx.realizedProfit != null) {
                    profitStr = '\nK/Z: ${AppFormatter.pnlValue(tx.realizedProfit!)}';
                  }

                  return LineTooltipItem(
                    '$type\n${AppFormatter.money(tx.price)}\n${AppFormatter.amount(tx.amount, "")} ${AppStrings.labels.units}$profitStr',
                    TextStyle(
                      color: tx.isBuy ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }

                final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                return LineTooltipItem(
                  '${AppFormatter.moneyFromDouble(touchedSpot.y)}\n',
                  TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  children: [
                    TextSpan(
                      text: DateFormat('dd MMM HH:mm').format(date),
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                    )
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((_) {
              return TouchedSpotIndicatorData(
                const FlLine(color: Colors.white30, strokeWidth: 1, dashArray: [3, 3]),
                FlDotData(getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: color,
                )),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}