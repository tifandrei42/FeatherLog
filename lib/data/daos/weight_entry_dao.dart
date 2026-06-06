import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'weight_entry_dao.g.dart';

/// Data access for [WeightEntries].
///
/// Every reading is stored with a full `measuredAt` timestamp; multiple
/// readings per day are kept (no overwrite). Aggregation to one value per day
/// for the chart/stats happens in the domain layer. All weights are canonical
/// kilograms; display conversion happens in the UI.
@DriftAccessor(tables: [WeightEntries])
class WeightEntryDao extends DatabaseAccessor<AppDatabase>
    with _$WeightEntryDaoMixin {
  WeightEntryDao(super.db);

  /// All readings, newest first, as a reactive stream (drives list/chart/stats).
  Stream<List<WeightEntry>> watchAllEntries() {
    return (select(
      weightEntries,
    )..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])).watch();
  }

  /// One-shot read of all readings, oldest first (handy for export / math).
  Future<List<WeightEntry>> getAllEntries() {
    return (select(
      weightEntries,
    )..orderBy([(t) => OrderingTerm.asc(t.measuredAt)])).get();
  }

  /// All readings whose `measuredAt` falls on the calendar day of [day],
  /// oldest first.
  Future<List<WeightEntry>> getReadingsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(weightEntries)
          ..where((t) => t.measuredAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
        .get();
  }

  /// Inserts a new reading. Returns the new row id. Never overwrites an
  /// existing reading — each call adds a distinct measurement.
  Future<int> addReading({
    required DateTime measuredAt,
    required double weightKg,
    String? note,
  }) {
    return into(weightEntries).insert(
      WeightEntriesCompanion.insert(
        measuredAt: measuredAt,
        weightKg: weightKg,
        note: Value(note),
      ),
    );
  }

  /// Updates an existing reading by id (used by edit). Bumps `updatedAt`.
  Future<bool> updateReading({
    required int id,
    required DateTime measuredAt,
    required double weightKg,
    String? note,
  }) {
    return update(weightEntries).replace(
      WeightEntriesCompanion(
        id: Value(id),
        measuredAt: Value(measuredAt),
        weightKg: Value(weightKg),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes a single reading by id. Returns the number of rows removed.
  Future<int> deleteEntry(int id) {
    return (delete(weightEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Bulk insert of readings, used by JSON import (Phase 5). Each reading is
  /// keyed by its timestamp, so distinct readings (including several on one
  /// day) are all preserved.
  Future<void> bulkInsert(Iterable<WeightEntriesCompanion> entries) {
    return batch((b) => b.insertAll(weightEntries, entries.toList()));
  }

  /// Removes every reading. Used before a full restore (Phase 5).
  Future<int> deleteAllEntries() => delete(weightEntries).go();
}
