import 'package:featherlog/domain/daily.dart';
import 'package:featherlog/domain/units.dart';
import 'package:featherlog/ui/widgets/weight_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders a LineChart for a multi-day series', (tester) async {
    final daily = [
      DailyWeight(day: DateTime(2026, 5, 27), weightKg: 81.0),
      DailyWeight(day: DateTime(2026, 5, 28), weightKg: 80.5),
      DailyWeight(day: DateTime(2026, 5, 29), weightKg: 80.0),
    ];
    await tester.pumpWidget(
      host(WeightChart(daily: daily, unit: WeightUnit.kg)),
    );
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('handles a single-day series without throwing', (tester) async {
    final daily = [DailyWeight(day: DateTime(2026, 5, 29), weightKg: 80.0)];
    await tester.pumpWidget(
      host(WeightChart(daily: daily, unit: WeightUnit.kg)),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
