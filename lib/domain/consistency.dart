// Logging-consistency facts derived from the daily-aggregated weight series.
//
// All functions are pure and operate on the oldest-first `DailyWeight` list
// from `daily.dart`. By design these report only *positive* facts (streaks,
// days logged, the fraction of a window covered): there is no "missed days"
// or other punitive framing (RESEARCH.md, US habit-support).
//
// Nothing here reads the wall clock. Anything that depends on "today" takes an
// injected `today` so the library stays pure and testable (mirrors stats.dart).

import 'daily.dart';

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// The distinct calendar days that have at least one entry, oldest first.
///
/// Time-of-day is stripped so multiple readings on the same day count once.
List<DateTime> _loggedDays(List<DailyWeight> daily) {
  final set = <DateTime>{for (final d in daily) _dayOf(d.day)};
  final days = set.toList()..sort();
  return days;
}

/// Length of the run of consecutive logged days ending at [today] (or within
/// [graceDays] before it, so a not-yet-logged today doesn't zero an active
/// streak).
///
/// The most recent logged day must fall within the grace window — i.e. no more
/// than [graceDays] days before [today] — otherwise the streak has lapsed and
/// this returns 0. From that anchor, the run extends back over every immediately
/// preceding logged day. Multiple readings on one day count once.
///
/// Examples (graceDays defaults to 1): logged today -> counts; logged only
/// yesterday -> still counts (grace); newest log 3 days ago -> 0.
int currentStreak(
  List<DailyWeight> daily, {
  required DateTime today,
  int graceDays = 1,
}) {
  final days = _loggedDays(daily);
  if (days.isEmpty) return 0;

  final anchorDay = _dayOf(today);
  final newest = days.last;

  // How many days back is the most recent log? Future logs (negative) are
  // treated as on-time so a clock skew can't hide an active streak.
  final gap = anchorDay.difference(newest).inDays;
  if (gap > graceDays) return 0;

  // Walk back from the newest logged day over consecutive calendar days.
  var streak = 0;
  var expected = newest;
  for (var i = days.length - 1; i >= 0; i--) {
    if (days[i] == expected) {
      streak++;
      expected = expected.subtract(const Duration(days: 1));
    } else if (days[i].isBefore(expected)) {
      break; // a gap: the run has ended
    }
  }
  return streak;
}

/// The longest run of consecutive logged calendar days anywhere in the history,
/// or 0 if there are no logs. Multiple readings on one day count once.
int longestStreak(List<DailyWeight> daily) {
  final days = _loggedDays(daily);
  if (days.isEmpty) return 0;

  var longest = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final isNextDay = days[i].difference(days[i - 1]).inDays == 1;
    run = isNextDay ? run + 1 : 1;
    if (run > longest) longest = run;
  }
  return longest;
}

/// Fraction (0.0–1.0) of the last [windowDays] calendar days, ending on
/// [today], that have at least one log.
///
/// This is [daysLoggedIn] divided by [windowDays]. With no logs (or a
/// non-positive window) it is 0.0.
double consistency(
  List<DailyWeight> daily, {
  required DateTime today,
  int windowDays = 30,
}) {
  if (windowDays <= 0) return 0.0;
  return daysLoggedIn(daily, today: today, windowDays: windowDays) / windowDays;
}

/// Count of distinct calendar days with a log within the trailing [windowDays]
/// window ending on [today] (inclusive). Multiple readings on one day count
/// once; days logged in the future relative to [today] are not counted.
int daysLoggedIn(
  List<DailyWeight> daily, {
  required DateTime today,
  int windowDays = 30,
}) {
  if (windowDays <= 0) return 0;
  final anchorDay = _dayOf(today);
  final cutoff = anchorDay.subtract(Duration(days: windowDays - 1));
  var count = 0;
  for (final day in _loggedDays(daily)) {
    if (!day.isBefore(cutoff) && !day.isAfter(anchorDay)) count++;
  }
  return count;
}
