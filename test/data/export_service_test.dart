import 'dart:convert';

import 'package:featherlog/data/database.dart';
import 'package:featherlog/data/export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ExportService();

  // Minimal stand-ins shaped like the drift row classes the service reads.
  // The drift Profile/WeightEntry are plain data holders; we build real ones
  // via the generated constructors.
  final profile = Profile(
    id: 1,
    heightCm: 178.0,
    goalWeightKg: 75.0,
    sex: null,
    birthDate: null,
    createdAt: DateTime.utc(2026, 1, 1),
  );
  final settings = Setting(
    id: 1,
    weightUnit: 'kg',
    lengthUnit: 'cm',
    theme: 'system',
    showMovingAvg: true,
    showGoalLine: true,
    palette: 'meadow',
  );
  final entries = [
    WeightEntry(
      id: 1,
      measuredAt: DateTime.utc(2026, 5, 28, 7, 30),
      weightKg: 80.4,
      note: null,
      createdAt: DateTime.utc(2026, 5, 28),
      updatedAt: DateTime.utc(2026, 5, 28),
    ),
    WeightEntry(
      id: 2,
      measuredAt: DateTime.utc(2026, 5, 29, 7, 15),
      weightKg: 80.1,
      note: 'after run, felt great',
      createdAt: DateTime.utc(2026, 5, 29),
      updatedAt: DateTime.utc(2026, 5, 29),
    ),
  ];

  group('toJson', () {
    test('matches the documented shape', () {
      final json = service.toJson(
        profile: profile,
        settings: settings,
        entries: entries,
        exportedAt: DateTime.utc(2026, 5, 30, 10),
      );
      final map = jsonDecode(json) as Map<String, dynamic>;

      expect(map['schema_version'], ExportService.schemaVersion);
      expect(map['exported_at'], '2026-05-30T10:00:00.000Z');
      expect(map['profile']['height_cm'], 178.0);
      expect(map['settings']['weight_unit'], 'kg');

      final list = map['entries'] as List;
      expect(list, hasLength(2));
      expect(list[0]['measured_at'], '2026-05-28T07:30:00.000Z');
      expect(list[0]['weight_kg'], 80.4);
      expect(list[1]['note'], 'after run, felt great');
    });

    test('round-trips through JSON decode', () {
      final json = service.toJson(
        profile: profile,
        settings: settings,
        entries: entries,
        exportedAt: DateTime.utc(2026, 5, 30),
      );
      expect(() => jsonDecode(json), returnsNormally);
    });
  });

  group('toCsv', () {
    test('has the header and a computed BMI column', () {
      final csv = service.toCsv(profile: profile, entries: entries);
      final lines = const LineSplitter().convert(csv);
      expect(
        lines.first,
        'measured_at,date,weight_kg,bmi,'
        'body_fat_pct,muscle_pct,water_pct,note',
      );
      // 80.4 kg @ 178 cm -> 25.4
      expect(lines[1], contains('2026-05-28,80.4,25.4,'));
    });

    test('omits BMI when height is unknown', () {
      final csv = service.toCsv(profile: null, entries: entries);
      final lines = const LineSplitter().convert(csv);
      // bmi field is empty -> two commas in a row around it.
      expect(lines[1], contains('80.4,,'));
    });

    test('quotes notes containing commas', () {
      final csv = service.toCsv(profile: profile, entries: entries);
      expect(csv, contains('"after run, felt great"'));
    });
  });
}
