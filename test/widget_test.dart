import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/main.dart';
import 'package:featherlog/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // These tests cover the dashboard/logging flow, not first-run onboarding,
    // so mark onboarding done up front — otherwise the root gate would show the
    // onboarding screen on a fresh database.
    await db.settingsDao.setOnboardingDone(true);
  });

  tearDown(() async {
    await db.close();
  });

  Widget app() => ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const FeatherLogApp(),
  );

  // Tears down the widget tree so StreamProvider subscriptions (and drift's
  // backing timers) are cancelled before the test framework checks for pending
  // timers. Without this, drift's watch* streams leave a Timer pending.
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state with no entries', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.text('Log weight'), findsOneWidget); // the FAB

    await disposeTree(tester);
  });

  testWidgets('logging a weight shows it on the dashboard', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Open the add-entry sheet.
    await tester.tap(find.text('Log weight'));
    await tester.pumpAndSettle();

    // Enter a weight and save.
    await tester.enterText(find.byType(TextFormField).first, '80');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dashboard now shows the current weight and leaves the empty state.
    expect(find.text('No entries yet'), findsNothing);
    expect(find.textContaining('80.0 kg'), findsWidgets);

    await disposeTree(tester);
  });

  testWidgets('rejects an empty / invalid weight', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log weight'));
    await tester.pumpAndSettle();

    // Save with no input → validation message, sheet stays open.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a weight'), findsOneWidget);

    await disposeTree(tester);
  });
}
