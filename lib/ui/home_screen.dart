import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../dev/dev_menu_screen.dart';
import '../domain/bmi.dart';
import '../domain/daily.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import '../providers/database_provider.dart';
import 'add_entry_sheet.dart';
import 'settings_screen.dart';
import 'widgets/day_detail_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/stats_panel.dart';
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
      appBar: AppBar(
        title: const Text('FeatherLog'),
        actions: [
          // Dev-only entry to the developer tools. kDebugMode is a const false
          // in release builds, so this whole action is tree-shaken out.
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Developer tools',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DevMenuScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddEntrySheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _ErrorState(),
        data: (entries) {
          if (entries.isEmpty) return const _EmptyState();
          return _Dashboard(
            entries: entries,
            unit: weightUnit,
            heightCm: profile?.heightCm,
            goalKg: profile?.goalWeightKg,
            showGoalLine: settings?.showGoalLine ?? true,
            showMovingAvg: settings?.showMovingAvg ?? true,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState();

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
              Icons.cloud_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text("Couldn't load your data", style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Try reopening the app. Your saved entries are safe on your '
              'device.',
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

class _Dashboard extends ConsumerStatefulWidget {
  const _Dashboard({
    required this.entries,
    required this.unit,
    required this.heightCm,
    required this.goalKg,
    required this.showGoalLine,
    required this.showMovingAvg,
  });

  /// Newest first (as provided by entriesProvider).
  final List<WeightEntry> entries;
  final WeightUnit unit;
  final double? heightCm;

  /// Canonical goal weight (kg), or null if unset.
  final double? goalKg;

  /// Whether the goal line overlay is enabled in settings.
  final bool showGoalLine;

  /// Whether the 7-day moving-average overlay is enabled in settings.
  final bool showMovingAvg;

  @override
  ConsumerState<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<_Dashboard> {
  /// The day currently selected on the chart (drives the detail card).
  DateTime? _selectedDay;

  /// The selected chart time window.
  ChartRange _range = ChartRange.month;

  WeightUnit get unit => widget.unit;
  double? get heightCm => widget.heightCm;

  String get _unitLabel => unit == WeightUnit.lb ? 'lb' : 'kg';

  String _fmtWeight(double kg) {
    final v = weightFromKg(kg, unit);
    return '${v.toStringAsFixed(1)} $_unitLabel';
  }

  /// The first note found among the readings on [day], if any.
  String? _noteForDay(DateTime day) {
    for (final e in widget.entries) {
      final d = DateTime(
        e.measuredAt.year,
        e.measuredAt.month,
        e.measuredAt.day,
      );
      if (d == day && e.note != null && e.note!.isNotEmpty) return e.note;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Aggregate raw readings to one value per day; current weight, BMI and the
    // trend all use the smoothed daily series, not individual readings.
    final daily = dailyAverages(
      widget.entries.map(
        (e) => Reading(measuredAt: e.measuredAt, weightKg: e.weightKg),
      ),
    );
    final today = daily.last; // entries is non-empty here
    final yesterday = daily.length > 1 ? daily[daily.length - 2] : null;

    // The chart shows only the selected time window; current weight / BMI /
    // recent list still reflect the full history.
    final visibleDaily = filterByRange(daily, _range);

    // Resolve the selected day within the visible window (clear if not shown).
    final selectedIndex = _selectedDay == null
        ? -1
        : visibleDaily.indexWhere((d) => d.day == _selectedDay);
    final selected = selectedIndex >= 0 ? visibleDaily[selectedIndex] : null;
    final selectedPrev = selectedIndex > 0
        ? visibleDaily[selectedIndex - 1]
        : null;

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
          _rangeSelector(),
          const SizedBox(height: 8),
          _overlayChips(),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: visibleDaily.length >= 2
                  ? WeightChart(
                      daily: visibleDaily,
                      unit: unit,
                      selectedDay: selected?.day,
                      goalKg: widget.showGoalLine ? widget.goalKg : null,
                      showMovingAverage: widget.showMovingAvg,
                      onDaySelected: (d) =>
                          setState(() => _selectedDay = d?.day),
                    )
                  : SizedBox(
                      height: 220,
                      child: Center(
                        child: Text(
                          'Not enough data in this range',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                      heightCm: heightCm,
                      note: _noteForDay(selected.day),
                      onClose: () => setState(() => _selectedDay = null),
                    ),
                  ),
          ),
        ],
        const SizedBox(height: 16),
        StatsPanel(daily: daily, unit: unit, goalKg: widget.goalKg),
        const SizedBox(height: 24),
        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...widget.entries.take(10).map((e) => _EntryTile(entry: e, unit: unit)),
      ],
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
          _selectedDay = null; // clear selection when the window changes
        }),
      ),
    );
  }

  Widget _overlayChips() {
    final hasGoal = widget.goalKg != null;
    return Wrap(
      spacing: 8,
      children: [
        if (hasGoal)
          FilterChip(
            label: const Text('Goal line'),
            avatar: const Icon(Icons.flag_outlined, size: 18),
            selected: widget.showGoalLine,
            onSelected: (wantOn) async {
              await ref
                  .read(databaseProvider)
                  .settingsDao
                  .setShowGoalLine(wantOn);
            },
          )
        else
          ActionChip(
            label: const Text('Set goal'),
            avatar: const Icon(Icons.flag_outlined, size: 18),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        FilterChip(
          label: const Text('7-day avg'),
          avatar: const Icon(Icons.show_chart, size: 18),
          selected: widget.showMovingAvg,
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
