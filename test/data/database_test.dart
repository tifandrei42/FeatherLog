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
      final at = DateTime(2026, 5, 28, 7, 30);
      await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(measuredAt: at, weightKg: 80.4),
          );

      final rows = await db.select(db.weightEntries).get();
      expect(rows, hasLength(1));
      expect(rows.single.weightKg, 80.4);
      expect(rows.single.measuredAt, at);
      expect(rows.single.note, isNull);
    });

    test('keeps multiple readings on the same day (no unique date)', () async {
      final day = DateTime(2026, 5, 28);
      await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(
              measuredAt: day.add(const Duration(hours: 7)),
              weightKg: 80.0,
            ),
          );
      await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(
              measuredAt: day.add(const Duration(hours: 21)),
              weightKg: 81.0,
            ),
          );

      final rows = await db.select(db.weightEntries).get();
      expect(rows, hasLength(2)); // both kept, no overwrite
    });

    test('update and delete a row', () async {
      final id = await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(
              measuredAt: DateTime(2026, 5, 28, 8),
              weightKg: 80.0,
            ),
          );

      await (db.update(db.weightEntries)..where((t) => t.id.equals(id))).write(
        const WeightEntriesCompanion(weightKg: Value(78.2)),
      );
      final row = await (db.select(
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
