import 'package:featherlog/domain/daily.dart';
import 'package:featherlog/domain/units.dart';
import 'package:featherlog/ui/widgets/day_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows date, weight, BMI and change', (tester) async {
    await tester.pumpWidget(
      host(
        DayDetailCard(
          day: DailyWeight(day: DateTime(2026, 5, 28), weightKg: 80.0),
          previous: DailyWeight(day: DateTime(2026, 5, 27), weightKg: 81.0),
          unit: WeightUnit.kg,
          heightCm: 178.0,
          note: 'after run',
        ),
      ),
    );

    expect(find.textContaining('80.0 kg'), findsOneWidget);
    expect(find.text('after run'), findsOneWidget);
    // BMI for 80kg/178cm ~ 25.2; change is -1.0 kg (a loss).
    expect(find.textContaining('25.2'), findsOneWidget);
    expect(find.textContaining('−1.0 kg'), findsOneWidget);
  });

  testWidgets('omits BMI when height is unknown', (tester) async {
    await tester.pumpWidget(
      host(
        DayDetailCard(
          day: DailyWeight(day: DateTime(2026, 5, 28), weightKg: 80.0),
          previous: null,
          unit: WeightUnit.kg,
          heightCm: null,
        ),
      ),
    );

    expect(find.text('BMI'), findsNothing);
    // No previous day → no change metric.
    expect(find.text('CHANGE'), findsNothing);
  });
}
