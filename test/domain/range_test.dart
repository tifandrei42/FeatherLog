import 'package:featherlog/domain/daily.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 10 consecutive days ending 2026-05-30.
  List<DailyWeight> series() => [
    for (var i = 0; i < 10; i++)
      DailyWeight(
        day: DateTime(2026, 5, 21).add(Duration(days: i)),
        weightKg: 80.0 + i,
      ),
  ];

  group('filterByRange', () {
    test('all returns the full series', () {
      final s = series();
      expect(filterByRange(s, ChartRange.all), s);
    });

    test('week keeps the last 7 days counting from the latest entry', () {
      final result = filterByRange(series(), ChartRange.week);
      expect(result, hasLength(7));
      expect(result.first.day, DateTime(2026, 5, 24)); // 30th - 6 days
      expect(result.last.day, DateTime(2026, 5, 30));
    });

    test('counts back from the most recent day, not "now"', () {
      // A series whose latest day is well in the past still yields its tail,
      // rather than an empty window.
      final old = [
        for (var i = 0; i < 5; i++)
          DailyWeight(
            day: DateTime(2020, 1, 1).add(Duration(days: i)),
            weightKg: 70.0,
          ),
      ];
      final result = filterByRange(old, ChartRange.week);
      expect(result, hasLength(5)); // all within 7 days of the last old day
    });

    test('range larger than the data returns everything', () {
      final s = series();
      expect(filterByRange(s, ChartRange.year), s);
    });

    test('empty input yields empty output', () {
      expect(filterByRange(<DailyWeight>[], ChartRange.month), isEmpty);
    });
  });
}
