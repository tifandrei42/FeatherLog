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
    test('upsertForDate inserts then overwrites the same day', () async {
      final date = DateTime(2026, 5, 28);
      await db.weightEntryDao.upsertForDate(date: date, weightKg: 80.0);
      await db.weightEntryDao.upsertForDate(
        date: date,
        weightKg: 79.4,
        note: 'after run',
      );

      final all = await db.weightEntryDao.getAllEntries();
      expect(all, hasLength(1));
      expect(all.single.weightKg, 79.4);
      expect(all.single.note, 'after run');
    });

    test('getEntryForDate returns the row or null', () async {
      final date = DateTime(2026, 5, 28);
      expect(await db.weightEntryDao.getEntryForDate(date), isNull);
      await db.weightEntryDao.upsertForDate(date: date, weightKg: 80.0);
      expect(await db.weightEntryDao.getEntryForDate(date), isNotNull);
    });

    test('watchAllEntries emits newest first', () async {
      await db.weightEntryDao.upsertForDate(
        date: DateTime(2026, 5, 27),
        weightKg: 81.0,
      );
      await db.weightEntryDao.upsertForDate(
        date: DateTime(2026, 5, 29),
        weightKg: 80.0,
      );
      await db.weightEntryDao.upsertForDate(
        date: DateTime(2026, 5, 28),
        weightKg: 80.5,
      );

      final first = await db.weightEntryDao.watchAllEntries().first;
      expect(first.map((e) => e.date), [
        DateTime(2026, 5, 29),
        DateTime(2026, 5, 28),
        DateTime(2026, 5, 27),
      ]);
    });

    test('deleteEntry removes a single row', () async {
      await db.weightEntryDao.upsertForDate(
        date: DateTime(2026, 5, 28),
        weightKg: 80.0,
      );
      final entry = await db.weightEntryDao.getEntryForDate(
        DateTime(2026, 5, 28),
      );
      final removed = await db.weightEntryDao.deleteEntry(entry!.id);
      expect(removed, 1);
      expect(await db.weightEntryDao.getAllEntries(), isEmpty);
    });

    test('bulkUpsert + deleteAllEntries (import path)', () async {
      await db.weightEntryDao.bulkUpsert([
        WeightEntriesCompanion.insert(
          date: DateTime(2026, 5, 27),
          weightKg: 81.0,
        ),
        WeightEntriesCompanion.insert(
          date: DateTime(2026, 5, 28),
          weightKg: 80.0,
        ),
      ]);
      expect(await db.weightEntryDao.getAllEntries(), hasLength(2));

      // Re-upserting an existing date updates rather than duplicates.
      await db.weightEntryDao.bulkUpsert([
        WeightEntriesCompanion.insert(
          date: DateTime(2026, 5, 28),
          weightKg: 79.0,
        ),
      ]);
      final all = await db.weightEntryDao.getAllEntries();
      expect(all, hasLength(2));
      expect(
        all.firstWhere((e) => e.date == DateTime(2026, 5, 28)).weightKg,
        79.0,
      );

      expect(await db.weightEntryDao.deleteAllEntries(), 2);
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
