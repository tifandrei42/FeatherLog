import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/main.dart';
import 'package:featherlog/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// First-run onboarding gate (issue #65). The root gate shows onboarding only
/// when it hasn't been completed AND there's no existing history.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
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

  testWidgets('a fresh install lands on onboarding', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Travel light.'), findsOneWidget);
    expect(find.text('No entries yet'), findsNothing); // not the dashboard yet

    await disposeTree(tester);
  });

  testWidgets('skipping completes onboarding and reveals the app', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip — just let me log'));
    await tester.pumpAndSettle();

    // Gate flips to the dashboard, and the flag is persisted so it won't return.
    expect(find.text('No entries yet'), findsOneWidget);
    final settings = await db.settingsDao.getOrCreateSettings();
    expect(settings.onboardingDone, isTrue);

    await disposeTree(tester);
  });

  testWidgets('a user with existing history never sees onboarding', (
    tester,
  ) async {
    // onboardingDone defaults to false (new v7 column), but real history means
    // this is an existing user, not a first run — they go straight to the app.
    await db.weightEntryDao.addReading(
      measuredAt: DateTime(2026, 5, 28, 8),
      weightKg: 80.0,
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Travel light.'), findsNothing);
    expect(find.textContaining('80.0 kg'), findsWidgets);

    await disposeTree(tester);
  });

  testWidgets('height entered during onboarding persists to the profile', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Step 1 → 2.
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Step 2: enter height (kg·cm is the default unit). The height field is the
    // first text field on this step.
    await tester.enterText(find.byType(TextField).first, '180');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3 → finish.
    await tester.tap(find.text('Start logging'));
    await tester.pumpAndSettle();

    final profile = await db.profileDao.getOrCreateProfile();
    expect(profile.heightCm, 180.0);
    final settings = await db.settingsDao.getOrCreateSettings();
    expect(settings.onboardingDone, isTrue);

    await disposeTree(tester);
  });
}
