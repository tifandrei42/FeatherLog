import 'package:featherlog/domain/daily.dart';
import 'package:featherlog/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a daily series starting 2026-01-01 from a list of kg values on
/// consecutive days.
List<DailyWeight> seriesFrom(List<double> kgs, {DateTime? start}) {
  final s = start ?? DateTime(2026, 1, 1);
  return [
    for (var i = 0; i < kgs.length; i++)
      DailyWeight(
        day: s.add(Duration(days: i)),
        weightKg: kgs[i],
      ),
  ];
}

void main() {
  group('movingAverage', () {
    test('empty -> empty', () {
      expect(movingAverage(const []), isEmpty);
    });

    test('first point equals itself; window grows', () {
      final s = seriesFrom([80, 82]);
      final ma = movingAverage(s, window: 7);
      expect(ma[0].weightKg, 80); // only itself in window
      expect(ma[1].weightKg, 81); // (80+82)/2
    });

    test('windows by date, not count (gaps drop out of the window)', () {
      // Two points 10 days apart: the second day's 7-day window excludes the
      // first, so its average is just itself.
      final s = [
        DailyWeight(day: DateTime(2026, 1, 1), weightKg: 80),
        DailyWeight(day: DateTime(2026, 1, 11), weightKg: 70),
      ];
      final ma = movingAverage(s, window: 7);
      expect(ma[1].weightKg, 70);
    });
  });

  group('totalChange / periodChange', () {
    test('total change is latest minus first', () {
      expect(totalChange(seriesFrom([80, 79, 78])), -2.0);
    });

    test('total change null with <2 points', () {
      expect(totalChange(seriesFrom([80])), isNull);
    });

    test('period change windows from the most recent day', () {
      // 10 days, 80..71; last 7 days => day4(76)..day9(71) => -5? check window.
      final s = seriesFrom(List.generate(10, (i) => 80.0 - i));
      // 7-day window ending on day 9 (value 71) starts day 3 (value 77).
      expect(periodChange(s, 7), 71 - 77);
    });

    test('period change null when only one point in window', () {
      final s = [
        DailyWeight(day: DateTime(2026, 1, 1), weightKg: 80),
        DailyWeight(day: DateTime(2026, 3, 1), weightKg: 78),
      ];
      expect(periodChange(s, 7), isNull);
    });
  });

  group('ratePerWeek', () {
    test('steady -1kg/day -> about -7 kg/week', () {
      final s = seriesFrom(List.generate(14, (i) => 90.0 - i));
      final rate = ratePerWeek(s)!;
      // Smoothing flattens the very start, but over 14 days it's close to -7.
      expect(rate, lessThan(-5));
      expect(rate, greaterThan(-7.5));
    });

    test('flat series -> ~0', () {
      final s = seriesFrom(List.filled(10, 80.0));
      expect(ratePerWeek(s)!, closeTo(0, 1e-9));
    });

    test('null with <2 points', () {
      expect(ratePerWeek(seriesFrom([80])), isNull);
    });

    test('uses the recent window, not full history (issue #34)', () {
      // 60 days: gained for the first 40 (80 -> 100), then losing for the last
      // 20 (100 -> 90). Full-history slope is positive; the recent 30-day rate
      // must be negative so the projection points the right way.
      final kgs = <double>[
        for (var i = 0; i < 40; i++) 80.0 + (20 * i / 39),
        for (var i = 1; i <= 20; i++) 100.0 - (10 * i / 20),
      ];
      final s = seriesFrom(kgs);
      final rate = ratePerWeek(s)!; // default 30-day window
      expect(rate, lessThan(0), reason: 'recent trend is downward');

      // And a projection toward a lower goal is now meaningful.
      final weeks = projectionWeeks(
        currentKg: s.last.weightKg,
        goalKg: 85,
        ratePerWeek: rate,
      );
      expect(weeks, isNotNull);
      expect(weeks, greaterThan(0));
    });

    test('respects a custom recentDays window', () {
      final s = seriesFrom(List.generate(60, (i) => 90.0 - i * 0.1));
      // Both windows are downward here; just assert it computes without error
      // and stays negative for a steady decline.
      expect(ratePerWeek(s, recentDays: 14)!, lessThan(0));
      expect(ratePerWeek(s, recentDays: 30)!, lessThan(0));
    });
  });

  group('projectionWeeks', () {
    test('losing toward a lower goal gives positive weeks', () {
      final weeks = projectionWeeks(
        currentKg: 80,
        goalKg: 75,
        ratePerWeek: -0.5,
      );
      expect(weeks, closeTo(10, 1e-9)); // (75-80)/-0.5 = 10
    });

    test('suppressed when rate is ~0', () {
      expect(
        projectionWeeks(currentKg: 80, goalKg: 75, ratePerWeek: 0.0),
        isNull,
      );
    });

    test('suppressed when trending away from goal', () {
      // Goal is below current (need to lose) but gaining.
      expect(
        projectionWeeks(currentKg: 80, goalKg: 75, ratePerWeek: 0.4),
        isNull,
      );
    });

    test('suppressed when already at goal', () {
      expect(
        projectionWeeks(currentKg: 75, goalKg: 75, ratePerWeek: -0.5),
        isNull,
      );
    });

    test('null rate -> null', () {
      expect(
        projectionWeeks(currentKg: 80, goalKg: 75, ratePerWeek: null),
        isNull,
      );
    });
  });

  group('min/max/average', () {
    test('computes extremes and mean', () {
      final s = seriesFrom([80, 78, 82]);
      expect(minWeight(s), 78);
      expect(maxWeight(s), 82);
      expect(averageWeight(s), 80);
    });

    test('null on empty', () {
      expect(minWeight(const []), isNull);
      expect(maxWeight(const []), isNull);
      expect(averageWeight(const []), isNull);
    });
  });
}
