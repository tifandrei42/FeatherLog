// Trend statistics derived from the daily-aggregated weight series.
//
// All functions are pure and operate on the oldest-first `DailyWeight` list
// from `daily.dart`. Rate and projection use the *smoothed* (moving-average)
// series so a single heavy day doesn't whipsaw them (RESEARCH.md §4).

import 'daily.dart';

/// Trailing simple moving average, windowed by **date** (not by count) so gaps
/// in logging don't distort it. For each day, averages all points whose day is
/// within the trailing [window]-day window ending on that day.
///
/// Returns one [DailyWeight] per input day, oldest first.
List<DailyWeight> movingAverage(List<DailyWeight> daily, {int window = 7}) {
  if (daily.isEmpty) return const [];
  final result = <DailyWeight>[];
  for (var i = 0; i < daily.length; i++) {
    final end = daily[i].day;
    final start = end.subtract(Duration(days: window - 1));
    var sum = 0.0;
    var count = 0;
    // Walk back while within the window.
    for (var j = i; j >= 0; j--) {
      if (daily[j].day.isBefore(start)) break;
      sum += daily[j].weightKg;
      count++;
    }
    result.add(DailyWeight(day: end, weightKg: sum / count));
  }
  return result;
}

/// Latest minus first weight across the whole series, or null if fewer than two
/// points.
double? totalChange(List<DailyWeight> daily) {
  if (daily.length < 2) return null;
  return daily.last.weightKg - daily.first.weightKg;
}

/// Change over the trailing [days] window: latest weight minus the earliest
/// weight still within the window (counting back from the most recent day).
/// Null if there's no earlier point in the window.
double? periodChange(List<DailyWeight> daily, int days) {
  if (daily.length < 2) return null;
  final cutoff = daily.last.day.subtract(Duration(days: days - 1));
  final inWindow = daily.where((d) => !d.day.isBefore(cutoff)).toList();
  if (inWindow.length < 2) return null;
  return inWindow.last.weightKg - inWindow.first.weightKg;
}

/// Average rate of change in kg per week, from a least-squares fit over the
/// smoothed series (x = days since first point, y = kg). Null if fewer than two
/// smoothed points or the dates don't span any time.
double? ratePerWeek(List<DailyWeight> daily, {int window = 7}) {
  final smoothed = movingAverage(daily, window: window);
  if (smoothed.length < 2) return null;

  final x0 = smoothed.first.day;
  final xs = [for (final d in smoothed) d.day.difference(x0).inDays.toDouble()];
  final ys = [for (final d in smoothed) d.weightKg];
  final n = xs.length;

  final meanX = xs.reduce((a, b) => a + b) / n;
  final meanY = ys.reduce((a, b) => a + b) / n;

  var num = 0.0;
  var den = 0.0;
  for (var i = 0; i < n; i++) {
    num += (xs[i] - meanX) * (ys[i] - meanY);
    den += (xs[i] - meanX) * (xs[i] - meanX);
  }
  if (den == 0) return null; // all points on the same day
  final slopePerDay = num / den;
  return slopePerDay * 7;
}

/// Estimated weeks to reach [goalKg] from [currentKg] at [ratePerWeek].
///
/// Returns null when a projection isn't meaningful: rate is ~0, or the trend is
/// moving away from the goal, or the goal is already met. Callers present the
/// result as an estimate ("~9 weeks"), never a promise (RESEARCH.md §4).
double? projectionWeeks({
  required double currentKg,
  required double goalKg,
  required double? ratePerWeek,
  double minRate = 0.05,
}) {
  if (ratePerWeek == null) return null;
  final remaining = goalKg - currentKg;
  if (remaining.abs() < 0.05) return null; // already at goal
  if (ratePerWeek.abs() < minRate) return null; // not really moving
  // Trend must point toward the goal: same sign as the needed change.
  if (remaining.sign != ratePerWeek.sign) return null;
  final weeks = remaining / ratePerWeek;
  return weeks <= 0 ? null : weeks;
}

double? minWeight(List<DailyWeight> daily) => daily.isEmpty
    ? null
    : daily.map((d) => d.weightKg).reduce((a, b) => a < b ? a : b);

double? maxWeight(List<DailyWeight> daily) => daily.isEmpty
    ? null
    : daily.map((d) => d.weightKg).reduce((a, b) => a > b ? a : b);

double? averageWeight(List<DailyWeight> daily) => daily.isEmpty
    ? null
    : daily.map((d) => d.weightKg).reduce((a, b) => a + b) / daily.length;
