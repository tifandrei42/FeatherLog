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

    test('deleteEntry removes a single row', () async {
      final id = await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 28, 8),
        weightKg: 80.0,
      );
      expect(await db.weightEntryDao.deleteEntry(id), 1);
      expect(await db.weightEntryDao.getAllEntries(), isEmpty);
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
