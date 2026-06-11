import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('WeightEntryDao', () {
    test('addReading keeps multiple readings on the same day', () async {
      final day = DateTime(2026, 5, 28);
      await db.weightEntryDao.addReading(
        measuredAt: day.add(const Duration(hours: 7)),
        weightKg: 80.4,
        note: 'morning',
      );
      await db.weightEntryDao.addReading(
        measuredAt: day.add(const Duration(hours: 21)),
        weightKg: 80.9,
        note: 'evening',
      );

      final all = await db.weightEntryDao.getAllEntries();
      expect(all, hasLength(2)); // both kept, no overwrite
      expect(all.map((e) => e.weightKg), [80.4, 80.9]); // oldest first
    });

    test('getReadingsForDay returns only that calendar day', () async {
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 28, 7),
        weightKg: 80.0,
      );
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 28, 21),
        weightKg: 81.0,
      );
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 29, 7),
        weightKg: 79.0,
      );

      final day = await db.weightEntryDao.getReadingsForDay(
        DateTime(2026, 5, 28),
      );
      expect(day, hasLength(2));
      expect(day.every((e) => e.measuredAt.day == 28), isTrue);
    });

    test('watchAllEntries emits newest first', () async {
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 27, 8),
        weightKg: 81.0,
      );
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 29, 8),
        weightKg: 80.0,
      );
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 28, 8),
        weightKg: 80.5,
      );

      final first = await db.weightEntryDao.watchAllEntries().first;
      expect(first.map((e) => e.measuredAt), [
        DateTime(2026, 5, 29, 8),
        DateTime(2026, 5, 28, 8),
        DateTime(2026, 5, 27, 8),
      ]);
    });

    test('updateReading edits in place', () async {
      final id = await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 28, 8),
        weightKg: 80.0,
      );
      await db.weightEntryDao.updateReading(
        id: id,
        measuredAt: DateTime(2026, 5, 28, 8),
        weightKg: 78.2,
        note: 'corrected',
      );
      final all = await db.weightEntryDao.getAllEntries();
      expect(all, hasLength(1));
      expect(all.single.weightKg, 78.2);
      expect(all.single.note, 'corrected');
    });

    test('updateReading preserves v7 provenance/event fields', () async {
      // Edit an imported, event-flagged reading and confirm the provenance and
      // event fields survive (regression: replace() used to null them out).
      final id = await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(
              measuredAt: DateTime(2026, 5, 28, 8),
              weightKg: 80.0,
              source: const Value('aktibmi'),
              externalId: const Value('row-7'),
              profileId: const Value(2),
              isEvent: const Value(true),
              eventLabel: const Value('started gym'),
            ),
          );
      await db.weightEntryDao.updateReading(
        id: id,
        measuredAt: DateTime(2026, 5, 28, 8),
        weightKg: 78.2,
        note: 'corrected',
      );
      final row = await (db.select(
        db.weightEntries,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.weightKg, 78.2);
      expect(row.note, 'corrected');
      expect(row.source, 'aktibmi');
      expect(row.externalId, 'row-7');
      expect(row.profileId, 2);
      expect(row.isEvent, isTrue);
      expect(row.eventLabel, 'started gym');
    });

    test('deleteEntry removes a single row', () async {
      final id = await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 28, 8),
        weightKg: 80.0,
      );
      expect(await db.weightEntryDao.deleteEntry(id), 1);
      expect(await db.weightEntryDao.getAllEntries(), isEmpty);
    });

    test('restoreEntry brings back a deleted row verbatim (undo)', () async {
      // An imported, event-flagged reading with composition — every field must
      // survive a delete→undo round-trip, including the id and provenance.
      final id = await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(
              measuredAt: DateTime(2026, 5, 28, 8),
              weightKg: 80.0,
              note: const Value('post-run'),
              bodyFatPct: const Value(21.5),
              source: const Value('aktibmi'),
              externalId: const Value('row-7'),
              profileId: const Value(2),
              isEvent: const Value(true),
              eventLabel: const Value('started gym'),
            ),
          );
      final original = await (db.select(
        db.weightEntries,
      )..where((t) => t.id.equals(id))).getSingle();

      await db.weightEntryDao.deleteEntry(id);
      expect(await db.weightEntryDao.getAllEntries(), isEmpty);

      await db.weightEntryDao.restoreEntry(original);
      final all = await db.weightEntryDao.getAllEntries();
      expect(all, hasLength(1));
      final restored = all.single;
      expect(restored.id, original.id); // same id (was just freed)
      expect(restored.weightKg, 80.0);
      expect(restored.note, 'post-run');
      expect(restored.bodyFatPct, 21.5);
      expect(restored.source, 'aktibmi');
      expect(restored.externalId, 'row-7');
      expect(restored.profileId, 2);
      expect(restored.isEvent, isTrue);
      expect(restored.eventLabel, 'started gym');
      expect(restored.createdAt, original.createdAt);
    });

    test('bulkInsert + deleteAllEntries (import path)', () async {
      await db.weightEntryDao.bulkInsert([
        WeightEntriesCompanion.insert(
          measuredAt: DateTime(2026, 5, 27, 8),
          weightKg: 81.0,
        ),
        WeightEntriesCompanion.insert(
          measuredAt: DateTime(2026, 5, 28, 7),
          weightKg: 80.0,
        ),
        WeightEntriesCompanion.insert(
          measuredAt: DateTime(2026, 5, 28, 21),
          weightKg: 80.6,
        ),
      ]);
      // All three kept, including two on the same day.
      expect(await db.weightEntryDao.getAllEntries(), hasLength(3));

      expect(await db.weightEntryDao.deleteAllEntries(), 3);
      expect(await db.weightEntryDao.getAllEntries(), isEmpty);
    });

    test(
      'addReading stores optional body composition; nulls by default',
      () async {
        await db.weightEntryDao.addReading(
          measuredAt: DateTime(2026, 5, 28, 8),
          weightKg: 80.0,
          bodyFatPct: 22.0,
          musclePct: 40.0,
          waterPct: 55.0,
        );
        await db.weightEntryDao.addReading(
          measuredAt: DateTime(2026, 5, 29, 8),
          weightKg: 79.5,
        );

        final all = await db.weightEntryDao.getAllEntries(); // oldest first
        expect(all.first.bodyFatPct, 22.0);
        expect(all.first.musclePct, 40.0);
        expect(all.first.waterPct, 55.0);
        expect(all.last.bodyFatPct, isNull); // weight-only entry
      },
    );
  });

  group('ProfileDao', () {
    test('getOrCreateProfile is idempotent (single row)', () async {
      final a = await db.profileDao.getOrCreateProfile();
      final b = await db.profileDao.getOrCreateProfile();
      expect(a.id, b.id);
      expect(await db.select(db.profiles).get(), hasLength(1));
    });

    test('updateHeight / updateGoalWeight persist', () async {
      await db.profileDao.updateHeight(178.0);
      await db.profileDao.updateGoalWeight(75.0);
      final p = await db.profileDao.getOrCreateProfile();
      expect(p.heightCm, 178.0);
      expect(p.goalWeightKg, 75.0);
    });
  });

  group('SettingsDao', () {
    test('getOrCreateSettings yields defaults', () async {
      final s = await db.settingsDao.getOrCreateSettings();
      expect(s.weightUnit, 'kg');
      expect(s.theme, 'system');
    });

    test('updates persist and stay a single row', () async {
      await db.settingsDao.updateWeightUnit('lb');
      await db.settingsDao.updateTheme('dark');
      await db.settingsDao.setShowGoalLine(false);
      final s = await db.settingsDao.getOrCreateSettings();
      expect(s.weightUnit, 'lb');
      expect(s.theme, 'dark');
      expect(s.showGoalLine, isFalse);
      expect(await db.select(db.settings).get(), hasLength(1));
    });
  });
}
