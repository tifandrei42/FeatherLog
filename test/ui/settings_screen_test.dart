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

  testWidgets('renders the setting groups', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('UNITS'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Goal weight'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Height').first, findsOneWidget);

    await dispose(tester);
  });

  testWidgets('changing weight unit persists to the DB', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();

    final s = await db.settingsDao.getOrCreateSettings();
    expect(s.weightUnit, 'lb');

    await dispose(tester);
  });

  testWidgets('setting a goal weight persists to the profile', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Goal weight'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '75');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final p = await db.profileDao.getOrCreateProfile();
    expect(p.goalWeightKg, 75.0);

    await dispose(tester);
  });
}
