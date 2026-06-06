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
