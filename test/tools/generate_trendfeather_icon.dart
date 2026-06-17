import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One-off generator for the "Trendfeather" launcher icon — the feather whose
/// shaft IS a descending trend line ending in a data point (design pack concept
/// A). Ported directly from
/// Documentation/Improvement-Pack/logos/app-icon-trendfeather.svg to a Flutter
/// [Canvas] so we don't need an external SVG rasterizer.
///
/// Not part of the test suite (filename has no `_test` suffix, so `flutter test`
/// skips it). Run explicitly to (re)generate the PNG:
///   flutter test test/tools/generate_trendfeather_icon.dart
const _size = 1024.0;

/// Paints the full-bleed brand gradient.
void _drawBackground(Canvas canvas) {
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, _size, _size),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(_size, _size),
        const [Color(0xFF3FB465), Color(0xFF1F7E44)],
      ),
  );
}

/// Paints the feather mark (vane + barbs + trend-line shaft + data dot). Ported
/// from the SVG's `translate(512,512) scale(3.4)` group.
void _drawFeather(Canvas canvas) {
  canvas.save();
  canvas.translate(512, 512);
  canvas.scale(3.4);

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

Future<void> _writePng(String path, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _size, _size));
  paint(canvas);
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  test('write the Trendfeather icon PNGs', () async {
    // Full icon (legacy launcher + web): gradient + feather.
    await _writePng('assets/icon/featherlog-trendfeather-1024.png', (c) {
      _drawBackground(c);
      _drawFeather(c);
    });
    // Adaptive-icon layers (Android): gradient background + feather foreground
    // on transparent, so launchers can mask/parallax them independently.
    await _writePng('assets/icon/featherlog-trendfeather-bg-1024.png', (c) {
      _drawBackground(c);
    });
    await _writePng('assets/icon/featherlog-trendfeather-fg-1024.png', (c) {
      _drawFeather(c);
    });

    expect(
      File('assets/icon/featherlog-trendfeather-1024.png').existsSync(),
      isTrue,
    );
  });
}
