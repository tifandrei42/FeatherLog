import 'package:featherlog/domain/daily.dart';
import 'package:featherlog/domain/units.dart';
import 'package:featherlog/ui/motion.dart';
import 'package:featherlog/ui/widgets/weight_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Motion pack (issue #69) — verifies the mechanics that CAN be checked
/// headless: reduce-motion zeroes durations everywhere, and the chart honours
/// it. (The actual feel needs a device.)
void main() {
  Duration? captured;

  Widget probe({required bool reduceMotion}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Builder(
      builder: (context) {
        captured = motionDuration(context, Motion.expressive);
        return const SizedBox();
      },
    ),
  );

  testWidgets('motionDuration passes the duration through normally', (
    tester,
  ) async {
    await tester.pumpWidget(probe(reduceMotion: false));
    expect(captured, Motion.expressive);
  });

  testWidgets('motionDuration collapses to zero under reduce-motion', (
    tester,
  ) async {
    await tester.pumpWidget(probe(reduceMotion: true));
    expect(captured, Duration.zero);
  });

  final daily = [
    DailyWeight(day: DateTime(2026, 5, 27), weightKg: 81.0),
    DailyWeight(day: DateTime(2026, 5, 28), weightKg: 80.5),
    DailyWeight(day: DateTime(2026, 5, 29), weightKg: 80.0),
  ];

  Duration chartDuration(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).duration;

  testWidgets('chart animates normally, instant under reduce-motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeightChart(daily: daily, unit: WeightUnit.kg),
        ),
      ),
    );
    expect(chartDuration(tester), Motion.expressive);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: WeightChart(daily: daily, unit: WeightUnit.kg),
          ),
        ),
      ),
    );
    expect(chartDuration(tester), Duration.zero);
  });
}
