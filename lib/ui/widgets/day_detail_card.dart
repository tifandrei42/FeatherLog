import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/bmi.dart';
import '../../domain/daily.dart';
import '../../domain/units.dart';

/// Detail card shown below the chart when a day is selected (DESIGN §3.1,
/// US-6.2). Shows the day's date, weight, BMI, change vs the previous day, and
/// note — richer than a floating tooltip, without obscuring the graph.
class DayDetailCard extends StatelessWidget {
  const DayDetailCard({
    super.key,
    required this.day,
    required this.previous,
    required this.unit,
    required this.heightCm,
    this.note,
    this.onClose,
  });

  final DailyWeight day;

  /// The previous day's aggregate (for the delta), or null if none.
  final DailyWeight? previous;
  final WeightUnit unit;
  final double? heightCm;
  final String? note;
  final VoidCallback? onClose;

  String get _unitLabel => unit == WeightUnit.lb ? 'lb' : 'kg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weight = weightFromKg(day.weightKg, unit);

    final deltaKg = previous == null ? null : day.weightKg - previous!.weightKg;
    final bmi = heightCm == null
        ? null
        : calculateBmi(weightKg: day.weightKg, heightCm: heightCm!);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMMEEEEd().format(day.day),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    tooltip: 'Clear selection',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Metric(
                  label: 'Weight',
                  value: '${weight.toStringAsFixed(1)} $_unitLabel',
                ),
                if (bmi != null)
                  _Metric(
                    label: 'BMI',
                    value:
                        '${bmi.toStringAsFixed(1)}  '
                        '${bmiCategoryFor(bmi).label}',
                  ),
                if (deltaKg != null)
                  _Metric(label: 'Change', value: _formatDelta(deltaKg)),
              ],
            ),
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDelta(double deltaKg) {
    final v = weightFromKg(deltaKg.abs(), unit);
    if (deltaKg.abs() < 0.05) return 'no change';
    final sign = deltaKg > 0 ? '+' : '−';
    return '$sign${v.toStringAsFixed(1)} $_unitLabel';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
