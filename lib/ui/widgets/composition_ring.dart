import 'package:flutter/material.dart';

/// A donut gauge for a body-composition percentage (fat / muscle / water).
/// The ring fills to [value]% in the metric's [color], with the figure in the
/// centre and a [label] beneath. A null [value] shows an empty track and "—".
class CompositionRing extends StatelessWidget {
  const CompositionRing({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.size = 76,
  });

  final String label;

  /// Percentage 0–100, or null when not logged.
  final double? value;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = value == null ? 0.0 : (value!.clamp(0, 100) / 100);

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: target),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              Text(
                value == null ? '—' : '${value!.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: value == null
                      ? theme.colorScheme.onSurfaceVariant
                      : color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
