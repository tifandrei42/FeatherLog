import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/database.dart';
import '../data/update_service.dart';
import '../dev/dev_menu_screen.dart';
import '../dev/dev_tools.dart';
import '../domain/bmi.dart';
import '../domain/milestones.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import '../providers/database_provider.dart';
import '../providers/update_provider.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/bento_tile.dart';
import 'widgets/bmi_band_gauge.dart';
import 'widgets/delta_pill.dart';

/// The calm anchor of the Almanac UI, laid out as a bento mosaic: a prominent
/// weight hero, a full-width BMI band gauge, and a 2-up row of small streak /
/// days-logged tiles. The chart and full history live one tap away on Trends.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FeatherLog'),
        actions: [
          // Dev-only entry point; tree-shaken out of release builds. The
          // `showDevTools` flag additionally lets the screenshot harness hide it.
          if (kDebugMode && showDevTools)
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Developer tools',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DevMenuScreen()),
              ),
            ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _ErrorState(),
        data: (entries) =>
            entries.isEmpty ? const _EmptyState() : const _TodayBody(),
      ),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final profile = ref.watch(profileProvider).value;
    final entries = ref.watch(entriesProvider).value ?? const <WeightEntry>[];
    final consistency = ref.watch(consistencyProvider);
    final milestones = ref.watch(milestonesProvider);
    final bmiCtx = ref.watch(bmiContextProvider);
    final trend = ref.watch(trendSnapshotProvider);
    final nextMile = ref.watch(nextMilestoneProvider);
    final update = ref.watch(updateCheckProvider).value;

    final unit = settings?.weightUnit == 'lb' ? WeightUnit.lb : WeightUnit.kg;
    final heroShowsTrend = settings?.heroShowsTrend ?? true;

    if (entries.isEmpty) return const SizedBox.shrink();
    final last = entries.first;
    final prev = entries.length > 1 ? entries[1] : null;
    final deltaSinceLast = prev == null ? null : last.weightKg - prev.weightKg;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        if (update != null) ...[
          _UpdateBanner(info: update),
          const SizedBox(height: Spacing.md),
        ],
        if (milestones.isNotEmpty) ...[
          _MilestoneBanner(label: milestones.last.label),
          const SizedBox(height: Spacing.md),
        ],
        _HeroTile(
          last: last,
          unit: unit,
          deltaSinceLast: deltaSinceLast,
          trendKg: trend.trendKg,
          weeklyTrendDeltaKg: trend.weeklyTrendDeltaKg,
          showTrend: heroShowsTrend,
        ),
        const SizedBox(height: Spacing.md),
        // A near target to aim for, shown only when there's a goal still ahead.
        if (nextMile != null) ...[
          _NextMilestoneTile(milestone: nextMile, unit: unit),
          const SizedBox(height: Spacing.md),
        ],
        _BmiTile(
          weightKg: last.weightKg,
          heightCm: profile?.heightCm,
          ctx: bmiCtx,
        ),
        const SizedBox(height: Spacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StreakTile(streak: consistency.currentStreak)),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _DaysTile(
                  daysLogged: consistency.daysLogged,
                  window: consistency.window,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Center(
          child: TextButton.icon(
            onPressed: () => ref.read(selectedTabProvider.notifier).select(1),
            icon: const Icon(Icons.insights_outlined),
            label: const Text('View full trend'),
          ),
        ),
      ],
    );
  }
}

