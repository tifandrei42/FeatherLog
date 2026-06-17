// Screenshot-capture harness (NOT a regression test — filename intentionally
// omits the `_test` suffix so `flutter test` doesn't run it in CI). It renders
// the real app, seeded with realistic data, headlessly via Flutter's golden
// mechanism and writes PNGs under build/screenshots/ (phone) and
// build/screenshots/tablet/.
//
// Run each device profile in its OWN invocation: the drift stream keeps a timer
// alive after the goldens are written, so the test hangs until its timeout (a
// harmless cosmetic "failure"). Running both profiles in one invocation only
// reliably writes the first, so capture them separately:
//
//   flutter test test/screenshots/capture_screens.dart --update-goldens --plain-name "capture phone screenshots"
//   flutter test test/screenshots/capture_screens.dart --update-goldens --plain-name "capture tablet screenshots"
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:featherlog/data/database.dart';
import 'package:featherlog/dev/dev_tools.dart';
import 'package:featherlog/main.dart';
import 'package:featherlog/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads every bundled font (Nunito + MaterialIcons + Cupertino) from the test
/// asset bundle, so text and icons render properly instead of as tofu boxes.
Future<void> loadAppFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final entry in manifest) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in entry['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Seeds a realistic, attractive dataset into [db].
Future<void> _seedInto(AppDatabase db) async {
  await db.profileDao.updateHeight(178);
  await db.profileDao.updateGoalWeight(76);
  await db.profileDao.updateSex('male');
  await db.profileDao.updateBirthDate(DateTime(1992, 4, 12));

  final today = DateTime(2026, 6, 11, 7, 30);
  final start = today.subtract(const Duration(days: 60));
  for (var d = 0; d <= 60; d++) {
    if (d % 7 == 3) continue; // occasional gap
    final target = 86.0 - (8.0 * d / 60); // 86 -> 78
    final noise = ((d * 37) % 7 - 3) * 0.12; // deterministic +/- jitter
    final kg = double.parse((target + noise).toStringAsFixed(1));
    final at = DateTime(start.year, start.month, start.day + d, 7, 30);
    await db.weightEntryDao.addReading(measuredAt: at, weightKg: kg);
  }
  await db.weightEntryDao.addReading(
    measuredAt: today,
    weightKg: 78.2,
    bodyFatPct: 19.4,
    musclePct: 42.1,
    waterPct: 55.3,
  );
  for (final m in const [('waist', 84.0), ('chest', 100.0), ('hips', 96.0)]) {
    await db.bodyMeasurementDao.addMeasurement(
      measuredAt: today,
      type: m.$1,
      valueCm: m.$2,
    );
  }
}

/// Advances the clock enough to flush the (real-async) drift stream and finish
/// entry/chart animations, without pumpAndSettle (which can hang). The real
/// stream emission happens via [WidgetTester.runAsync]; pumps then render it.
Future<void> tick(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump(); // rebuild with emitted data
  await tester.pump(const Duration(seconds: 1)); // finish animations
}

/// Unmounts the tree so StreamProvider/drift subscriptions are cancelled before
/// the binding checks for pending work (mirrors widget_test's disposeTree).
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(FeatherLogApp),
    matchesGoldenFile('../../build/screenshots/$name.png'),
  );
}

/// Seeds a fresh db, renders the app at the given device profile, and captures
/// the four tab screens with [prefix] (e.g. '' for phone, 'tablet/' for tablet).
Future<void> _capture(
  WidgetTester tester, {
  required Size physical,
  required double dpr,
  required String prefix,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  // Real-async work (asset/font load + drift writes) must run via runAsync,
  // not in the test's fake-async zone where those futures never complete.
  await tester.runAsync(() async {
    await loadAppFonts();
    await _seedInto(db);
  });

  tester.view.physicalSize = physical;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const FeatherLogApp(),
    ),
  );
  await tick(tester);

  await _shot(tester, '${prefix}01-today');
  await tester.tap(find.text('Trends'));
  await tick(tester);
  await _shot(tester, '${prefix}02-trends');
  await tester.tap(find.text('Body'));
  await tick(tester);
  await _shot(tester, '${prefix}03-body');
  await tester.tap(find.text('Settings'));
  await tick(tester);
  await _shot(tester, '${prefix}04-settings');

  // Clean teardown: unmount, then close the db in the real async zone so
  // drift's stream/timers are disposed (avoids a hang at test end).
  await _disposeTree(tester);
  await tester.runAsync(() async => db.close());
}

// Phone and tablet are SEPARATE tests on purpose: each writes its goldens, then
// the drift stream's timer keeps the test alive until its timeout (a harmless
// teardown hang). As separate tests, the runner still moves on to the next one,
// so both device sets get written in a single `--update-goldens` run.
void main() {
  // Phone: 1170×2532 @3.0 → logical 390×844. Shots at build/screenshots/.
  testWidgets('capture phone screenshots', (tester) async {
    showDevTools = false;
    await _capture(
      tester,
      physical: const Size(1170, 2532),
      dpr: 3.0,
      prefix: '',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  // Tablet: 1640×2360 @2.0 → logical 820×1180. Sized to satisfy both the 7-inch
  // and 10-inch Play rules (each side within 1080–3840 px). Shots at
  // build/screenshots/tablet/.
  testWidgets('capture tablet screenshots', (tester) async {
    showDevTools = false;
    await _capture(
      tester,
      physical: const Size(1640, 2360),
      dpr: 2.0,
      prefix: 'tablet/',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
