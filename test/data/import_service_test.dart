import 'package:drift/drift.dart' show Value;
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

    test(
      'export → import round-trips losslessly (incl. measurements)',
      () async {
        // Seed, export, wipe via importing into a fresh db, compare. Includes a
        // body measurement to guard the regression where the production JSON
        // export dropped measurements and a restore wiped them.
        await db.weightEntryDao.addReading(
          measuredAt: DateTime.utc(2026, 5, 27, 8),
          weightKg: 81.0,
          note: 'a, b',
        );
        await db.weightEntryDao.addReading(
          measuredAt: DateTime.utc(2026, 5, 28, 8),
          weightKg: 80.5,
        );
        await db.bodyMeasurementDao.addMeasurement(
          measuredAt: DateTime.utc(2026, 5, 28, 8),
          type: 'waist',
          valueCm: 84.0,
        );
        await db.profileDao.updateHeight(178);

        final json = const ExportService().toJson(
          profile: await db.profileDao.getOrCreateProfile(),
          settings: await db.settingsDao.getOrCreateSettings(),
          entries: await db.weightEntryDao.getAllEntries(),
          measurements: await db.bodyMeasurementDao.getAll(),
          exportedAt: DateTime.utc(2026, 5, 30),
        );

        final fresh = AppDatabase.forTesting(NativeDatabase.memory());
        await fresh.applyImport(const ImportService().parse(json));
        final restored = await fresh.weightEntryDao.getAllEntries();
        expect(restored, hasLength(2));
        expect(restored.map((e) => e.weightKg), [81.0, 80.5]);
        expect(restored.first.note, 'a, b');
        expect((await fresh.profileDao.getOrCreateProfile()).heightCm, 178.0);
        expect(await fresh.bodyMeasurementDao.getAll(), hasLength(1));
        await fresh.close();
      },
    );
  });

  group('body composition (issue #47)', () {
    test('parses v2 body-composition fields', () {
      final r = importer.parse(
        '{"schema_version":2,"entries":[{'
        '"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0,'
        '"body_fat_pct":22.5,"muscle_pct":40.0,"water_pct":55.0}]}',
      );
      expect(r.isOk, isTrue);
      final c = r.entries.single;
      expect(c.bodyFatPct.value, 22.5);
      expect(c.musclePct.value, 40.0);
      expect(c.waterPct.value, 55.0);
    });

    test('v1 files (no composition fields) still import', () {
      final r = importer.parse(
        '{"schema_version":1,"entries":'
        '[{"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0}]}',
      );
      expect(r.isOk, isTrue);
      expect(r.entries.single.bodyFatPct.value, isNull);
    });

    test('out-of-range percentage is rejected', () {
      final r = importer.parse(
        '{"schema_version":2,"entries":[{'
        '"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0,'
        '"body_fat_pct":150}]}',
      );
      expect(r.isOk, isFalse);
      expect(r.error, contains('invalid percentage'));
    });

    test('export → import preserves composition', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.weightEntryDao.addReading(
        measuredAt: DateTime.utc(2026, 5, 28, 8),
        weightKg: 80.0,
        bodyFatPct: 21.0,
        musclePct: 41.0,
        waterPct: 56.0,
      );
      final json = const ExportService().toJson(
        profile: await db.profileDao.getOrCreateProfile(),
        settings: await db.settingsDao.getOrCreateSettings(),
        entries: await db.weightEntryDao.getAllEntries(),
        measurements: const [],
        exportedAt: DateTime.utc(2026, 5, 30),
      );

      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      await fresh.applyImport(const ImportService().parse(json));
      final e = (await fresh.weightEntryDao.getAllEntries()).single;
      expect(e.bodyFatPct, 21.0);
      expect(e.musclePct, 41.0);
      expect(e.waterPct, 56.0);
      await db.close();
      await fresh.close();
    });
  });

  group('body measurements (issue #48)', () {
    test('parses measurements; absent list is fine', () {
      final r = importer.parse(
        '{"schema_version":2,"entries":[],"measurements":[{'
        '"measured_at":"2026-05-28T08:00:00Z","type":"waist","value_cm":85.0}]}',
      );
      expect(r.isOk, isTrue);
      expect(r.measurements, hasLength(1));
      expect(r.measurements.single.type.value, 'waist');
      expect(r.measurements.single.valueCm.value, 85.0);

      final noList = importer.parse('{"schema_version":2,"entries":[]}');
      expect(noList.isOk, isTrue);
      expect(noList.measurements, isEmpty);
    });

    test('rejects an invalid measurement value/type', () {
      final badValue = importer.parse(
        '{"schema_version":2,"entries":[],"measurements":[{'
        '"measured_at":"2026-05-28T08:00:00Z","type":"waist","value_cm":0}]}',
      );
      expect(badValue.isOk, isFalse);
      final badType = importer.parse(
        '{"schema_version":2,"entries":[],"measurements":[{'
        '"measured_at":"2026-05-28T08:00:00Z","type":"","value_cm":85}]}',
      );
      expect(badType.isOk, isFalse);
    });

    test('export → import round-trips measurements', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.bodyMeasurementDao.addMeasurement(
        measuredAt: DateTime.utc(2026, 5, 28, 8),
        type: 'waist',
        valueCm: 85.0,
      );
      final json = const ExportService().toJson(
        profile: await db.profileDao.getOrCreateProfile(),
        settings: await db.settingsDao.getOrCreateSettings(),
        entries: await db.weightEntryDao.getAllEntries(),
        measurements: await db.bodyMeasurementDao.getAll(),
        exportedAt: DateTime.utc(2026, 5, 30),
      );

      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      await fresh.applyImport(const ImportService().parse(json));
      final m = (await fresh.bodyMeasurementDao.getAll()).single;
      expect(m.type, 'waist');
      expect(m.valueCm, 85.0);
      await db.close();
      await fresh.close();
    });
  });

  group('v7 provenance + event fields', () {
    test('parses source/external_id/profile_id/is_event/event_label', () {
      final r = importer.parse(
        '{"schema_version":2,"entries":[{'
        '"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0,'
        '"source":"aktibmi","external_id":"abc-1","profile_id":2,'
        '"is_event":true,"event_label":"started gym"}]}',
      );
      expect(r.isOk, isTrue);
      final c = r.entries.single;
      expect(c.source.value, 'aktibmi');
      expect(c.externalId.value, 'abc-1');
      expect(c.profileId.value, 2);
      expect(c.isEvent.value, isTrue);
      expect(c.eventLabel.value, 'started gym');
    });

    test('absent v7 fields default to null/false (older files import)', () {
      final r = importer.parse(
        '{"schema_version":2,"entries":'
        '[{"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0}]}',
      );
      expect(r.isOk, isTrue);
      final c = r.entries.single;
      expect(c.source.value, isNull);
      expect(c.isEvent.value, isFalse);
      expect(c.eventLabel.value, isNull);
    });

    test('malformed v7 field types are coerced, not thrown', () {
      // source as a number, profile_id as a string, is_event as a string:
      // the parser stays lenient (never throws) and falls back to defaults.
      final r = importer.parse(
        '{"schema_version":2,"entries":[{'
        '"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0,'
        '"source":42,"profile_id":"nope","is_event":"yes"}]}',
      );
      expect(r.isOk, isTrue);
      final c = r.entries.single;
      expect(c.source.value, isNull);
      expect(c.profileId.value, isNull);
      expect(c.isEvent.value, isFalse); // only literal true counts
    });

    test(
      're-import is idempotent on (source, external_id), not a crash',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        // Two rows claim the same source record (different timestamps); the
        // importer collapses them to one (last wins) so applying never violates
        // the UNIQUE(source, external_id) index or aborts the restore.
        final r = importer.parse(
          '{"schema_version":2,"entries":['
          '{"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0,'
          '"source":"x","external_id":"dup"},'
          '{"measured_at":"2026-05-29T07:00:00Z","weight_kg":79.0,'
          '"source":"x","external_id":"dup"}]}',
        );
        expect(r.isOk, isTrue);
        expect(r.entries, hasLength(1)); // de-duped in the parser
        await db.applyImport(r); // does not throw
        final all = await db.weightEntryDao.getAllEntries();
        expect(all, hasLength(1));
        expect(all.single.weightKg, 79.0); // last occurrence wins
        await db.close();
      },
    );

    test('same instant, different provenance → both rows survive', () {
      // A manually-entered reading and an imported reading can share an exact
      // timestamp and are genuinely different rows; neither should be dropped.
      final r = importer.parse(
        '{"schema_version":2,"entries":['
        '{"measured_at":"2026-05-28T07:00:00Z","weight_kg":80.0},'
        '{"measured_at":"2026-05-28T07:00:00Z","weight_kg":81.0,'
        '"source":"health_connect","external_id":"hc-1"}]}',
      );
      expect(r.isOk, isTrue);
      expect(r.entries, hasLength(2));
    });

    test('measurements de-dupe on provenance; restore does not abort', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final r = importer.parse(
        '{"schema_version":2,"entries":[],"measurements":['
        '{"measured_at":"2026-05-28T08:00:00Z","type":"waist","value_cm":84.0,'
        '"source":"x","external_id":"m1"},'
        '{"measured_at":"2026-05-29T08:00:00Z","type":"waist","value_cm":83.0,'
        '"source":"x","external_id":"m1"}]}',
      );
      expect(r.isOk, isTrue);
      expect(r.measurements, hasLength(1)); // de-duped on (source, external_id)
      await db.applyImport(r); // no unique-index abort
      expect(await db.bodyMeasurementDao.getAll(), hasLength(1));
      await db.close();
    });

    test('export → import preserves an event entry with provenance', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db
          .into(db.weightEntries)
          .insert(
            WeightEntriesCompanion.insert(
              measuredAt: DateTime.utc(2026, 5, 28, 8),
              weightKg: 80.0,
              source: const Value('aktibmi'),
              externalId: const Value('row-7'),
              isEvent: const Value(true),
              eventLabel: const Value('vacation'),
            ),
          );
      final json = const ExportService().toJson(
        profile: await db.profileDao.getOrCreateProfile(),
        settings: await db.settingsDao.getOrCreateSettings(),
        entries: await db.weightEntryDao.getAllEntries(),
        measurements: const [],
        exportedAt: DateTime.utc(2026, 5, 30),
      );

      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      await fresh.applyImport(const ImportService().parse(json));
      final e = (await fresh.weightEntryDao.getAllEntries()).single;
      expect(e.source, 'aktibmi');
      expect(e.externalId, 'row-7');
      expect(e.isEvent, isTrue);
      expect(e.eventLabel, 'vacation');
      await db.close();
      await fresh.close();
    });
  });

  group('profile sex + birth date (issue #51)', () {
    test('parses sex and birth_date from the profile', () {
      final r = importer.parse(
        '{"schema_version":2,"profile":{"sex":"female",'
        '"birth_date":"2000-03-15T00:00:00.000Z"},"entries":[]}',
      );
      expect(r.isOk, isTrue);
      expect(r.sex, 'female');
      expect(r.birthDate, DateTime.utc(2000, 3, 15));
    });

    test('absent sex/birth_date is fine (null)', () {
      final r = importer.parse('{"schema_version":2,"entries":[]}');
      expect(r.isOk, isTrue);
      expect(r.sex, isNull);
      expect(r.birthDate, isNull);
    });

    test('an invalid birth_date is rejected', () {
      final r = importer.parse(
        '{"schema_version":2,"profile":{"birth_date":"nope"},"entries":[]}',
      );
      expect(r.isOk, isFalse);
      expect(r.error, contains('invalid birth date'));
    });

    test('export → import round-trips sex and birth date', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.profileDao.updateSex('male');
      await db.profileDao.updateBirthDate(DateTime.utc(1990, 7, 1));
      final json = const ExportService().toJson(
        profile: await db.profileDao.getOrCreateProfile(),
        settings: await db.settingsDao.getOrCreateSettings(),
        entries: await db.weightEntryDao.getAllEntries(),
        measurements: const [],
        exportedAt: DateTime.utc(2026, 5, 30),
      );

      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      await fresh.applyImport(const ImportService().parse(json));
      final p = await fresh.profileDao.getOrCreateProfile();
      expect(p.sex, 'male');
      // drift reads DateTime back in local time; compare the instant, not the
      // wall-clock representation / isUtc flag.
      expect(p.birthDate!.isAtSameMomentAs(DateTime.utc(1990, 7, 1)), isTrue);
      await db.close();
      await fresh.close();
    });
  });
}