/// The prominent hero tile. By default it leads with the smoothed **trend
/// weight** (the honest, low-noise number) and demotes today's raw reading to a
/// caption; a small "why two numbers?" explainer is one tap away. When the user
/// turns the trend hero off — or there isn't enough data for a trend yet — it
/// falls back to the raw latest reading and the "since your last log" delta.
class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.last,
    required this.unit,
    required this.deltaSinceLast,
    required this.trendKg,
    required this.weeklyTrendDeltaKg,
    required this.showTrend,
  });

  final WeightEntry last;
  final WeightUnit unit;
  final double? deltaSinceLast;

  /// Latest 7-day moving-average weight in kg (null if too little data).
  final double? trendKg;

  /// Trend change over the trailing week in kg (null if too little data).
  final double? weeklyTrendDeltaKg;

  /// User preference: lead with the trend weight (default true).
  final bool showTrend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';

    // Lead with the trend only when the user wants it AND there's a trend.
    final useTrend = showTrend && trendKg != null;
    final bigKg = useTrend ? trendKg! : last.weightKg;
    final bigValue = weightFromKg(bigKg, unit);
    final deltaKg = useTrend ? weeklyTrendDeltaKg : deltaSinceLast;
    // "trend over the last 7 days" (smoothed) is deliberately distinct from the
    // Trends screen's raw "Last 7 days" figure — same window, different number.
    final deltaLabel = useTrend
        ? 'trend over the last 7 days'
        : 'since your last log';

    return BentoTile(
      padding: const EdgeInsets.all(Spacing.xl),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          theme.colorScheme.surface,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                useTrend ? 'TREND WEIGHT' : 'CURRENT WEIGHT',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.4,
                ),
              ),
              if (useTrend)
                // Tappable explainer — keeps the "two numbers" idea discoverable
                // without a nagging one-time card.
                const _ExplainerButton(),
            ],
          ),
          const SizedBox(height: 6),
          // Count-up so the hero animates in (and tweens on a new log). One
          // Text.rich so value + unit read as "78.4 kg" together (a11y).
          // Tabular figures keep the big number from jittering as it counts.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: bigValue),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value.toStringAsFixed(1),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: ' $unitLabel',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (deltaKg != null)
            Row(
              children: [
                DeltaPill(deltaKg: deltaKg, unit: unit),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    deltaLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          // When leading with the trend, demote the raw reading to a caption so
          // the user still sees today's actual number.
          Text(
            useTrend
                ? "Today's reading "
                      '${weightFromKg(last.weightKg, unit).toStringAsFixed(1)} '
                      '$unitLabel · ${DateFormat.yMMMd().format(last.measuredAt)}'
                : 'Last logged ${DateFormat.yMMMd().format(last.measuredAt)} · '
                      '${DateFormat.Hm().format(last.measuredAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "?" affordance next to the TREND WEIGHT kicker that explains why the
/// hero shows a smoothed trend rather than the raw scale reading.
class _ExplainerButton extends StatelessWidget {
  const _ExplainerButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      iconSize: 16,
      color: theme.colorScheme.onSurfaceVariant,
      icon: const Icon(Icons.help_outline),
      tooltip: 'Why two numbers?',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Why two numbers?'),
          content: Text(
            'Your weight swings day to day — mostly water, not fat. The big '
            'number is your 7-day trend: the average that filters out that '
            'noise, so it reflects real change.\n\n'
            'The small "today\'s reading" is the raw number from the scale. '
            'When it jumps around but the trend keeps drifting your way, the '
            'trend is the truth.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A near, attainable target: the next 25/50/75% waypoint toward the goal, with
/// how far there is to go and an overall progress bar. Shown instead of the
/// distant goal so there's always something close to aim for.
class _NextMilestoneTile extends StatelessWidget {
  const _NextMilestoneTile({required this.milestone, required this.unit});

  final NextMilestone milestone;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';
    final target = weightFromKg(milestone.targetKg, unit).toStringAsFixed(1);
    final toGo = weightFromKg(milestone.toGoKg, unit).toStringAsFixed(1);
    final pct = (milestone.progress * 100).round();

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                'NEXT MILESTONE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                milestone.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: target,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' $unitLabel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$toGo $unitLabel to go',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: milestone.progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$pct% of the way to your goal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The BMI tile: value + category and the band gauge (or a prompt to set
/// height). Replaces the old plain BMI card.
class _BmiTile extends StatelessWidget {
  const _BmiTile({
    required this.weightKg,
    required this.heightCm,
    required this.ctx,
  });

  final double weightKg;
  final double? heightCm;
  final BmiContext ctx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (heightCm == null) {
      return BentoTile(
        child: Row(
          children: [
            Icon(Icons.straighten, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your height for BMI',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add height in Settings to see your BMI.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bmi = calculateBmi(weightKg: weightKg, heightCm: heightCm!);
    final category = bmiCategoryFor(bmi);

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'BMI',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                bmi.toStringAsFixed(1),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              Text(category.label, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 14),
          BmiBandGauge(bmi: bmi),
          if (!ctx.adultBandsApply) ...[
            const SizedBox(height: 10),
            Text(
              'Under 20 — adult BMI categories are a rough guide here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact stat tile: a small icon + kicker, a big figure, and a caption.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.kicker,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color iconColor;
  final String kicker;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                kicker.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StatTile(
      icon: Icons.local_fire_department_outlined,
      iconColor: theme.colorScheme.primary,
      kicker: 'Streak',
      value: '$streak',
      caption: streak == 0
          ? 'log today to start'
          : (streak == 1 ? 'day in a row' : 'days in a row'),
    );
  }
}

class _DaysTile extends StatelessWidget {
  const _DaysTile({required this.daysLogged, required this.window});

  final int daysLogged;
  final int window;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StatTile(
      icon: Icons.event_available_outlined,
      iconColor: theme.colorScheme.secondary,
      kicker: 'Logged',
      value: '$daysLogged/$window',
      caption: 'days this month',
    );
  }
}

class _MilestoneBanner extends StatelessWidget {
  const _MilestoneBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        theme.extension<FeatherPalette>()?.sunrise ??
        theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dismissible "update available" banner shown when an opt-in check finds a
/// newer release. "Update" opens the GitHub release page (where the APKs live);
/// "Later" remembers this version so it isn't shown again.
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner({required this.info});

  final UpdateInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return BentoTile(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      borderColor: accent.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_outlined, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update available',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${info.version} is ready to install',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => ref
                    .read(databaseProvider)
                    .settingsDao
                    .setDismissedUpdateVersion(info.version),
                child: const Text('Later'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () => launchUrl(
                  Uri.parse(info.url),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        ],
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
