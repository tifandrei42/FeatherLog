// Marketing-frame harness (NOT a regression test — no `_test` suffix so CI skips
// it). Reads the raw captures from build/screenshots/ (produced by
// capture_screens.dart) and composites each into a branded, captioned phone
// mockup, writing finished Play Store images to:
//   ../Documentation/store-assets/screenshots/
//
// Run after capture_screens.dart:
//   flutter test test/screenshots/frame_screens.dart --update-goldens
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

const _outDir = '../Documentation/store-assets/screenshots';

// (raw file, caption, yaw, pitch, roll) — yaw/pitch/roll in radians give each
// phone a distinct 3D tilt. Angles alternate left/right for visual rhythm.
const _shots = [
  ('01-today.png', 'Your weight, at a glance', -0.34, 0.06, 0.025),
  ('02-trends.png', 'See every trend', 0.34, 0.06, -0.025),
  ('03-body.png', 'Track body composition', -0.30, 0.05, 0.02),
  ('04-settings.png', 'Private. Yours to export.', 0.30, 0.05, -0.02),
];

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

Future<ui.Image> _decode(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}

/// One finished Play screenshot: brand gradient, caption, and the capture in a
/// rounded phone mockup. Sized to a 1080×1920 (9:16) canvas.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.shot,
    required this.caption,
    required this.yaw,
    required this.pitch,
    required this.roll,
  });

  final ui.Image shot;
  final String caption;
  final double yaw; // rotateY — left/right tilt
  final double pitch; // rotateX — forward/back tilt
  final double roll; // rotateZ — jaunty lean

  @override
  Widget build(BuildContext context) {
    // Screenshot drawn at a fixed on-canvas width so the tilted device fits the
    // canvas without a FittedBox (which can't account for the 3D paint).
    const contentW = 540.0;
    final contentH = contentW * shot.height / shot.width;

    final phone = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11161F),
        borderRadius: BorderRadius.circular(82),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.33),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(64),
        child: SizedBox(
          width: contentW,
          height: contentH,
          child: RawImage(image: shot, fit: BoxFit.cover),
        ),
      ),
    );

    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F6BED), Color(0xFF8AA6E0)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 96, 64, 72),
        child: Column(
          children: [
            Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 64,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0014) // perspective depth
                    ..rotateX(pitch)
                    ..rotateY(yaw)
                    ..rotateZ(roll),
                  child: phone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('frame store screenshots', (tester) async {
    Directory(_outDir).createSync(recursive: true);
    await tester.runAsync(loadAppFonts);

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final (raw, caption, yaw, pitch, roll) in _shots) {
      final bytes = File('build/screenshots/$raw').readAsBytesSync();
      final image = await tester.runAsync(() => _decode(bytes));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Frame(
            shot: image!,
            caption: caption,
            yaw: yaw,
            pitch: pitch,
            roll: roll,
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(_Frame),
        matchesGoldenFile('../../$_outDir/$raw'),
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
