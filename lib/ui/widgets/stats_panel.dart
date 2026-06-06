import 'package:flutter/material.dart';

import '../../domain/daily.dart';
import '../../domain/stats.dart';
import '../../domain/units.dart';

/// A calm, non-punitive summary of trends derived from the daily series
/// (US-6.x). Shows total/period changes, the weekly rate, an optional goal
/// projection, and the series min/max/average. All weights are converted to the
/// display [unit]; nulls are shown as "—" or omitted so nothing misleads.
class StatsPanel extends StatelessWidget {
  const StatsPanel({
    super.key,
    required this.daily,
    required this.unit,
    required this.goalKg,
  });

  /// Oldest-first daily-aggregated series.
  final List<DailyWeight> daily;
  final WeightUnit unit;

  /// Canonical goal weight (kg), or null if unset.
  final double? goalKg;

  String get _unitLabel => unit == WeightUnit.lb ? 'lb' : 'kg';

  /// Absolute weight (e.g. min/max/average), or "—" when null.
  String _fmtWeight(double? kg) {
    if (kg == null) return '—';
    final v = weightFromKg(kg, unit);
    return '${v.toStringAsFixed(1)} $_unitLabel';
  }

  /// A signed change (e.g. "+0.4 kg" / "−1.2 kg"), "no change" near zero, or
  /// "—" when null.
  String _fmtChange(double? kg) {
    if (kg == null) return '—';
    if (kg.abs() < 0.05) return 'no change';
    final v = weightFromKg(kg.abs(), unit);
    final sign = kg > 0 ? '+' : '−';
    return '$sign${v.toStringAsFixed(1)} $_unitLabel';
  }

  /// A signed weekly rate (e.g. "−0.4 kg/week"), or "—" when null.
  String _fmtRate(double? kgPerWeek) {
    if (kgPerWeek == null) return '—';
    if (kgPerWeek.abs() < 0.05) return 'holding steady';
    final v = weightFromKg(kgPerWeek.abs(), unit);
    final sign = kgPerWeek > 0 ? '+' : '−';
    return '$sign${v.toStringAsFixed(1)} $_unitLabel/week';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (daily.length < 2)
              Text(
                'Log a few more days to see your stats.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ..._statRows(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _statRows(BuildContext context) {
    final rate = ratePerWeek(daily);
    final current = daily.last.weightKg;
    final projection = goalKg == null
        ? null
        : projectionWeeks(
            currentKg: current,
            goalKg: goalKg!,
            ratePerWeek: rate,
          );

    return [
      _StatRow(label: 'Total change', value: _fmtChange(totalChange(daily))),
      _StatRow(label: 'Last 7 days', value: _fmtChange(periodChange(daily, 7))),
      _StatRow(
        label: 'Last 30 days',
        value: _fmtChange(periodChange(daily, 30)),
      ),
      _StatRow(
        label: 'Last 90 days',
        value: _fmtChange(periodChange(daily, 90)),
      ),
      _StatRow(label: 'Average rate', value: _fmtRate(rate)),
      // Only show a projection when it's actually meaningful (goal set and a
      // trend pointing toward it); never imply a guarantee.
      if (projection != null)
        _StatRow(
          label: 'To goal',
          value: '~${projection.round()} weeks at this rate',
        ),
      const Divider(height: 24),
      _StatRow(label: 'Lowest', value: _fmtWeight(minWeight(daily))),
      _StatRow(label: 'Highest', value: _fmtWeight(maxWeight(daily))),
      _StatRow(label: 'Average', value: _fmtWeight(averageWeight(daily))),
    ];
  }
}

/// A single label/value line, label muted on the left, value emphasised on the
/// right so the column reads like a tidy table.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
