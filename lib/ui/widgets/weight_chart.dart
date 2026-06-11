import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/daily.dart';
import '../../domain/stats.dart';
import '../../domain/units.dart';
import '../theme/app_theme.dart';

/// A line chart of the daily-aggregated weight series.
///
/// Plots one point per calendar day (the [DailyWeight] series from the domain
/// layer). With a single day it shows just the point; the trend line needs at
/// least two days. Values are shown in the user's [unit]; storage stays kg.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.daily,
    required this.unit,
    this.onDaySelected,
    this.selectedDay,
    this.goalKg,
    this.goalLabel = 'Goal',
    this.showMovingAverage = false,
  });

  /// Oldest-first daily series (as produced by `dailyAverages`).
  final List<DailyWeight> daily;
  final WeightUnit unit;

  /// Called with the nearest day when the chart is tapped/dragged, or null when
  /// the touch ends without a selection.
  final ValueChanged<DailyWeight?>? onDaySelected;

  /// The currently selected day, highlighted on the line.
  final DateTime? selectedDay;

  /// Canonical weight (kg) of the horizontal reference line, or null to hide.
  /// Trends passes the *next milestone* target here (which becomes the goal once
  /// you're in the final stretch), so the y-axis isn't stretched to a far goal.
  final double? goalKg;

  /// Short label shown on the reference line (e.g. 'Next' or 'Goal').
  final String goalLabel;

  /// Whether to overlay a 7-day moving-average line on top of the raw series.
  /// Only drawn when there are at least two points.
  final bool showMovingAverage;

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

    // Optional 7-day moving-average overlay. Smoothed values are always within
    // the raw data range, so they don't affect the Y-axis bounds below.
    final showMa = showMovingAverage && daily.length >= 2;
    final maSpots = showMa
        ? [
            for (final d in movingAverage(daily))
              FlSpot(xFor(d.day), weightFromKg(d.weightKg, unit)),
          ]
        : const <FlSpot>[];

    final goalY = goalKg == null ? null : weightFromKg(goalKg!, unit);

    final ys = spots.map((s) => s.y).toList();
    // Include the goal in the range so its line is always visible.
    if (goalY != null) ys.add(goalY);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    // Pad the range so the line isn't glued to the top/bottom; guarantee a
    // non-zero span when all points are equal.
    final pad = ((maxY - minY) * 0.15).clamp(0.5, double.infinity);

    final maxX = spots.last.x;
    // Aim for ~4 date labels across the axis.
    final labelStep = (maxX / 4).ceilToDouble().clamp(1.0, double.infinity);

    // Index of the currently selected day, for the highlight dot.
    final selectedIndex = selectedDay == null
        ? -1
        : daily.indexWhere((d) => d.day == selectedDay);

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
          extraLinesData: goalY == null
              ? const ExtraLinesData()
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goalY,
                      color: _goalColor(theme),
                      strokeWidth: 2,
                      dashArray: const [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _goalColor(theme),
                        ),
                        labelResolver: (_) => goalLabel,
                      ),
                    ),
                  ],
                ),
          lineBarsData: [
            // Moving-average overlay, drawn beneath the raw line so it stays
            // visually subordinate: thinner, distinct shade, no dots, no fill.
            if (showMa)
              LineChartBarData(
                spots: maSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: theme.colorScheme.tertiary,
                barWidth: 2,
                dashArray: const [6, 4],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                // Show all dots on short series; otherwise just the selected one.
                show: spots.length <= 14 || selectedIndex >= 0,
                checkToShowDot: (spot, _) =>
                    spots.length <= 14 || spot.x == selectedIndex.toDouble(),
                getDotPainter: (spot, _, _, _) {
                  final isSelected =
                      selectedIndex >= 0 && spot.x == selectedIndex.toDouble();
                  return FlDotCirclePainter(
                    radius: isSelected ? 6 : 3,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.7),
                    strokeWidth: isSelected ? 2 : 0,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.28),
                    theme.colorScheme.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: onDaySelected != null,
            // Use the built-in tooltip sparingly; the rich detail lives in the
            // card below the chart (DESIGN §3.1).
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((_) => null).toList(),
            ),
            touchCallback: (event, response) {
              if (onDaySelected == null) return;
              final spot = response?.lineBarSpots?.firstOrNull;
              if (spot == null) {
                if (event is FlTapUpEvent || event is FlPanEndEvent) {
                  onDaySelected!(null);
                }
                return;
              }
              final i = spot.x.round();
              if (i >= 0 && i < daily.length) onDaySelected!(daily[i]);
            },
          ),
        ),
      ),
    );
  }

  /// Convenience label, e.g. for an axis title elsewhere.
  String get unitLabel => unit == WeightUnit.lb ? 'lb' : 'kg';

  /// "positive/sage" goal color from the theme palette (UI_DESIGN.md). Falls
  /// back to the sage tokens if the extension isn't registered (e.g. a bare
  /// MaterialApp in a widget test).
  Color _goalColor(ThemeData theme) {
    final palette = theme.extension<FeatherPalette>();
    if (palette != null) return palette.positive;
    return theme.brightness == Brightness.dark
        ? const Color(0xFF7CC4A4)
        : const Color(0xFF6BAF92);
  }
}
