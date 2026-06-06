import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/providers/database_provider.dart';
import 'package:featherlog/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    child: const MaterialApp(home: SettingsScreen()),
  );

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('empty input shows an inline error and does not save', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Goal weight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a value'), findsOneWidget);
    // Dialog stays open (Save button still present).
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final p = await db.profileDao.getOrCreateProfile();
    expect(p.goalWeightKg, isNull);

    await dispose(tester);
  });

  testWidgets('an absurd height is rejected with a message', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Height'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a realistic height'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final p = await db.profileDao.getOrCreateProfile();
    expect(p.heightCm, isNull);

    await dispose(tester);
  });

  testWidgets('a valid height clears any error and saves', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Height'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '178');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final p = await db.profileDao.getOrCreateProfile();
    expect(p.heightCm, 178.0);

    await dispose(tester);
  });
}
