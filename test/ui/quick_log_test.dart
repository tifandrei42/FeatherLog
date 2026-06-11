import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/main.dart';
import 'package:featherlog/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quick-log stepper sheet (issue #67): the add-entry sheet pre-fills the last
/// weight and offers +/- steppers so a typical log is a couple of taps.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.settingsDao.setOnboardingDone(true); // skip first-run gate
  });

  tearDown(() async {
    await db.close();
  });

  Widget app() => ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const FeatherLogApp(),
  );

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('pre-fills the last weight and steppers adjust it', (
    tester,
  ) async {
    await db.weightEntryDao.addReading(
      measuredAt: DateTime(2026, 6, 10, 7),
      weightKg: 80.0,
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Open the add-entry sheet from the FAB.
    await tester.tap(find.text('Log weight'));
    await tester.pumpAndSettle();

    // Field is pre-filled with the most recent weight.
    expect(find.widgetWithText(TextFormField, '80'), findsOneWidget);

    // Tapping "+" nudges by 0.1.
    await tester.tap(find.bySemanticsLabel('Increase weight'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '80.1'), findsOneWidget);

    // Tapping "-" twice goes back below the start.
    await tester.tap(find.bySemanticsLabel('Decrease weight'));
    await tester.tap(find.bySemanticsLabel('Decrease weight'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '79.9'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('first-ever log opens with an empty weight field', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log weight'));
    await tester.pumpAndSettle();

    // No prior reading → nothing to pre-fill; the field stays empty and
    // validation still guards an empty save.
    expect(find.widgetWithText(TextFormField, '80'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a weight'), findsOneWidget);

    await disposeTree(tester);
  });
}
