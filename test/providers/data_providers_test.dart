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
