import 'package:flutter/material.dart';

import '../../domain/units.dart';
import '../theme/app_theme.dart';

/// A small aktiBMI-style "delta pill": a coloured, rounded chip showing a weight
/// change with a direction arrow (e.g. "↘ 0.4 kg").
///
/// Colours follow the chosen palette and the app's non-punitive framing: a loss
/// reads in the [FeatherPalette.positive] sage, a gain in the accent, and a
/// near-zero change is shown neutrally as "no change". [deltaKg] is the signed
/// change in canonical kilograms (positive = gained); display respects [unit].
class DeltaPill extends StatelessWidget {
  const DeltaPill({
    super.key,
    required this.deltaKg,
    required this.unit,
    this.dense = false,
  });

  /// Signed change in kilograms (current − previous). Positive means gained.
  final double deltaKg;

  /// Display unit for the magnitude.
  final WeightUnit unit;

  /// Tighter padding / smaller text for use inside dense list rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<FeatherPalette>();
    final up = deltaKg > 0;
    final flat = deltaKg.abs() < 0.05;
    final icon = flat
        ? Icons.trending_flat
        : (up ? Icons.north_east : Icons.south_east);
    final color = flat
        ? theme.colorScheme.onSurfaceVariant
        : (up
              ? theme.colorScheme.tertiary
              : (palette?.positive ?? Colors.green));
    final display = weightFromKg(deltaKg.abs(), unit).toStringAsFixed(1);
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';
    final textStyle =
        (dense ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
            ?.copyWith(color: color, fontWeight: FontWeight.w700);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: dense ? 14 : 16),
          const SizedBox(width: 4),
          Text(flat ? 'no change' : '$display $unitLabel', style: textStyle),
        ],
      ),
    );
  }
}
