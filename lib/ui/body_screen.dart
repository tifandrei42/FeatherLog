import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import 'add_measurement_sheet.dart';
import 'widgets/bento_tile.dart';
import 'widgets/composition_ring.dart';
import 'widgets/section_header.dart';

/// The Body tab: body composition (fat/muscle/water %, captured with a weigh-in)
/// and body measurements (waist, chest, … each with its own history). Both are
/// free in FeatherLog. Logging is via the contextual FAB in the shell.
class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final lengthUnit = settings?.lengthUnit == 'in'
        ? LengthUnit.inch
        : LengthUnit.cm;
    final entries = ref.watch(entriesProvider).value ?? const <WeightEntry>[];
    final measurementsAsync = ref.watch(measurementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Body')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const SectionHeader('Composition'),
          _Composition(entries: entries),
          const SizedBox(height: 28),
          const SectionHeader('Measurements'),
          measurementsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => const Text("Couldn't load measurements"),
            data: (list) => _Measurements(measurements: list, unit: lengthUnit),
          ),
        ],
      ),
    );
  }
}

class _Composition extends StatelessWidget {
  const _Composition({required this.entries});

  final List<WeightEntry> entries;

  /// Latest non-null value of [select] across the (newest-first) entries.
  double? _latest(double? Function(WeightEntry) select) {
    for (final e in entries) {
      final v = select(e);
      if (v != null) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fat = _latest((e) => e.bodyFatPct);
    final muscle = _latest((e) => e.musclePct);
    final water = _latest((e) => e.waterPct);

    if (fat == null && muscle == null && water == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.donut_small_outlined),
          title: Text('No composition logged yet'),
          subtitle: Text(
            'Add body fat, muscle or water % when you log a weight.',
          ),
        ),
      );
    }

    return BentoTile(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CompositionRing(
            label: 'Body fat',
            value: fat,
            color: theme.colorScheme.tertiary,
          ),
          CompositionRing(
            label: 'Muscle',
            value: muscle,
            color: theme.colorScheme.primary,
          ),
          CompositionRing(
            label: 'Water',
            value: water,
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _Measurements extends StatelessWidget {
  const _Measurements({required this.measurements, required this.unit});

  final List<BodyMeasurement> measurements;
  final LengthUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (measurements.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.straighten),
          title: Text('No measurements yet'),
          subtitle: Text(
            'Tap “Add measurement” to track waist, chest, hips and more.',
          ),
        ),
      );
    }

    // Group by type, preserving the newest-first order so the first of each
    // group is the latest reading.
    final byType = <String, List<BodyMeasurement>>{};
    for (final m in measurements) {
      byType.putIfAbsent(m.type, () => []).add(m);
    }
    final types = byType.keys.toList()..sort();
    final unitLabel = unit == LengthUnit.inch ? 'in' : 'cm';

    return Column(
      children: [
        for (final type in types)
          Builder(
            builder: (context) {
              final latest = byType[type]!.first;
              final value = lengthFromCm(latest.valueCm, unit);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(_titleCase(type)),
                  subtitle: Text(
                    '${byType[type]!.length} reading'
                    '${byType[type]!.length == 1 ? '' : 's'} · last '
                    '${DateFormat.MMMd().format(latest.measuredAt)}',
                  ),
                  trailing: Text(
                    '${value.toStringAsFixed(1)} $unitLabel',
                    style: theme.textTheme.titleMedium,
                  ),
                  onTap: () =>
                      showAddMeasurementSheet(context, existing: latest),
                ),
              );
            },
          ),
      ],
    );
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
