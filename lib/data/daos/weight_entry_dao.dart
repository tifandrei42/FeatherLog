import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'weight_entry_dao.g.dart';

/// Data access for [WeightEntries].
///
/// Encapsulates the one-entry-per-day rule (via [upsertForDate]) so callers
/// can't accidentally violate the unique `date` constraint. All weights are
/// canonical kilograms; conversion to/from display units happens in the UI.
@DriftAccessor(tables: [WeightEntries])
class WeightEntryDao extends DatabaseAccessor<AppDatabase>
    with _$WeightEntryDaoMixin {
  WeightEntryDao(super.db);

  /// All entries, newest first, as a reactive stream (drives chart/list/stats).
  Stream<List<WeightEntry>> watchAllEntries() {
    return (select(
      weightEntries,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  /// One-shot read of all entries, oldest first (handy for export / math).
  Future<List<WeightEntry>> getAllEntries() {
    return (select(
      weightEntries,
    )..orderBy([(t) => OrderingTerm.asc(t.date)])).get();
  }

  /// The entry logged for [date], or null if none exists.
  Future<WeightEntry?> getEntryForDate(DateTime date) {
    return (select(
      weightEntries,
    )..where((t) => t.date.equals(date))).getSingleOrNull();
  }

  /// Insert or overwrite the entry for a given day.
  ///
  /// Targets the unique `date` column (not the primary key) so re-logging the
  /// same day updates the existing row instead of throwing. Always refreshes
  /// `updatedAt`.
  Future<void> upsertForDate({
    required DateTime date,
    required double weightKg,
    String? note,
  }) {
    return into(weightEntries).insert(
      WeightEntriesCompanion.insert(
        date: date,
        weightKg: weightKg,
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
      onConflict: DoUpdate(
        (_) => WeightEntriesCompanion(
          weightKg: Value(weightKg),
          note: Value(note),
          updatedAt: Value(DateTime.now()),
        ),
        target: [weightEntries.date],
      ),
    );
  }

  /// Deletes a single entry by id. Returns the number of rows removed.
  Future<int> deleteEntry(int id) {
    return (delete(weightEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Bulk insert-or-overwrite, keyed by date. Used by JSON import (Phase 5)
  /// where last-write-wins on date collisions is desired.
  ///
  /// Conflict resolution targets the unique `date` column (not the primary key),
  /// so importing a date that already exists updates the row instead of hitting
  /// the unique constraint.
  Future<void> bulkUpsert(Iterable<WeightEntriesCompanion> entries) {
    final list = entries.toList();
    return batch((b) {
      for (final entry in list) {
        b.insert(
          weightEntries,
          entry,
          onConflict: DoUpdate((_) => entry, target: [weightEntries.date]),
        );
      }
    });
  }

  /// Removes every entry. Used before a full restore (Phase 5).
  Future<int> deleteAllEntries() => delete(weightEntries).go();
}
