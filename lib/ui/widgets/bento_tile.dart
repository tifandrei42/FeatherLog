import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A rounded "bento" surface tile — the building block of the Almanac's
/// mosaic layouts. Keeps the editorial hairline border and card radius so all
/// tiles read as one family, while allowing an optional [gradient]/[color] fill
/// for emphasis (e.g. the Today hero) and an optional [onTap] with a ripple.
class BentoTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(Radii.lg);
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? theme.colorScheme.surface) : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
