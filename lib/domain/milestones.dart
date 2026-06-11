// Encouraging progress milestones derived from the daily weight series.
//
// This layer exists to celebrate the user, never to scold them. The type system
// is deliberately *incapable* of expressing a negative or punitive milestone:
// [MilestoneKind] has only positive achievements, so an upward (gaining) series
// can never produce any output here. All functions are pure and operate on the
// oldest-first `DailyWeight` list from `daily.dart` (see DESIGN.md §1).

import 'daily.dart';

/// The only milestones FeatherLog recognises — every one is an achievement.
///
/// There is intentionally no `regained`/`gained`/`missed` kind: progress
/// tracking should encourage, not punish (issue #49).
enum MilestoneKind {
  /// Crossed another whole-step amount lost below the starting weight.
  weightLost,

  /// Reached a 25 / 50 / 75 percent waypoint toward a (lower) goal.
  percentToGoal,

  /// Reached the goal weight.
  goalReached,

  /// Set a new all-time low for this series.
  newLow,
}

/// A single celebrated achievement, pinned to the day it first occurred.
class Milestone {
  const Milestone({required this.kind, required this.day, required this.value});

  /// What kind of achievement this is.
  final MilestoneKind kind;

  /// The day the milestone was first reached.
  final DateTime day;

  /// The numeric payload, interpreted per [kind]:
  /// - [MilestoneKind.weightLost]: whole kg lost from start (e.g. `5`).
  /// - [MilestoneKind.percentToGoal]: the percentage waypoint (25/50/75).
  /// - [MilestoneKind.goalReached]: the goal weight in kg.
  /// - [MilestoneKind.newLow]: the new low weight in kg.
  final double value;

  /// A stable identifier for "celebrate once" persistence. Two milestones with
  /// the same kind and value share a key regardless of the day, so re-running
  /// detection over a longer series never resurfaces an already-seen one.
  String get key => '${kind.name}:$value';

  /// A gentle, human-readable label for display.
  String get label => switch (kind) {
    MilestoneKind.weightLost => '${_trim(value)} kg lost',
    MilestoneKind.percentToGoal => switch (value) {
      50.0 => 'Halfway to goal',
      _ => '${_trim(value)}% to goal',
    },
    MilestoneKind.goalReached => 'Goal reached!',
    MilestoneKind.newLow => 'New low: ${_trim(value)} kg',
  };

  @override
  String toString() => 'Milestone($key, $day)';
}

/// Formats a double without a trailing `.0` so labels read naturally
/// ("5 kg lost", not "5.0 kg lost") while keeping real decimals ("78.2").
String _trim(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}

/// Detects encouraging milestones across [daily] (oldest-first), in
/// chronological order.
///
/// Because every [MilestoneKind] is positive, a flat or upward-only series
/// yields an empty list — there is no way to emit a discouraging event.
///
/// - [goalKg]: when provided **and** below the starting weight (a losing goal),
///   enables percent-to-goal (25/50/75) and goal-reached milestones. A goal at
///   or above the start is ignored (we never frame gaining as the target here).
/// - [stepKg]: the granularity of [MilestoneKind.weightLost] and the minimum
///   improvement required before a fresh [MilestoneKind.newLow] is emitted
///   (keeps day-to-day jitter from spamming new-low events).
List<Milestone> detectMilestones(
  List<DailyWeight> daily, {
  double? goalKg,
  double stepKg = 1.0,
}) {
  if (daily.isEmpty || stepKg <= 0) return const [];

  final start = daily.first.weightKg;
  final losingGoal = goalKg != null && goalKg < start;
  final goalSpan = losingGoal ? start - goalKg : 0.0;

  final out = <Milestone>[];

  // Highest whole-step loss already celebrated (so a regain then re-loss does
  // not re-emit a passed milestone, and we never emit on the way up).
  var lostSteps = 0;
  // Highest percent waypoint already crossed (0, 25, 50, 75, 100).
  var percentDone = 0;
  // Lowest weight already celebrated as a "new low"; null until the first one.
  double? lastLow;

  for (final d in daily) {
    final w = d.weightKg;

    // weightLost: emit each whole step of loss not yet reached. Only fires when
    // w is genuinely further below start than anything seen before.
    final lostNow = start - w;
    while ((lostSteps + 1) * stepKg <= lostNow + 1e-9) {
      lostSteps++;
      out.add(
        Milestone(
          kind: MilestoneKind.weightLost,
          day: d.day,
          value: (lostSteps * stepKg),
        ),
      );
    }

    // percent-to-goal + goalReached: only for a losing goal, at first crossing.
    if (losingGoal && goalSpan > 0) {
      final pct = ((start - w) / goalSpan) * 100;
      for (final threshold in const [25, 50, 75]) {
        if (percentDone < threshold && pct + 1e-9 >= threshold) {
          percentDone = threshold;
          out.add(
            Milestone(
              kind: MilestoneKind.percentToGoal,
              day: d.day,
              value: threshold.toDouble(),
            ),
          );
        }
      }
      if (percentDone < 100 && w <= goalKg + 1e-9) {
        percentDone = 100;
        out.add(
          Milestone(kind: MilestoneKind.goalReached, day: d.day, value: goalKg),
        );
      }
    }

    // newLow: a strict new minimum below the start, but only when it improves on
    // the previously celebrated low by at least [stepKg] — this gives new-low
    // milestones the same breathing room as weight-lost ones instead of firing
    // on every tiny dip.
    if (w < start - 1e-9) {
      if (lastLow == null || w <= lastLow - stepKg + 1e-9) {
        lastLow = w;
        out.add(Milestone(kind: MilestoneKind.newLow, day: d.day, value: w));
      }
    }
  }

  return out;
}

