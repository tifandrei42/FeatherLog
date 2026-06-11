import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/body_measurement_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/weight_entry_dao.dart';
import 'import_service.dart';
import 'tables.dart';

part 'database.g.dart';

/// The FeatherLog database.
///
/// Holds the three tables (see `tables.dart`). All access goes through the
/// generated, type-safe API. The connection is provided by `drift_flutter`,
/// which transparently uses a native SQLite file on mobile/desktop and the
/// sqlite3 WASM build on web — so the same code runs everywhere, including the
/// Docker web demo.
@DriftDatabase(
  tables: [Profiles, WeightEntries, Settings, BodyMeasurements],
  daos: [WeightEntryDao, ProfileDao, SettingsDao, BodyMeasurementDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Injects a custom executor (e.g. an in-memory database) for unit tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // createAll() builds tables but not the helper indexes — add them so a
      // fresh install matches an upgraded one.
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: WeightEntries moved from a unique `date` to a non-unique
      // `measuredAt` timestamp (multiple readings per day are now kept).
      // Pre-release, so the old day-keyed rows are dropped and the table is
      // recreated rather than migrated row-by-row.
      if (from < 2) {
        await m.deleteTable(weightEntries.actualTableName);
        await m.createTable(weightEntries);
      }
      // v2 → v3: add nullable body-composition columns (additive — existing
      // rows keep their data; new columns default to null).
      if (from < 3) {
        await m.addColumn(weightEntries, weightEntries.bodyFatPct);
        await m.addColumn(weightEntries, weightEntries.musclePct);
        await m.addColumn(weightEntries, weightEntries.waterPct);
      }
      // v3 → v4: add the BodyMeasurements table (additive; no existing data
      // touched).
      if (from < 4) {
        await m.createTable(bodyMeasurements);
      }
      // v4 → v5: add the selected-palette preference (additive, defaulted).
      if (from < 5) {
        await m.addColumn(settings, settings.palette);
      }
      // v5 → v6: add the opt-in update-check preference + the dismissed-version
      // marker (additive; both default to off/null).
      if (from < 6) {
        await m.addColumn(settings, settings.checkUpdates);
        await m.addColumn(settings, settings.dismissedUpdateVersion);
      }
      // v6 → v7: provenance/event columns on the data tables + a few defaulted
      // Settings flags + helper indexes (the "foundation" that unblocks import
      // idempotency, event flags, onboarding, and the trend hero). All
      // additive: nullable or defaulted, so existing rows are untouched.
      if (from < 7) {
        await m.addColumn(weightEntries, weightEntries.source);
        await m.addColumn(weightEntries, weightEntries.externalId);
        await m.addColumn(weightEntries, weightEntries.profileId);
        await m.addColumn(weightEntries, weightEntries.isEvent);
        await m.addColumn(weightEntries, weightEntries.eventLabel);
        await m.addColumn(bodyMeasurements, bodyMeasurements.source);
        await m.addColumn(bodyMeasurements, bodyMeasurements.externalId);
        await m.addColumn(bodyMeasurements, bodyMeasurements.profileId);
        await m.addColumn(settings, settings.onboardingDone);
        await m.addColumn(settings, settings.heroShowsTrend);
        await m.addColumn(settings, settings.showEnergyEstimate);
        await _createIndexes();
      }
    },
  );

  /// Helper indexes created on both fresh installs ([onCreate]) and the v7
  /// upgrade. `measured_at` speeds chart range queries; the unique
  /// `(source, external_id)` pair makes re-imports idempotent. SQLite treats
  /// NULLs as distinct, so manually-entered rows (null source/external_id)
  /// never collide. `IF NOT EXISTS` keeps this safe to run more than once.
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_weight_entries_measured_at '
      'ON weight_entries (measured_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_body_measurements_measured_at '
      'ON body_measurements (measured_at)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_weight_entries_source_external '
      'ON weight_entries (source, external_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_body_measurements_source_external '
      'ON body_measurements (source, external_id)',
    );
  }

  /// Applies a parsed [ImportResult] as a full restore, in one transaction:
  /// existing entries are replaced, and profile/settings fields present in the
  /// backup are updated. Runs only after the import file has been validated, so
  /// a malformed file never reaches here (US-11.4).
  Future<void> applyImport(ImportResult result) {
    return transaction(() async {
      await weightEntryDao.deleteAllEntries();
      await weightEntryDao.bulkInsert(result.entries);

      await bodyMeasurementDao.deleteAll();
      await bodyMeasurementDao.bulkInsert(result.measurements);

      if (result.heightCm != null) {
        await profileDao.updateHeight(result.heightCm);
      }
      if (result.goalWeightKg != null) {
        await profileDao.updateGoalWeight(result.goalWeightKg);
      }
      if (result.sex != null) {
        await profileDao.updateSex(result.sex);
      }
      if (result.birthDate != null) {
        await profileDao.updateBirthDate(result.birthDate);
      }
      if (result.weightUnit != null) {
        await settingsDao.updateWeightUnit(result.weightUnit!);
      }
      if (result.lengthUnit != null) {
        await settingsDao.updateLengthUnit(result.lengthUnit!);
      }
      if (result.theme != null) {
        await settingsDao.updateTheme(result.theme!);
      }
    });
  }

  static QueryExecutor _openConnection() {
    // `driftDatabase` picks the right platform implementation automatically:
    // a native SQLite file on mobile/desktop, and sqlite3 WASM on web. On web
    // it must be told where the wasm engine + drift worker live — these are the
    // files served from web/ (see web/sqlite3.wasm and web/drift_worker.js).
    return driftDatabase(
      name: 'featherlog',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
