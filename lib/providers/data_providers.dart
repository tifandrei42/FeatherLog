import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/age.dart';
import '../domain/consistency.dart';
import '../domain/daily.dart';
import '../domain/milestones.dart';
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
