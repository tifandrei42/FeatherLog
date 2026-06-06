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

  testWidgets('overlay off → a single line series', (tester) async {
    await tester.pumpWidget(
      host(
        WeightChart(
          daily: daily,
          unit: WeightUnit.kg,
          showMovingAverage: false,
        ),
      ),
    );
    expect(dataOf(tester).lineBarsData, hasLength(1));
  });

  testWidgets('overlay on with >=2 days → two line series', (tester) async {
    await tester.pumpWidget(
      host(
        WeightChart(daily: daily, unit: WeightUnit.kg, showMovingAverage: true),
      ),
    );
    expect(dataOf(tester).lineBarsData, hasLength(2));
  });

  testWidgets('default (unset) → overlay off, single series', (tester) async {
    await tester.pumpWidget(
      host(WeightChart(daily: daily, unit: WeightUnit.kg)),
    );
    expect(dataOf(tester).lineBarsData, hasLength(1));
  });
}
