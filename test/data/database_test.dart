// `drift` and the test matcher library both export `isNull`/`isNotNull`; hide
// the drift expression-builders here so the matcher versions win in tests.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Fresh in-memory database per test — fast, isolated, no files on disk.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('WeightEntries', () {
    test('insert then read back the row', () async {
      final date = DateTime(2026, 5, 28);
      await db
          .into(db.weightEntries)
          .insert(WeightEntriesCompanion.insert(date: date, weightKg: 80.4));

      final rows = await db.select(db.weightEntries).get();
      expect(rows, hasLength(1));
      expect(rows.single.weightKg, 80.4);
      expect(rows.single.date, date);
      expect(rows.single.note, isNull);
    });

    test('enforces one entry per day (unique date)', () async {
      final date = DateTime(2026, 5, 28);
      await db
          .into(db.weightEntries)
          .insert(WeightEntriesCompanion.insert(date: date, weightKg: 80.0));

      // A second plain insert on the same date must fail the unique constraint.
      expect(
        () => db
            .into(db.weightEntries)
            .insert(WeightEntriesCompanion.insert(date: date, weightKg: 81.0)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('upsert by date overwrites the same day', () async {
      final date = DateTime(2026, 5, 28);
      // Upsert must target the unique `date` column, not the primary key —
      // otherwise the fresh auto-increment id means no conflict and the unique
      // index on date throws. This is the pattern the DAO will use for
      // "log/overwrite today's weight".
      Future<void> upsert(double kg) => db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(date: date, weightKg: kg),
            onConflict: DoUpdate(
              (old) => WeightEntriesCompanion(weightKg: Value(kg)),
              target: [db.weightEntries.date],
            ),
          );

      await upsert(80.0);
      await upsert(79.5);

      final rows = await db.select(db.weightEntries).get();
      expect(rows, hasLength(1));
      expect(rows.single.weightKg, 79.5);
    });

    test('update and delete a row', () async {
      final id = await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(
              date: DateTime(2026, 5, 28),
              weightKg: 80.0,
            ),
          );

      await (db.update(db.weightEntries)..where((t) => t.id.equals(id))).write(
        const WeightEntriesCompanion(weightKg: Value(78.2)),
      );
      var row = await (db.select(
        db.weightEntries,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.weightKg, 78.2);

      await (db.delete(db.weightEntries)..where((t) => t.id.equals(id))).go();
      expect(await db.select(db.weightEntries).get(), isEmpty);
    });
  });

  group('Profiles', () {
    test('height is nullable until set', () async {
      final id = await db.into(db.profiles).insert(const ProfilesCompanion());
      final p = await (db.select(
        db.profiles,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(p.heightCm, isNull);
      expect(p.goalWeightKg, isNull);
    });
  });

  group('Settings', () {
    test('defaults are kg / cm / system with overlays on', () async {
      final id = await db.into(db.settings).insert(const SettingsCompanion());
      final s = await (db.select(
        db.settings,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(s.weightUnit, 'kg');
      expect(s.lengthUnit, 'cm');
      expect(s.theme, 'system');
      expect(s.showMovingAvg, isTrue);
      expect(s.showGoalLine, isTrue);
    });
  });
}
