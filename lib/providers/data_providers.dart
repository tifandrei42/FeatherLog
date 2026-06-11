import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/age.dart';
import '../domain/consistency.dart';
import '../domain/daily.dart';
import '../domain/milestones.dart';
import '../domain/stats.dart';
import 'database_provider.dart';

/// All weight entries, newest first. Rebuilds dependents whenever an entry is
/// added, edited, or deleted.
final entriesProvider = StreamProvider<List<WeightEntry>>((ref) {
  return ref.watch(databaseProvider).weightEntryDao.watchAllEntries();
});

/// All body measurements (every type), newest first. Grouped by type on the
/// Body screen.
final measurementsProvider = StreamProvider<List<BodyMeasurement>>((ref) {
  return ref.watch(databaseProvider).bodyMeasurementDao.watchAll();
});

/// The single profile row (height, goal). Emits null until first created.
final profileProvider = StreamProvider<Profile?>((ref) {
  return ref.watch(databaseProvider).profileDao.watchProfile();
});

/// Display settings (units, theme, overlays). Emits null until first created.
final settingsProvider = StreamProvider<Setting?>((ref) {
  return ref.watch(databaseProvider).settingsDao.watchSettings();
});

/// The daily-aggregated weight series (oldest-first), derived once from
/// [entriesProvider] so milestone/consistency/chart code shares one computation.
/// Empty while entries are still loading.
final dailySeriesProvider = Provider<List<DailyWeight>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const <WeightEntry>[];
  return dailyAverages(
    entries.map((e) => Reading(measuredAt: e.measuredAt, weightKg: e.weightKg)),
  );
});

/// The Today hero's headline numbers, derived from the smoothed series:
/// [trendKg] is the latest 7-day moving-average weight (the honest, low-noise
/// number, RESEARCH.md §4), and [weeklyTrendDeltaKg] is how that trend changed
/// over the trailing week (trend-vs-trend, so a single heavy day doesn't
/// whipsaw it). Both null when there isn't enough data.
typedef TrendSnapshot = ({double? trendKg, double? weeklyTrendDeltaKg});

final trendSnapshotProvider = Provider<TrendSnapshot>((ref) {
  final daily = ref.watch(dailySeriesProvider);
  final smoothed = movingAverage(daily);
  // Need at least two logged days before the average is meaningfully a *trend*:
  // with a single day the moving average just equals that day's reading, so
  // leading with it and calling it a "trend" would be misleading (and would
  // print the same number twice). Below the threshold the hero falls back to
  // the raw "current weight".
  if (smoothed.length < 2) {
    return (trendKg: null, weeklyTrendDeltaKg: null);
  }
  return (
    trendKg: smoothed.last.weightKg,
    // periodChange over the smoothed series = the trend's own weekly delta.
    weeklyTrendDeltaKg: periodChange(smoothed, 7),
  );
});

/// Encouraging milestones reached across the whole series (chronological).
/// Recomputes when entries or the goal weight change.
final milestonesProvider = Provider<List<Milestone>>((ref) {
  final daily = ref.watch(dailySeriesProvider);
  final goalKg = ref.watch(profileProvider).value?.goalWeightKg;
  return detectMilestones(daily, goalKg: goalKg);
});

/// Logging-consistency snapshot (positive facts only — no "missed days").
/// Uses the wall clock for "today"; the underlying domain stays pure.
typedef ConsistencySnapshot = ({
  int currentStreak,
  int longestStreak,
  int daysLogged,
  int window,
});

final consistencyProvider = Provider<ConsistencySnapshot>((ref) {
  final daily = ref.watch(dailySeriesProvider);
  final now = DateTime.now();
  const window = 30;
  return (
    currentStreak: currentStreak(daily, today: now),
    longestStreak: longestStreak(daily),
    daysLogged: daysLoggedIn(daily, today: now, windowDays: window),
    window: window,
  );
});

/// Age + whether the adult WHO BMI bands should be presented as applicable
/// (false only when the birth date proves the person is under [adultBmiMinAge]).
typedef BmiContext = ({int? age, bool adultBandsApply});

final bmiContextProvider = Provider<BmiContext>((ref) {
  final birthDate = ref.watch(profileProvider).value?.birthDate;
  final now = DateTime.now();
  return (
    age: ageInYears(birthDate, asOf: now),
    adultBandsApply: adultBmiBandsApply(birthDate, asOf: now),
  );
});
