import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/data/pdf_report_service.dart';
import 'package:featherlog/domain/daily.dart';
import 'package:flutter_test/flutter_test.dart';

/// A PDF file starts with the magic bytes "%PDF-".
bool _looksLikePdf(List<int> bytes) =>
    bytes.length > 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';

void main() {
  const service = PdfReportService();
  final generatedAt = DateTime(2026, 6, 7);

  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Uint8List> buildFor(ChartRange range) async {
    return service.build(
      profile: await db.profileDao.getOrCreateProfile(),
      settings: await db.settingsDao.getOrCreateSettings(),
      entries: await db.weightEntryDao.getAllEntries(),
      measurements: await db.bodyMeasurementDao.getAll(),
      range: range,
      generatedAt: generatedAt,
    );
  }

  Future<void> seedRealistic() async {
    await db.profileDao.updateHeight(178);
    await db.profileDao.updateGoalWeight(75);
    await db.profileDao.updateSex('male');
    await db.profileDao.updateBirthDate(DateTime(1990, 3, 15));
    // 14 near-daily readings trending down, with composition on the latest.
    for (var i = 0; i < 14; i++) {
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 5, 25).add(Duration(days: i)),
        weightKg: 82.0 - i * 0.2,
        note: i == 3 ? 'after a long run' : null,
        bodyFatPct: i == 13 ? 21.5 : null,
        musclePct: i == 13 ? 40.0 : null,
        waterPct: i == 13 ? 55.0 : null,
      );
    }
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: DateTime(2026, 6, 6),
      type: 'waist',
      valueCm: 86.0,
    );
  }

  group('PdfReportService.build', () {
    test('produces a valid, non-trivial PDF for realistic data', () async {
      await seedRealistic();
      final bytes = await buildFor(ChartRange.month);
      expect(_looksLikePdf(bytes), isTrue);
      // A real multi-section report is comfortably over a few KB.
      expect(bytes.length, greaterThan(2000));
    });

    test('handles an empty database gracefully (still a valid PDF)', () async {
      final bytes = await buildFor(ChartRange.all);
      expect(_looksLikePdf(bytes), isTrue);
    });

    test('handles a single sparse entry without throwing', () async {
      await db.profileDao.updateHeight(170);
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 6, 1),
        weightKg: 70,
      );
      final bytes = await buildFor(ChartRange.week);
      expect(_looksLikePdf(bytes), isTrue);
    });

    test('builds for every chart range', () async {
      await seedRealistic();
      for (final range in ChartRange.values) {
        final bytes = await buildFor(range);
        expect(_looksLikePdf(bytes), isTrue, reason: 'range: ${range.name}');
      }
    });

    test('builds with imperial display units (lb / in)', () async {
      await seedRealistic();
      await db.settingsDao.updateWeightUnit('lb');
      await db.settingsDao.updateLengthUnit('in');
      final bytes = await buildFor(ChartRange.threeMonths);
      expect(_looksLikePdf(bytes), isTrue);
    });

    test('builds when height is unset (BMI column omitted)', () async {
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 6, 1),
        weightKg: 70,
      );
      await db.weightEntryDao.addReading(
        measuredAt: DateTime(2026, 6, 2),
        weightKg: 69.6,
      );
      final bytes = await buildFor(ChartRange.all);
      expect(_looksLikePdf(bytes), isTrue);
    });
  });
}
