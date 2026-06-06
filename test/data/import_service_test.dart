import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/data/export_service.dart';
import 'package:featherlog/data/import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const importer = ImportService();

  group('parse — rejections (data stays safe)', () {
    test('non-JSON is rejected', () {
      final r = importer.parse('not json {');
      expect(r.isOk, isFalse);
      expect(r.error, contains('valid JSON'));
    });

    test('a JSON array (wrong shape) is rejected', () {
      expect(importer.parse('[]').isOk, isFalse);
    });

    test('missing schema_version is rejected', () {
      expect(importer.parse('{"entries": []}').isOk, isFalse);
    });

    test('newer schema_version is rejected', () {
      final r = importer.parse('{"schema_version": 999, "entries": []}');
      expect(r.isOk, isFalse);
      expect(r.error, contains('newer version'));
    });

    test('an entry with an invalid date is rejected', () {
      final r = importer.parse(
        '{"schema_version":1,"entries":[{"measured_at":"nope","weight_kg":80}]}',
      );
      expect(r.isOk, isFalse);
      expect(r.error, contains('invalid date'));
    });

    test('an entry with a non-positive weight is rejected', () {
      final r = importer.parse(
        '{"schema_version":1,"entries":'
        '[{"measured_at":"2026-05-28T07:00:00Z","weight_kg":0}]}',
      );
      expect(r.isOk, isFalse);
      expect(r.error, contains('invalid weight'));
    });
  });

  group('parse — success', () {
    test('reads entries, profile and settings', () {
      final r = importer.parse(
        '{"schema_version":1,'
        '"profile":{"height_cm":178.0,"goal_weight_kg":75.0},'
        '"settings":{"weight_unit":"lb","length_unit":"in","theme":"dark"},'
        '"entries":[{"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.4,'
        '"note":"hi"}]}',
      );
      expect(r.isOk, isTrue);
      expect(r.entries, hasLength(1));
      expect(r.heightCm, 178.0);
      expect(r.weightUnit, 'lb');
      expect(r.theme, 'dark');
    });

    test('de-dupes by timestamp, last occurrence wins', () {
      final r = importer.parse(
        '{"schema_version":1,"entries":['
        '{"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0},'
        '{"measured_at":"2026-05-28T07:00:00Z","weight_kg":79.0}]}',
      );
      expect(r.entries, hasLength(1));
    });
  });

  group('applyImport — full restore', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('replaces existing entries', () async {
      // Pre-existing data that must be wiped by a restore.
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2020, 1, 1),
        weightKg: 99,
      );

      final r = importer.parse(
        '{"schema_version":1,"profile":{"height_cm":180.0},'
        '"entries":[{"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.4}]}',
      );
      await db.applyImport(r);

      final all = await db.weightEntryDao.getAllEntries();
      expect(all, hasLength(1));
      expect(all.single.weightKg, 80.4);
      expect((await db.profileDao.getOrCreateProfile()).heightCm, 180.0);
    });

    test('export → import round-trips losslessly', () async {
      // Seed, export, wipe via importing into a fresh db, compare.
      await db.weightEntryDao.addReading(
        measuredAt: DateTime.utc(2026, 5, 27, 8),
        weightKg: 81.0,
        note: 'a, b',
      );
      await db.weightEntryDao.addReading(
        measuredAt: DateTime.utc(2026, 5, 28, 8),
        weightKg: 80.5,
      );
      await db.profileDao.updateHeight(178);

      final entries = await db.weightEntryDao.getAllEntries();
      final profile = await db.profileDao.getOrCreateProfile();
      final settings = await db.settingsDao.getOrCreateSettings();
      final json = const ExportService().toJson(
        profile: profile,
        settings: settings,
        entries: entries,
        exportedAt: DateTime.utc(2026, 5, 30),
      );

      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      await fresh.applyImport(const ImportService().parse(json));
      final restored = await fresh.weightEntryDao.getAllEntries();
      expect(restored, hasLength(2));
      expect(restored.map((e) => e.weightKg), [81.0, 80.5]);
      expect(restored.first.note, 'a, b');
      expect((await fresh.profileDao.getOrCreateProfile()).heightCm, 178.0);
      await fresh.close();
    });
  });
}
