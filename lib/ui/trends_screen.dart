import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/bmi.dart';
import '../domain/daily.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import '../providers/database_provider.dart';
import 'add_entry_sheet.dart';
import 'theme/app_theme.dart';
import 'widgets/bento_tile.dart';
import 'widgets/day_detail_card.dart';
import 'widgets/delta_pill.dart';
import 'widgets/section_header.dart';
import 'widgets/stats_panel.dart';
import 'widgets/weight_chart.dart';

/// The analytical tab: the full interactive trend chart (the showpiece), range
/// and overlay controls, a tap-to-detail card, the statistics panel, and the
/// recent-readings list.
class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  DateTime? _selectedDay;
  ChartRange _range = ChartRange.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(entriesProvider);
    final settings = ref.watch(settingsProvider).value;
    final profile = ref.watch(profileProvider).value;

    final unit = settings?.weightUnit == 'lb' ? WeightUnit.lb : WeightUnit.kg;
    final showGoalLine = settings?.showGoalLine ?? true;
    final showMovingAvg = settings?.showMovingAvg ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't load your data")),
        data: (entries) {
          final daily = ref.watch(dailySeriesProvider);
          if (daily.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Log on a couple more days to see your trend.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          final visibleDaily = filterByRange(daily, _range);
          final selectedIndex = _selectedDay == null
              ? -1
              : visibleDaily.indexWhere((d) => d.day == _selectedDay);
          final selected = selectedIndex >= 0
              ? visibleDaily[selectedIndex]
              : null;
          final selectedPrev = selectedIndex > 0
              ? visibleDaily[selectedIndex - 1]
              : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _rangeSelector(),
              const SizedBox(height: 8),
              _overlayChips(profile?.goalWeightKg, showGoalLine, showMovingAvg),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: visibleDaily.length >= 2
                      ? WeightChart(
                          daily: visibleDaily,
                          unit: unit,
                          selectedDay: selected?.day,
                          goalKg: showGoalLine ? profile?.goalWeightKg : null,
                          showMovingAverage: showMovingAvg,
                          onDaySelected: (d) =>
                              setState(() => _selectedDay = d?.day),
                        )
                      : SizedBox(
                          height: 220,
                          child: Center(
                            child: Text(
                              'Not enough data in this range',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: selected == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: DayDetailCard(
                          day: selected,
                          previous: selectedPrev,
                          unit: unit,
                          heightCm: profile?.heightCm,
                          note: _noteForDay(entries, selected.day),
                          onClose: () => setState(() => _selectedDay = null),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              StatsPanel(
                daily: daily,
                unit: unit,
                goalKg: profile?.goalWeightKg,
              ),
              const SizedBox(height: 24),
              const SectionHeader('Recent'),
              // One inset card with hairline dividers so the readings read as a
              // single grouped object. entries is newest-first, so the "previous
              // log" for row i is the next (older) reading — looked up in the
              // full list so the 10th row still gets a delta when more exists.
              BentoTile(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length && i < 10; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _EntryTile(
                        entry: entries[i],
                        previous: i + 1 < entries.length
                            ? entries[i + 1]
                            : null,
                        unit: unit,
                        heightCm: profile?.heightCm,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _rangeSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ChartRange>(
        showSelectedIcon: false,
        segments: [
          for (final r in ChartRange.values)
            ButtonSegment(value: r, label: Text(r.label)),
        ],
        selected: {_range},
        onSelectionChanged: (s) => setState(() {
          _range = s.first;
          _selectedDay = null;
        }),
      ),
    );
  }

  Widget _overlayChips(double? goalKg, bool showGoalLine, bool showMovingAvg) {
    final hasGoal = goalKg != null;
    return Wrap(
      spacing: 8,
      children: [
        if (hasGoal)
          FilterChip(
            label: const Text('Goal line'),
            avatar: const Icon(Icons.flag_outlined, size: 18),
            selected: showGoalLine,
            onSelected: (wantOn) async {
              await ref
                  .read(databaseProvider)
                  .settingsDao
                  .setShowGoalLine(wantOn);
            },
          ),
        FilterChip(
          label: const Text('7-day avg'),
          avatar: const Icon(Icons.show_chart, size: 18),
          selected: showMovingAvg,
          onSelected: (wantOn) async {
            await ref
                .read(databaseProvider)
                .settingsDao
                .setShowMovingAvg(wantOn);
          },
        ),
      ],
    );
  }

  /// The first note found among the readings on [day], if any.
  String? _noteForDay(List<WeightEntry> entries, DateTime day) {
    for (final e in entries) {
      final d = DateTime(
        e.measuredAt.year,
        e.measuredAt.month,
        e.measuredAt.day,
      );
      if (d == day && e.note != null && e.note!.isNotEmpty) return e.note;
    }
    return null;
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.previous,
    required this.unit,
    this.heightCm,
  });

  final WeightEntry entry;

  /// The previous (older) reading, used for the "since your last log" delta.
  /// Null only for the very first entry in history.
  final WeightEntry? previous;
  final WeightUnit unit;

  /// Height in cm, when known, enables the per-row BMI indicator.
  final double? heightCm;

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

    final meta = StringBuffer()
      ..write(DateFormat.MMMd().format(entry.measuredAt))
      ..write(' · ')
      ..write(DateFormat.Hm().format(entry.measuredAt));
    if (bmi != null) meta.write(' · BMI ${bmi.toStringAsFixed(1)}');

    return InkWell(
      onTap: () => showAddEntrySheet(context, existing: entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // BMI category indicator: a calm coloured dot when height is known.
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
            // "Since your last log" delta, aktiBMI-style. Absent for the first
            // ever entry (nothing to compare against).
            if (deltaKg != null)
              DeltaPill(deltaKg: deltaKg, unit: unit, dense: true),
          ],
        ),
      ),
    );
  }
}
