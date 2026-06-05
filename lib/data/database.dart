import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/profile_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/weight_entry_dao.dart';
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
  tables: [Profiles, WeightEntries, Settings],
  daos: [WeightEntryDao, ProfileDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Injects a custom executor (e.g. an in-memory database) for unit tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    // `driftDatabase` picks the right platform implementation automatically.
    // The web build looks for sqlite3.wasm + drift_worker.js under web/.
    return driftDatabase(name: 'featherlog');
  }
}
