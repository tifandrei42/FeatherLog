import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'body_measurement_dao.g.dart';

/// Data access for [BodyMeasurements] (long-format: one row per reading, keyed
/// by [BodyMeasurements.type]). Values are canonical centimetres; display
/// conversion happens in the UI.
@DriftAccessor(tables: [BodyMeasurements])
class BodyMeasurementDao extends DatabaseAccessor<AppDatabase>
    with _$BodyMeasurementDaoMixin {
  BodyMeasurementDao(super.db);

  /// All readings of every type, newest first, as a reactive stream. Drives the
  /// Body screen, which groups by [BodyMeasurements.type] on read.
  Stream<List<BodyMeasurement>> watchAll() {
    return (select(
      bodyMeasurements,
    )..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])).watch();
  }

  /// All readings of [type], newest first, as a reactive stream.
  Stream<List<BodyMeasurement>> watchByType(String type) {
    return (select(bodyMeasurements)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
        .watch();
  }

  /// All readings (every type), oldest first — handy for export.
  Future<List<BodyMeasurement>> getAll() {
    return (select(
      bodyMeasurements,
    )..orderBy([(t) => OrderingTerm.asc(t.measuredAt)])).get();
  }

  /// The distinct measurement types that have at least one reading, so the UI
  /// can list only the body parts the user actually tracks.
  Future<List<String>> distinctTypes() async {
    final query = selectOnly(bodyMeasurements, distinct: true)
      ..addColumns([bodyMeasurements.type])
      ..orderBy([OrderingTerm.asc(bodyMeasurements.type)]);
    final rows = await query.get();
    return [for (final r in rows) r.read(bodyMeasurements.type)!];
  }

  /// Inserts a new measurement reading. Returns the new row id.
  Future<int> addMeasurement({
    required DateTime measuredAt,
    required String type,
    required double valueCm,
    String? note,
  }) {
    return into(bodyMeasurements).insert(
      BodyMeasurementsCompanion.insert(
        measuredAt: measuredAt,
        type: type,
        valueCm: valueCm,
        note: Value(note),
      ),
    );
  }

  /// Updates an existing reading by id. Bumps `updatedAt`.
  Future<bool> updateMeasurement({
    required int id,
    required DateTime measuredAt,
    required String type,
    required double valueCm,
    String? note,
  }) {
    return update(bodyMeasurements).replace(
      BodyMeasurementsCompanion(
        id: Value(id),
        measuredAt: Value(measuredAt),
        type: Value(type),
        valueCm: Value(valueCm),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes a single reading by id. Returns the number of rows removed.
  Future<int> deleteMeasurement(int id) {
    return (delete(bodyMeasurements)..where((t) => t.id.equals(id))).go();
  }

  /// Bulk insert, used by JSON import.
  Future<void> bulkInsert(Iterable<BodyMeasurementsCompanion> rows) {
    return batch((b) => b.insertAll(bodyMeasurements, rows.toList()));
  }

  /// Removes every measurement. Used before a full restore.
  Future<int> deleteAll() => delete(bodyMeasurements).go();
}
