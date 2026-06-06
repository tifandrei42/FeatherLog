import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/bmi.dart';
import '../domain/daily.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import 'add_entry_sheet.dart';
import 'widgets/stat_card.dart';
import 'widgets/weight_chart.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final settings = ref.watch(settingsProvider).value;
    final profile = ref.watch(profileProvider).value;
    final weightUnit = settings?.weightUnit == 'lb'
        ? WeightUnit.lb
        : WeightUnit.kg;

    return Scaffold(
      appBar: AppBar(title: const Text('FeatherLog')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddEntrySheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong:\n$e')),
        data: (entries) {
          if (entries.isEmpty) return const _EmptyState();
          return _Dashboard(
            entries: entries,
            unit: weightUnit,
            heightCm: profile?.heightCm,
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No entries yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap “Log weight” to record your first measurement.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.entries,
    required this.unit,
    required this.heightCm,
  });

  /// Newest first (as provided by entriesProvider).
  final List<WeightEntry> entries;
  final WeightUnit unit;
  final double? heightCm;

  String get _unitLabel => unit == WeightUnit.lb ? 'lb' : 'kg';

  String _fmtWeight(double kg) {
    final v = weightFromKg(kg, unit);
    return '${v.toStringAsFixed(1)} $_unitLabel';
  }

  @override
  Widget build(BuildContext context) {
    // Aggregate raw readings to one value per day; current weight, BMI and the
    // trend all use the smoothed daily series, not individual readings.
    final daily = dailyAverages(
      entries.map(
        (e) => Reading(measuredAt: e.measuredAt, weightKg: e.weightKg),
      ),
    );
    final today = daily.last; // entries is non-empty here
    final yesterday = daily.length > 1 ? daily[daily.length - 2] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        StatCard(
          label: 'Current weight',
          value: _fmtWeight(today.weightKg),
          sublabel: DateFormat.yMMMMd().format(today.day),
          trailing: yesterday == null
              ? null
              : _TrendArrow(
                  deltaKg: today.weightKg - yesterday.weightKg,
                  unit: unit,
                ),
        ),
        const SizedBox(height: 8),
        _bmiCard(context, today.weightKg),
        if (daily.length >= 2) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: WeightChart(daily: daily, unit: unit),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...entries.take(10).map((e) => _EntryTile(entry: e, unit: unit)),
      ],
    );
  }

  Widget _bmiCard(BuildContext context, double currentKg) {
    if (heightCm == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.straighten),
          title: const Text('Set your height for BMI'),
          subtitle: const Text('Add height in Settings to see your BMI.'),
        ),
      );
    }
    final bmi = calculateBmi(weightKg: currentKg, heightCm: heightCm!);
    return StatCard(
      label: 'BMI',
      value: bmi.toStringAsFixed(1),
      sublabel: bmiCategoryFor(bmi).label,
    );
  }
}

class _TrendArrow extends StatelessWidget {
  const _TrendArrow({required this.deltaKg, required this.unit});

  final double deltaKg;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final up = deltaKg > 0;
    final flat = deltaKg.abs() < 0.05;
    final icon = flat
        ? Icons.trending_flat
        : (up ? Icons.north_east : Icons.south_east);
    final color = flat
        ? theme.colorScheme.onSurfaceVariant
        : (up ? Colors.orange : Colors.green);
    final deltaDisplay = (weightFromKg(deltaKg.abs(), unit)).toStringAsFixed(1);
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 4),
        Text(
          flat ? '—' : '$deltaDisplay $unitLabel',
          style: theme.textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.unit});

  final WeightEntry entry;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final v = weightFromKg(entry.weightKg, unit);
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';
    return ListTile(
      dense: true,
      title: Text('${v.toStringAsFixed(1)} $unitLabel'),
      subtitle: entry.note == null ? null : Text(entry.note!),
      trailing: Text(
        '${DateFormat.MMMd().format(entry.measuredAt)}\n'
        '${DateFormat.Hm().format(entry.measuredAt)}',
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => showAddEntrySheet(context, existing: entry),
    );
  }
}
