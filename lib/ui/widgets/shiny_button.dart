import 'package:flutter/material.dart';

/// A glossy pill action button: a vertical gradient fill (lighter at the top so
/// it reads as "lit"), a bright hairline rim for shine, a soft colored glow, an
/// ink ripple, and a subtle press-scale. Used for the primary actions (the
/// logging FAB and the Save buttons) to give them more polish than a flat fill.
class ShinyButton extends StatefulWidget {
  const ShinyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.expanded = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Base fill color; defaults to the theme primary.
  final Color? color;

  /// Stretch to the full available width (otherwise hugs its content).
  final bool expanded;

  @override
  State<ShinyButton> createState() => _ShinyButtonState();
}

class _ShinyButtonState extends State<ShinyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.color ?? scheme.primary;
    final top = Color.lerp(base, Colors.white, 0.24)!;
    final onColor =
        ThemeData.estimateBrightnessForColor(base) == Brightness.dark
        ? Colors.white
        : scheme.onSurface;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, base],
          ),
          // The "shine": a bright hairline rim catching imaginary light.
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: _pressed ? 0.25 : 0.45),
              blurRadius: _pressed ? 10 : 18,
              spreadRadius: -2,
              offset: Offset(0, _pressed ? 3 : 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisSize: widget.expanded
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: onColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: onColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