/// The most recent milestone in [all] whose [Milestone.key] is not in
/// [seenKeys], or null if every milestone has already been seen.
///
/// [all] is assumed chronological (as returned by [detectMilestones]); the
/// "most recent" unseen one is the last such entry. Intended to drive a
/// "celebrate once" prompt without re-celebrating past achievements.
Milestone? newestUnseen(List<Milestone> all, Set<String> seenKeys) {
  for (var i = all.length - 1; i >= 0; i--) {
    if (!seenKeys.contains(all[i].key)) return all[i];
  }
  return null;
}

/// A forward-looking target: the next un-reached waypoint on the way to the
/// goal. Unlike [detectMilestones] (which celebrates the past), this gives the
/// user a *near* thing to aim for instead of the full, possibly distant, goal.
class NextMilestone {
  const NextMilestone({
    required this.percent,
    required this.targetKg,
    required this.toGoKg,
    required this.progress,
  });

  /// The waypoint this target represents: 25, 50, 75, or 100 (the goal itself).
  final int percent;

  /// The canonical weight (kg) at this waypoint.
  final double targetKg;

  /// How far the latest weight still is from [targetKg], in kg (always ≥ 0).
  final double toGoKg;

  /// Overall fraction of the start→goal journey already covered, clamped 0–1.
  final double progress;

  /// True when the next thing to aim for is the goal itself (past 75%).
  bool get isGoal => percent == 100;

  /// A gentle headline for the waypoint.
  String get label => switch (percent) {
    50 => 'Halfway to goal',
    100 => 'Goal',
    _ => '$percent% to goal',
  };
}

/// The next 25 / 50 / 75 / 100% waypoint toward [goalKg] from the series start.
///
/// Returns null when there's nothing to aim for: no data, no goal, a goal equal
/// to the starting weight, or the goal already reached. Works in either
/// direction (loss or gain) — the waypoints are fractions of the start→goal
/// journey, so the same 25/50/75 checkpoints used by [detectMilestones] line up.
NextMilestone? nextMilestone(List<DailyWeight> daily, {double? goalKg}) {
  if (daily.isEmpty || goalKg == null) return null;
  final start = daily.first.weightKg;
  final current = daily.last.weightKg;
  final journey = goalKg - start;
  if (journey.abs() < 1e-9) return null; // goal == start: nothing to track

  // Fraction of the journey covered. Moving the wrong way reads as 0 progress.
  var progress = (current - start) / journey;
  if (progress < 0) progress = 0;
  if (progress >= 1 - 1e-9) return null; // already at/past the goal

  const waypoints = [0.25, 0.5, 0.75, 1.0];
  final nextFraction = waypoints.firstWhere((w) => w > progress + 1e-9);
  final targetKg = start + nextFraction * journey;
  return NextMilestone(
    percent: (nextFraction * 100).round(),
    targetKg: targetKg,
    toGoKg: (targetKg - current).abs(),
    progress: progress,
  );
}
