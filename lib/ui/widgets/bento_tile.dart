import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme/tokens.dart';

/// A rounded "bento" surface tile — the building block of the Almanac's
/// mosaic layouts. Keeps the editorial hairline border and card radius so all
/// tiles read as one family, while allowing an optional [gradient]/[color] fill
/// for emphasis (e.g. the Today hero) and an optional [onTap] with a ripple.
///
/// When [onTap] is set, the tile gives a subtle press-scale for tactile
/// feedback (skipped under the OS reduce-motion setting).
class BentoTile extends StatefulWidget {
  const BentoTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.gradient,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  State<BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<BentoTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(Radii.lg);
    // Press-scale only when the tile is tappable and motion is allowed.
    final pressable = widget.onTap != null && !reduceMotion(context);

    final tile = Container(
      decoration: BoxDecoration(
        color: widget.gradient == null
            ? (widget.color ?? theme.colorScheme.surface)
            : null,
        gradient: widget.gradient,
        borderRadius: radius,
        border: Border.all(
          color: widget.borderColor ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: pressable
                ? (v) => setState(() => _pressed = v)
                : null,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    if (!pressable) return tile;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: Motion.micro,
      curve: Curves.easeOut,
      child: tile,
    );
  }
}
