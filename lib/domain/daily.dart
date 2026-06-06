// Aggregation of raw readings into one value per calendar day.
//
// The data layer keeps every reading (with a full `measuredAt` timestamp), but
// the trend chart and statistics want a single clean value per day. This pure
// layer does that aggregation so the noise of multiple intraday readings never
// distorts the trend (DATA_MODEL.md §5, US-2.6).

/// A single day's aggregated weight.
class DailyWeight {
  const DailyWeight({required this.day, required this.weightKg});

  /// Midnight of the calendar day (local).
  final DateTime day;

  /// The aggregated canonical weight for that day.
  final double weightKg;
}

/// A reading as the domain layer needs it: a timestamp and a canonical weight.
/// Kept independent of the drift row type so this stays pure/testable.
class Reading {
  const Reading({required this.measuredAt, required this.weightKg});

  final DateTime measuredAt;
  final double weightKg;
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Collapses [readings] to one [DailyWeight] per calendar day, ordered oldest
/// first. The default aggregation is the day's mean (DATA_MODEL.md §5).
///
/// Days with no readings are simply absent (callers window by actual dates
/// rather than carrying values forward).
List<DailyWeight> dailyAverages(Iterable<Reading> readings) {
  final byDay = <DateTime, List<double>>{};
  for (final r in readings) {
    byDay.putIfAbsent(_dayOf(r.measuredAt), () => []).add(r.weightKg);
  }
  final days = byDay.keys.toList()..sort();
  return [
    for (final day in days)
      DailyWeight(
        day: day,
        weightKg: byDay[day]!.reduce((a, b) => a + b) / byDay[day]!.length,
      ),
  ];
}

/// The most recent single day's aggregated weight, or null if [readings] is
/// empty. Useful for the dashboard's "current weight".
DailyWeight? latestDailyAverage(Iterable<Reading> readings) {
  final daily = dailyAverages(readings);
  return daily.isEmpty ? null : daily.last;
}

/// Selectable chart time windows (US-6.3).
enum ChartRange {
  week('1W', 7),
  month('1M', 30),
  threeMonths('3M', 90),
  year('1Y', 365),
  all('All', null);

  const ChartRange(this.label, this.days);

  /// Short label for the segmented control.
  final String label;

  /// Window length in days, or null for "all".
  final int? days;
}

/// Returns the entries of [daily] within [range], counting back from the most
/// recent day in the series (not "now", so a gap at the end doesn't empty the
/// chart). [daily] is assumed oldest-first; the result preserves that order.
List<DailyWeight> filterByRange(List<DailyWeight> daily, ChartRange range) {
  final days = range.days;
  if (days == null || daily.isEmpty) return daily;
  final cutoff = daily.last.day.subtract(Duration(days: days - 1));
  return daily.where((d) => !d.day.isBefore(cutoff)).toList();
}
