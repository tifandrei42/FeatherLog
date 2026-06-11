import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'add + getAll (oldest first), multiple types and same-day rows',
    () async {
      await db.bodyMeasurementDao.addMeasurement(
        measuredAt: DateTime(2026, 5, 28, 8),
        type: 'waist',
        valueCm: 85.0,
      );
      await db.bodyMeasurementDao.addMeasurement(
        measuredAt: DateTime(2026, 5, 28, 9),
        type: 'chest',
        valueCm: 100.0,
      );
      await db.bodyMeasurementDao.addMeasurement(
        measuredAt: DateTime(2026, 5, 29, 8),
        type: 'waist',
        valueCm: 84.5,
      );

      final all = await db.bodyMeasurementDao.getAll();
      expect(all, hasLength(3));
      expect(all.first.valueCm, 85.0); // oldest first
    },
  );

  test('watchByType filters and orders newest first', () async {
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 5, 27, 8),
      type: 'waist',
      valueCm: 86.0,
    );
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 5, 29, 8),
      type: 'waist',
      valueCm: 84.0,
    );
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 5, 28, 8),
      type: 'hips',
      valueCm: 95.0,
    );

    final waist = await db.bodyMeasurementDao.watchByType('waist').first;
    expect(waist.map((m) => m.valueCm), [84.0, 86.0]); // newest first
    expect(waist.every((m) => m.type == 'waist'), isTrue);
  });

  test('distinctTypes returns sorted unique types', () async {
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 5, 28),
      type: 'waist',
      valueCm: 85,
    );
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 5, 28),
      type: 'chest',
      valueCm: 100,
    );
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 5, 29),
      type: 'waist',
      valueCm: 84,
    );
    expect(await db.bodyMeasurementDao.distinctTypes(), ['chest', 'waist']);
  });

  test('update and delete', () async {
    final id = await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 5, 28, 8),
      type: 'waist',
      valueCm: 85.0,
    );
    await db.bodyMeasurementDao.updateMeasurement(
      id: id,
      measuredAt: DateTime(2026, 5, 28, 8),
      type: 'waist',
      valueCm: 83.0,
      note: 'fixed',
    );
    var all = await db.bodyMeasurementDao.getAll();
    expect(all.single.valueCm, 83.0);
    expect(all.single.note, 'fixed');

    expect(await db.bodyMeasurementDao.deleteMeasurement(id), 1);
    expect(await db.bodyMeasurementDao.getAll(), isEmpty);
  });

  test('updateMeasurement preserves v7 provenance fields', () async {
    // Regression: replace() used to null out source/externalId/profileId on
    // every edit of an imported measurement.
    final id = await db
        .into(db.bodyMeasurements)
        .insert(
          BodyMeasurementsCompanion.insert(
            measuredAt: DateTime(2026, 5, 28, 8),
            type: 'waist',
            valueCm: 85.0,
            source: const Value('aktibmi'),
            externalId: const Value('m-3'),
            profileId: const Value(2),
          ),
        );
    await db.bodyMeasurementDao.updateMeasurement(
      id: id,
      measuredAt: DateTime(2026, 5, 28, 8),
      type: 'waist',
      valueCm: 83.0,
      note: 'fixed',
    );
    final row = await (db.select(
      db.bodyMeasurements,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(row.valueCm, 83.0);
    expect(row.note, 'fixed');
    expect(row.source, 'aktibmi');
    expect(row.externalId, 'm-3');
    expect(row.profileId, 2);
  });
}
