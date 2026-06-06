import 'package:featherlog/domain/daily.dart';
import 'package:featherlog/domain/units.dart';
import 'package:featherlog/ui/widgets/stats_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a daily series starting 2026-01-01 from kg values on consecutive
/// days (oldest first).
List<DailyWeight> seriesFrom(List<double> kgs) {
  final start = DateTime(2026, 1, 1);
  return [
    for (var i = 0; i < kgs.length; i++)
      DailyWeight(
        day: start.add(Duration(days: i)),
        weightKg: kgs[i],
      ),
  ];
}

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders total change and weekly rate for a multi-day series', (
    tester,
  ) async {
    // A steady loss of 0.2 kg/day from 90.0 over 100 days, so the total change
    // (−19.8 kg) is distinct from any of the 7/30/90-day window changes.
    final daily = seriesFrom(List.generate(100, (i) => 90.0 - i * 0.2));
    await tester.pumpWidget(
      host(StatsPanel(daily: daily, unit: WeightUnit.kg, goalKg: null)),
    );

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Total change'), findsOneWidget);
    // 90.0 - 0.2*99 = 70.2 -> total change −19.8 kg.
    expect(find.text('−19.8 kg'), findsOneWidget);
    // Rate row present and showing a (negative) kg/week value.
    expect(find.text('Average rate'), findsOneWidget);
    expect(find.textContaining('kg/week'), findsOneWidget);
    expect(find.textContaining('−'), findsWidgets);
  });

  testWidgets('shows projection row when a lower goal makes it meaningful', (
    tester,
  ) async {
    // Losing weight toward a lower goal -> trend points at the goal.
    final daily = seriesFrom(List.generate(20, (i) => 90.0 - i * 0.3));
    await tester.pumpWidget(
      host(StatsPanel(daily: daily, unit: WeightUnit.kg, goalKg: 80.0)),
    );

    expect(find.text('To goal'), findsOneWidget);
    expect(find.textContaining('weeks at this rate'), findsOneWidget);
  });

  testWidgets('hides projection when no goal is set', (tester) async {
    final daily = seriesFrom(List.generate(20, (i) => 90.0 - i * 0.3));
    await tester.pumpWidget(
      host(StatsPanel(daily: daily, unit: WeightUnit.kg, goalKg: null)),
    );

    expect(find.text('To goal'), findsNothing);
    expect(find.textContaining('weeks at this rate'), findsNothing);
  });

  testWidgets('hides projection when the trend moves away from the goal', (
    tester,
  ) async {
    // Gaining weight, but the goal is lower -> projection is not meaningful.
    final daily = seriesFrom(List.generate(20, (i) => 80.0 + i * 0.3));
    await tester.pumpWidget(
      host(StatsPanel(daily: daily, unit: WeightUnit.kg, goalKg: 75.0)),
    );

    expect(find.text('To goal'), findsNothing);
  });

  testWidgets('shows a gentle message for a single data point', (tester) async {
    final daily = seriesFrom([80.0]);
    await tester.pumpWidget(
      host(StatsPanel(daily: daily, unit: WeightUnit.kg, goalKg: null)),
    );

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.textContaining('Log a few more days'), findsOneWidget);
    expect(find.text('Total change'), findsNothing);
  });
}
