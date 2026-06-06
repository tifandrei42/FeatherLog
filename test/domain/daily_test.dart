import 'package:featherlog/domain/daily.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dailyAverages', () {
    test('empty input yields empty output', () {
      expect(dailyAverages([]), isEmpty);
    });

    test('one reading per day passes through, oldest first', () {
      final result = dailyAverages([
        Reading(measuredAt: DateTime(2026, 5, 29, 8), weightKg: 79.0),
        Reading(measuredAt: DateTime(2026, 5, 27, 8), weightKg: 81.0),
        Reading(measuredAt: DateTime(2026, 5, 28, 8), weightKg: 80.0),
      ]);
      expect(result.map((d) => d.day), [
        DateTime(2026, 5, 27),
        DateTime(2026, 5, 28),
        DateTime(2026, 5, 29),
      ]);
      expect(result.map((d) => d.weightKg), [81.0, 80.0, 79.0]);
    });

    test('multiple readings on a day are averaged', () {
      final result = dailyAverages([
        Reading(measuredAt: DateTime(2026, 5, 28, 7), weightKg: 80.0),
        Reading(measuredAt: DateTime(2026, 5, 28, 21), weightKg: 81.0),
      ]);
      expect(result, hasLength(1));
      expect(result.single.day, DateTime(2026, 5, 28));
      expect(result.single.weightKg, 80.5);
    });

    test('different times on the same calendar day collapse to one day', () {
      final result = dailyAverages([
        Reading(measuredAt: DateTime(2026, 5, 28, 0, 1), weightKg: 80.0),
        Reading(measuredAt: DateTime(2026, 5, 28, 23, 59), weightKg: 82.0),
      ]);
      expect(result, hasLength(1));
      expect(result.single.weightKg, 81.0);
    });
  });

  group('latestDailyAverage', () {
    test('returns null for no readings', () {
      expect(latestDailyAverage([]), isNull);
    });

    test('returns the most recent day, averaged', () {
      final latest = latestDailyAverage([
        Reading(measuredAt: DateTime(2026, 5, 27, 8), weightKg: 81.0),
        Reading(measuredAt: DateTime(2026, 5, 28, 7), weightKg: 80.0),
        Reading(measuredAt: DateTime(2026, 5, 28, 21), weightKg: 79.0),
      ]);
      expect(latest!.day, DateTime(2026, 5, 28));
      expect(latest.weightKg, 79.5);
    });
  });
}
