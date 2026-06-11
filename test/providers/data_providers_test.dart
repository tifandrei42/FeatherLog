import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/providers/data_providers.dart';
import 'package:featherlog/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Override the database so providers read from the in-memory instance.
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('entriesProvider reflects rows written via the DAO', () async {
    // Keep the stream subscription alive so it re-emits after the write.
    container.listen(entriesProvider, (_, _) {});
    expect(await container.read(entriesProvider.future), isEmpty);

    await db.weightEntryDao.addReading(
      measuredAt: DateTime(2026, 5, 28, 8),
      weightKg: 80.0,
    );

    final entries = await _await(
      () => container.read(entriesProvider),
      (v) => v.isNotEmpty,
    );
    expect(entries.single.weightKg, 80.0);
  });

  test('profileProvider emits the profile once created', () async {
    container.listen(profileProvider, (_, _) {});
    expect(await container.read(profileProvider.future), isNull);

    await db.profileDao.updateHeight(178.0);

    // The stream emits the inserted row (null height) then the updated row;
    // wait for the height to actually land.
    final profile = await _await(
      () => container.read(profileProvider),
      (p) => p?.heightCm != null,
    );
    expect(profile!.heightCm, 178.0);
  });

  test('settingsProvider emits settings once created', () async {
    container.listen(settingsProvider, (_, _) {});
    expect(await container.read(settingsProvider.future), isNull);

    await db.settingsDao.updateTheme('dark');

    // Wait for the theme update to land (not just the inserted default row).
    final settings = await _await(
      () => container.read(settingsProvider),
      (s) => s?.theme == 'dark',
    );
    expect(settings!.theme, 'dark');
  });

  test(
    'trendSnapshotProvider exposes the smoothed trend + weekly delta',
    () async {
      container.listen(entriesProvider, (_, _) {});
      container.listen(trendSnapshotProvider, (_, _) {});

      // A clean 1 kg/day decline over 8 days: 80 → 73 (oldest first).
      for (var d = 0; d < 8; d++) {
        await db.weightEntryDao.addReading(
          measuredAt: DateTime(2026, 6, 1 + d, 8),
          weightKg: 80.0 - d,
        );
      }
      await _await(() => container.read(entriesProvider), (v) => v.length == 8);

      final trend = container.read(trendSnapshotProvider);
      // 7-day MA of the last day (79..73) = 76.0.
      expect(trend.trendKg, closeTo(76.0, 0.001));
      // Trend's own weekly change: MA(day8) − MA(day2) = 76.0 − 79.5 = −3.5.
      expect(trend.weeklyTrendDeltaKg, closeTo(-3.5, 0.001));
    },
  );

  test('trendSnapshotProvider is all-null with no data', () {
    final trend = container.read(trendSnapshotProvider);
    expect(trend.trendKg, isNull);
    expect(trend.weeklyTrendDeltaKg, isNull);
  });

  test(
    'nextMilestoneProvider tracks the next waypoint toward the goal',
    () async {
      container.listen(entriesProvider, (_, _) {});
      container.listen(profileProvider, (_, _) {});
      container.listen(nextMilestoneProvider, (_, _) {});

      expect(container.read(nextMilestoneProvider), isNull); // no data/goal yet

      await db.profileDao.updateGoalWeight(70);
      // start 90 -> current 84 = 30% of the 20 kg journey, so next is 50% (80 kg).
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 6, 1, 8),
        weightKg: 90,
      );
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 6, 2, 8),
        weightKg: 84,
      );
      await _await(() => container.read(entriesProvider), (v) => v.length == 2);
      await _await(
        () => container.read(profileProvider),
        (p) => p?.goalWeightKg == 70,
      );

      final m = container.read(nextMilestoneProvider);
      expect(m, isNotNull);
      expect(m!.percent, 50);
      expect(m.targetKg, closeTo(80.0, 1e-9));
    },
  );

  test(
    'trendSnapshotProvider needs >=2 days (no false trend on day one)',
    () async {
      // With a single logged day the moving average equals the raw reading, so
      // trendKg must stay null — the hero then leads with "current weight", not a
      // mislabelled "trend".
      container.listen(entriesProvider, (_, _) {});
      container.listen(trendSnapshotProvider, (_, _) {});
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 6, 1, 8),
        weightKg: 80.0,
      );
      await _await(() => container.read(entriesProvider), (v) => v.length == 1);
      final trend = container.read(trendSnapshotProvider);
      expect(trend.trendKg, isNull);
      expect(trend.weeklyTrendDeltaKg, isNull);
    },
  );
}

/// Polls [read] (an `AsyncValue` getter) until its value satisfies [test],
/// then returns that value. Riverpod 3 removed `.stream`, so we observe the
/// `AsyncValue` directly. Bounded by a short timeout to fail fast.
Future<T> _await<T>(
  AsyncValue<T> Function() read,
  bool Function(T value) test,
) async {
  for (var i = 0; i < 500; i++) {
    final async = read();
    if (async.hasValue) {
      final value = async.value as T;
      if (test(value)) return value;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('value did not satisfy predicate within timeout');
}
