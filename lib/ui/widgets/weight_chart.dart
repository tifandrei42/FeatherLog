import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/daily.dart';
import '../../domain/units.dart';

/// A line chart of the daily-aggregated weight series.
///
/// Plots one point per calendar day (the [DailyWeight] series from the domain
/// layer). With a single day it shows just the point; the trend line needs at
/// least two days. Values are shown in the user's [unit]; storage stays kg.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.daily, required this.unit});

  /// Oldest-first daily series (as produced by `dailyAverages`).
  final List<DailyWeight> daily;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // X axis: whole days since the first entry, so spacing reflects real gaps.
    final firstDay = daily.first.day;
    double xFor(DateTime day) => day.difference(firstDay).inDays.toDouble();

    final spots = [
      for (final d in daily)
        FlSpot(xFor(d.day), weightFromKg(d.weightKg, unit)),
    ];

    final ys = spots.map((s) => s.y).toList();
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    // Pad the range so the line isn't glued to the top/bottom; guarantee a
    // non-zero span when all points are equal.
    final pad = ((maxY - minY) * 0.15).clamp(0.5, double.infinity);

    final maxX = spots.last.x;
    // Aim for ~4 date labels across the axis.
    final labelStep = (maxX / 4).ceilToDouble().clamp(1.0, double.infinity);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          minX: 0,
          maxX: maxX == 0 ? 1 : maxX,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY + pad) - (minY - pad)) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: labelStep,
                getTitlesWidget: (value, meta) {
                  final day = firstDay.add(Duration(days: value.round()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat.MMMd().format(day),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(show: spots.length <= 14),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }

  /// Convenience label, e.g. for an axis title elsewhere.
  String get unitLabel => unit == WeightUnit.lb ? 'lb' : 'kg';
}
