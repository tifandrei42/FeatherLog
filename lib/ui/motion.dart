import 'package:flutter/widgets.dart';

/// Motion language (UI_DESIGN.md §5). One place to keep durations consistent
/// and — crucially — to honour the OS "reduce motion" setting everywhere.
class Motion {
  const Motion._();

  /// Taps, toggles, press feedback.
  static const micro = Duration(milliseconds: 120);

  /// Card / state transitions.
  static const standard = Duration(milliseconds: 240);

  /// Chart draw-in / range changes, count-up numbers.
  static const expressive = Duration(milliseconds: 420);
}

/// Returns [duration], or [Duration.zero] when the platform's reduce-motion
/// accessibility setting is on — so every animation falls back to an instant
/// (opacity-only / no-op) transition in one shared place rather than each
/// widget re-checking the flag. Safe to call with any [context] under a
/// [MediaQuery] (falls back to "motion on" if there isn't one).
Duration motionDuration(BuildContext context, Duration duration) {
  final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return reduce ? Duration.zero : duration;
}

/// Whether the OS asked us to reduce motion. Use to skip a movement entirely
/// (e.g. a press-scale) rather than just zeroing its duration.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;
