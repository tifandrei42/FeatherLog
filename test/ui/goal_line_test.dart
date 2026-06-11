import 'package:featherlog/domain/daily.dart';
import 'package:featherlog/domain/units.dart';
import 'package:featherlog/ui/widgets/weight_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  final daily = [
    DailyWeight(day: DateTime(2026, 5, 27), weightKg: 81.0),
    DailyWeight(day: DateTime(2026, 5, 28), weightKg: 80.5),
    DailyWeight(day: DateTime(2026, 5, 29), weightKg: 80.0),
  ];

  LineChartData dataOf(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data;

  testWidgets('no goal → no horizontal line', (tester) async {
    await tester.pumpWidget(
      host(WeightChart(daily: daily, unit: WeightUnit.kg)),
    );
    expect(dataOf(tester).extraLinesData.horizontalLines, isEmpty);
  });

  testWidgets('goal → one horizontal line at the goal value', (tester) async {
    await tester.pumpWidget(
      host(WeightChart(daily: daily, unit: WeightUnit.kg, goalKg: 75.0)),
    );
    final lines = dataOf(tester).extraLinesData.horizontalLines;
    expect(lines, hasLength(1));
    expect(lines.single.y, 75.0);
  });

  testWidgets('goal converts to display unit (kg → lb)', (tester) async {
    await tester.pumpWidget(
      host(WeightChart(daily: daily, unit: WeightUnit.lb, goalKg: 75.0)),
    );
    final lines = dataOf(tester).extraLinesData.horizontalLines;
    // 75 kg ≈ 165.3 lb
    expect(lines.single.y, closeTo(165.3, 0.2));
  });

  testWidgets('reference line uses the provided label', (tester) async {
    // Trends passes the next-milestone target here with a 'Next' label.
    await tester.pumpWidget(
      host(
        WeightChart(
          daily: daily,
          unit: WeightUnit.kg,
          goalKg: 79.0,
          goalLabel: 'Next',
        ),
      ),
    );
    final line = dataOf(tester).extraLinesData.horizontalLines.single;
    expect(line.label.labelResolver(line), 'Next');
  });
}
