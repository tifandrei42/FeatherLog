import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/providers/database_provider.dart';
import 'package:featherlog/ui/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The History view (issue #66): month-grouped browsable log with swipe-to-
/// delete + undo.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget harness() => ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: HistoryScreen()),
  );

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('groups entries by month, newest first', (tester) async {
    await db.weightEntryDao.addReading(
      measuredAt: DateTime(2026, 6, 10, 7),
      weightKg: 81.9,
    );
    await db.weightEntryDao.addReading(
      measuredAt: DateTime(2026, 6, 2, 7),
      weightKg: 82.2,
    );
    await db.weightEntryDao.addReading(
      measuredAt: DateTime(2026, 5, 20, 7),
      weightKg: 83.0,
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('JUNE 2026'), findsOneWidget);
    expect(find.text('MAY 2026'), findsOneWidget);
    expect(find.textContaining('81.9 kg'), findsOneWidget);
    expect(find.textContaining('83.0 kg'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('empty state when there are no entries', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('No entries yet'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('swipe-to-delete removes the row and offers undo', (
    tester,
  ) async {
    final id = await db.weightEntryDao.addReading(
      measuredAt: DateTime(2026, 6, 10, 7),
      weightKg: 81.9,
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.textContaining('81.9 kg'), findsOneWidget);

    // Swipe left (endToStart) to delete.
    await tester.drag(
      find.byKey(ValueKey('history-entry-$id')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entry deleted'), findsOneWidget);
    expect(find.textContaining('81.9 kg'), findsNothing);
    expect(await db.weightEntryDao.getAllEntries(), isEmpty);

    // Undo restores it.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('81.9 kg'), findsOneWidget);
    expect(await db.weightEntryDao.getAllEntries(), hasLength(1));

    await disposeTree(tester);
  });
}
