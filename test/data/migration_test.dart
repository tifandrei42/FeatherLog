import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// v6 → v7 migration coverage (issue #72).
///
/// The v7 upgrade is additive: provenance/event columns on the data tables, a
/// few defaulted Settings flags, and helper indexes. Rather than rely on drift's
/// generated schema snapshots (which don't exist for the pre-release versions),
/// we stage a real v6 database with rows, hand it to drift, and let the actual
/// [AppDatabase.migration] run on open — then assert the data survived and the
/// new structure appeared. A second test pins the migrated schema against a
/// fresh v7 install so the two can't drift apart.
void main() {
  // The v6 schema: the current tables minus the v7 additions, and with no
  // helper indexes (those arrived in v7). `created_at`/`updated_at` omit their
  // DEFAULT expression — the migration never touches them and we insert
  // explicit values, so it's irrelevant to what's under test.
  const v6Ddl = [
    'CREATE TABLE profiles ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'height_cm REAL, goal_weight_kg REAL, sex TEXT, '
        'birth_date INTEGER, created_at INTEGER NOT NULL)',
    'CREATE TABLE weight_entries ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'measured_at INTEGER NOT NULL, weight_kg REAL NOT NULL, note TEXT, '
        'body_fat_pct REAL, muscle_pct REAL, water_pct REAL, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
    'CREATE TABLE body_measurements ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'measured_at INTEGER NOT NULL, type TEXT NOT NULL, '
        'value_cm REAL NOT NULL, note TEXT, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
    "CREATE TABLE settings ("
        "id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
        "weight_unit TEXT NOT NULL DEFAULT 'kg', "
        "length_unit TEXT NOT NULL DEFAULT 'cm', "
        "theme TEXT NOT NULL DEFAULT 'system', "
        "show_moving_avg INTEGER NOT NULL DEFAULT 1, "
        "show_goal_line INTEGER NOT NULL DEFAULT 1, "
        "palette TEXT NOT NULL DEFAULT 'meadow', "
        "check_updates INTEGER NOT NULL DEFAULT 0, "
        "dismissed_update_version TEXT)",
  ];

  /// Opens an in-memory database, builds the v6 schema, inserts a row per table,
  /// and stamps `user_version = 6`. Returned still-open so drift migrates it.
  Database openV6() {
    final raw = sqlite3.openInMemory();
    for (final stmt in v6Ddl) {
      raw.execute(stmt);
    }
    final t =
        DateTime(2026, 5, 1).millisecondsSinceEpoch ~/ 1000; // drift: secs
    raw.execute(
      'INSERT INTO profiles (id, height_cm, goal_weight_kg, sex, birth_date, '
      "created_at) VALUES (1, 178.0, 75.0, 'male', NULL, $t)",
    );
    raw.execute(
      'INSERT INTO weight_entries (measured_at, weight_kg, note, body_fat_pct, '
      "created_at, updated_at) VALUES ($t, 80.5, 'pre-v7', 21.0, $t, $t)",
    );
    raw.execute(
      'INSERT INTO weight_entries (measured_at, weight_kg, created_at, '
      'updated_at) VALUES (${t + 86400}, 80.0, ${t + 86400}, ${t + 86400})',
    );
    raw.execute(
      'INSERT INTO body_measurements (measured_at, type, value_cm, created_at, '
      "updated_at) VALUES ($t, 'waist', 84.0, $t, $t)",
    );
    raw.execute(
      'INSERT INTO settings (id, weight_unit, length_unit, theme) '
      "VALUES (1, 'lb', 'in', 'dark')",
    );
    raw.execute('PRAGMA user_version = 6');
    return raw;
  }

  test('v6 → v7 preserves data and applies the additive changes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.opened(openV6()));
    addTearDown(db.close);

    // Force the connection open, which runs the real migration.
    await db.customSelect('SELECT 1').get();

    // 1. Existing v6 data survived intact.
    final entries = await db.weightEntryDao.getAllEntries(); // oldest-first
    expect(entries, hasLength(2));
    expect(entries.first.weightKg, 80.5);
    expect(entries.first.note, 'pre-v7');
    expect(entries.first.bodyFatPct, 21.0);

    final profile = await db.profileDao.getOrCreateProfile();
    expect(profile.heightCm, 178.0);
    expect(profile.goalWeightKg, 75.0);
    expect(profile.sex, 'male');

    final settings = await db.settingsDao.getOrCreateSettings();
    expect(settings.weightUnit, 'lb');
    expect(settings.lengthUnit, 'in');
    expect(settings.theme, 'dark');

    final measurements = await db.bodyMeasurementDao.getAll();
    expect(measurements, hasLength(1));
    expect(measurements.single.type, 'waist');
    expect(measurements.single.valueCm, 84.0);

    // 2. The new v7 columns exist on the migrated rows, with their defaults.
    expect(entries.first.source, isNull);
    expect(entries.first.externalId, isNull);
    expect(entries.first.profileId, isNull);
    expect(entries.first.isEvent, isFalse);
    expect(entries.first.eventLabel, isNull);
    expect(measurements.single.source, isNull);
    expect(measurements.single.profileId, isNull);
    expect(settings.onboardingDone, isFalse);
    expect(settings.heroShowsTrend, isTrue);
    expect(settings.showEnergyEstimate, isFalse);

    // 3. The v7 helper indexes were created by the upgrade.
    final indexes =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'index' "
                  "AND name LIKE 'idx_%'",
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toSet();
    expect(
      indexes,
      containsAll([
        'idx_weight_entries_measured_at',
        'idx_body_measurements_measured_at',
        'idx_weight_entries_source_external',
        'idx_body_measurements_source_external',
      ]),
    );
  });

  test(
    'a migrated database is schema-compatible with a fresh v7 install',
    () async {
      final migrated = AppDatabase.forTesting(NativeDatabase.opened(openV6()));
      addTearDown(migrated.close);
      await migrated.customSelect('SELECT 1').get();

      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(fresh.close);
      await fresh.customSelect('SELECT 1').get();

      // Column name/type/nullability per table, normalised so order and the
      // default-expression difference on the base columns don't matter.
      Future<List<String>> columns(AppDatabase db, String table) async {
        final rows = await db.customSelect('PRAGMA table_info($table)').get();
        return rows
            .map(
              (r) =>
                  '${r.read<String>('name')}:'
                  '${r.read<String>('type')}:'
                  '${r.read<int>('notnull')}',
            )
            .toList()
          ..sort();
      }

      for (final table in const [
        'profiles',
        'weight_entries',
        'body_measurements',
        'settings',
      ]) {
        expect(
          await columns(migrated, table),
          await columns(fresh, table),
          reason: 'migrated "$table" columns should match a fresh v7 install',
        );
      }
    },
  );
}
