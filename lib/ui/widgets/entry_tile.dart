import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/bmi.dart';
import '../../domain/units.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'delta_pill.dart';

/// One weight-reading row, shared by the Trends "Recent" list and the History
/// screen so the two read as one family: a BMI category dot (when height is
/// known), the weight, a date/time (+ BMI) meta line, an optional note, and a
/// "since the previous log" delta pill.
///
/// [framed] wraps the row in a bordered, rounded card (History); unframed it's a
/// bare row meant to sit inside a grouped surface that supplies its own
/// dividers (Trends "Recent"). [dateFormat] defaults to `MMMd` ("Jun 10");
/// History passes `MMMEd` to include the weekday.
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.previous,
    required this.unit,
    this.heightCm,
    this.dateFormat,
    this.framed = false,
    this.onTap,
  });

  final WeightEntry entry;

  /// The previous (older) reading, used for the delta. Null only for the very
  /// first entry in history.
  final WeightEntry? previous;
  final WeightUnit unit;

  /// Height in cm, when known, enables the per-row BMI dot + value.
  final double? heightCm;

  /// Date format for the meta line; defaults to `DateFormat.MMMd()`.
  final DateFormat? dateFormat;

  /// Wrap in a bordered, rounded card (History) vs. a bare row (Trends Recent).
  final bool framed;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<FeatherPalette>();
    final v = weightFromKg(entry.weightKg, unit);
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';

    final bmi = (heightCm != null && heightCm! > 0)
        ? calculateBmi(weightKg: entry.weightKg, heightCm: heightCm!)
        : null;
    final bmiColor = bmi == null
        ? null
        : (palette?.forBmiCategory(bmiCategoryFor(bmi)) ??
              theme.colorScheme.primary);

    final deltaKg = previous == null
        ? null
        : entry.weightKg - previous!.weightKg;

    final fmt = dateFormat ?? DateFormat.MMMd();
    final meta = StringBuffer()
      ..write(fmt.format(entry.measuredAt))
      ..write(' · ')
      ..write(DateFormat.Hm().format(entry.measuredAt));
    if (bmi != null) meta.write(' · BMI ${bmi.toStringAsFixed(1)}');

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (bmiColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: bmiColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${v.toStringAsFixed(1)} $unitLabel',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  meta.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (deltaKg != null)
            DeltaPill(deltaKg: deltaKg, unit: unit, dense: true),
        ],
      ),
    );

    if (!framed) {
      return InkWell(onTap: onTap, child: row);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}
