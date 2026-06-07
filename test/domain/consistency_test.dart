import 'package:featherlog/domain/consistency.dart';
import 'package:featherlog/domain/daily.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed reference "today" so every test is deterministic.
final today = DateTime(2026, 6, 7);

/// Builds a daily series from day offsets relative to [today]. An offset of 0
/// is today, 1 is yesterday, etc. Weight values don't matter here, so a
/// constant is used. Repeating an offset (or passing [extraReadings]) lets a
/// test exercise "multiple readings on the same day".
List<DailyWeight> daysAgo(List<int> offsets, {double weightKg = 80.0}) {
  return [
    for (final o in offsets)
      DailyWeight(
        day: today.subtract(Duration(days: o)),
        weightKg: weightKg,
      ),
  ];
}

void main() {
  group('currentStreak', () {
    test('empty -> 0', () {
      expect(currentStreak(const [], today: today), 0);
    });

    test('single day logged today -> 1', () {
      expect(currentStreak(daysAgo([0]), today: today), 1);
    });

    test('logged today and yesterday -> 2', () {
      expect(currentStreak(daysAgo([0, 1]), today: today), 2);
    });

    test('grace lets logged-yesterday-not-today keep the streak', () {
      // Logged yesterday and the day before, nothing today yet.
      expect(currentStreak(daysAgo([1, 2]), today: today), 2);
    });

    test('newest log 3 days ago with graceDays:1 -> 0', () {
      expect(currentStreak(daysAgo([3, 4, 5]), today: today, graceDays: 1), 0);
    });

    test('a gap breaks the current streak (only the recent run counts)', () {
      // Today + yesterday are consecutive; then a gap before an older block.
      final daily = daysAgo([0, 1, 5, 6, 7]);
      expect(currentStreak(daily, today: today), 2);
    });

    test('multiple readings on the same day count once', () {
      // Two readings today, two yesterday -> streak of 2, not 4.
      final daily = [
        ...daysAgo([0], weightKg: 80.0),
        ...daysAgo([0], weightKg: 80.5),
        ...daysAgo([1], weightKg: 81.0),
        ...daysAgo([1], weightKg: 81.5),
      ];
      expect(currentStreak(daily, today: today), 2);
    });

    test('a wider grace window keeps an older streak alive', () {
      // Newest log 2 days ago: zeroed at default grace, alive at graceDays:2.
      final daily = daysAgo([2, 3]);
      expect(currentStreak(daily, today: today), 0);
      expect(currentStreak(daily, today: today, graceDays: 2), 2);
    });

    test('input order does not matter', () {
      final daily = daysAgo([2, 0, 1]);
      expect(currentStreak(daily, today: today), 3);
    });
  });

  group('longestStreak', () {
    test('empty -> 0', () {
      expect(longestStreak(const []), 0);
    });

    test('single day -> 1', () {
      expect(longestStreak(daysAgo([4])), 1);
    });

    test('reflects history even after the current streak is broken', () {
      // Current run is just today (1), but an older 4-day block exists.
      final daily = daysAgo([0, 5, 6, 7, 8]);
      expect(currentStreak(daily, today: today), 1);
      expect(longestStreak(daily), 4);
    });

    test('multiple readings on the same day count once', () {
      final daily = [
        ...daysAgo([10], weightKg: 80.0),
        ...daysAgo([10], weightKg: 80.5),
        ...daysAgo([11]),
        ...daysAgo([12]),
      ];
      expect(longestStreak(daily), 3);
    });
  });

  group('daysLoggedIn', () {
    test('empty -> 0', () {
      expect(daysLoggedIn(const [], today: today), 0);
    });

    test('counts distinct logged days inside the window', () {
      // 3 distinct days within the last 30.
      expect(daysLoggedIn(daysAgo([0, 2, 10]), today: today), 3);
    });

    test('ignores days outside the trailing window', () {
      // Two inside a 7-day window, one (10 days ago) outside it.
      expect(daysLoggedIn(daysAgo([0, 6, 10]), today: today, windowDays: 7), 2);
    });

    test('the window edge is inclusive', () {
      // 6 days ago is the first day of a 7-day window ending today.
      expect(daysLoggedIn(daysAgo([6]), today: today, windowDays: 7), 1);
    });

    test('multiple readings on the same day count once', () {
      final daily = [
        ...daysAgo([1], weightKg: 80.0),
        ...daysAgo([1], weightKg: 80.5),
      ];
      expect(daysLoggedIn(daily, today: today), 1);
    });
  });

  group('consistency', () {
    test('empty -> 0.0', () {
      expect(consistency(const [], today: today), 0.0);
    });

    test('fraction of the window with a log', () {
      // 3 logged days out of a 10-day window -> 0.3.
      final daily = daysAgo([0, 1, 2]);
      expect(consistency(daily, today: today, windowDays: 10), 0.3);
    });

    test('every day in the window logged -> 1.0', () {
      final daily = daysAgo([0, 1, 2, 3, 4, 5, 6]);
      expect(consistency(daily, today: today, windowDays: 7), 1.0);
    });

    test('logs outside the window do not inflate the fraction', () {
      // Only one of these falls inside a 7-day window.
      final daily = daysAgo([0, 20, 40]);
      expect(
        consistency(daily, today: today, windowDays: 7),
        closeTo(1 / 7, 1e-9),
      );
    });
  });
}
