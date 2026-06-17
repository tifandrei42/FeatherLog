import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// One-off generator for the Play Store graphic assets (local-only output under
/// ../Documentation/store-assets/): the 512² hi-res icon and the 1024×500
/// feature graphic. Reuses the Trendfeather mark; loads Nunito so the wordmark
/// renders properly. Not part of the suite (no `_test` suffix). Run with:
///   flutter test test/tools/generate_store_assets.dart
Future<void> _loadFonts() async {
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

void _drawBackground(Canvas canvas, Size size) {
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [Color(0xFF3FB465), Color(0xFF1F7E44)],
      ),
  );
}

/// The feather mark centred at [cx],[cy] at [scale] (SVG units; the icon uses
/// scale 3.4 on a 1024 canvas).
void _drawFeather(Canvas canvas, double cx, double cy, double scale) {
  canvas.save();
  canvas.translate(cx, cy);
  canvas.scale(scale);

  final vane = Path()
    ..moveTo(-62, 58)
    ..cubicTo(-50, -10, 8, -68, 74, -76)
    ..cubicTo(66, -28, 28, 24, -34, 48)
    ..close();
  canvas.drawPath(
    vane,
    Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.97),
  );

  final barbs = Path()
    ..moveTo(-22, 28)
    ..lineTo(-6, 36)
    ..moveTo(4, 0)
    ..lineTo(22, 9)
    ..moveTo(28, -26)
    ..lineTo(46, -18);
  canvas.drawPath(
    barbs,
    Paint()
      ..color = const Color(0xFF2E9E54).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round,
  );

  final trend = Path()
    ..moveTo(-62, 58)
    ..lineTo(-20, 26)
    ..lineTo(4, 38)
    ..lineTo(36, 8)
    ..lineTo(58, 16)
    ..lineTo(74, -4);
  canvas.drawPath(
    trend,
    Paint()
      ..color = const Color(0xFF16341F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  canvas.drawCircle(
    const Offset(74, -4),
    11,
    Paint()..color = const Color(0xFF16341F),
  );
  canvas.drawCircle(
    const Offset(74, -4),
    5,
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.restore();
}

void _text(
  Canvas canvas,
  String text,
  Offset at, {
  required double fontSize,
  required FontWeight weight,
  Color color = const Color(0xFFFFFFFF),
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, at);
}

Future<void> _writePng(
  String path,
  int w,
  int h,
  void Function(Canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );
  paint(canvas);
  final image = await recorder.endRecording().toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..parent.createSync(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  // rootBundle (font loading) needs the services binding initialised.
  TestWidgetsFlutterBinding.ensureInitialized();
  const dir = '../Documentation/store-assets';

  test('write store icon + feature graphic', () async {
    await _loadFonts();

    // 512² hi-res store icon (full-bleed, same mark as the launcher icon).
    await _writePng('$dir/featherlog-icon-512.png', 512, 512, (c) {
      _drawBackground(c, const Size(512, 512));
      _drawFeather(c, 256, 256, 1.7); // half of the 1024/3.4 mapping
    });

    // 1024×500 feature graphic: feather on the left, wordmark + tagline.
    await _writePng('$dir/featherlog-feature-1024x500.png', 1024, 500, (c) {
      _drawBackground(c, const Size(1024, 500));
      _drawFeather(c, 200, 250, 2.1);
      _text(
        c,
        'featherlog',
        const Offset(380, 150),
        fontSize: 104,
        weight: FontWeight.w800,
      );
      _text(
        c,
        'Private weight & BMI tracker.',
        const Offset(384, 280),
        fontSize: 34,
        weight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
      );
      _text(
        c,
        'Your data stays on your device.',
        const Offset(384, 322),
        fontSize: 34,
        weight: FontWeight.w600,
        color: const Color(0xCCFFFFFF),
      );
    });

    expect(File('$dir/featherlog-feature-1024x500.png').existsSync(), isTrue);
  });
}
