import 'package:featherlog/domain/daily.dart';
import 'package:featherlog/domain/milestones.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a daily series starting 2026-01-01 from a list of kg values on
/// consecutive days.
List<DailyWeight> seriesFrom(List<double> kgs, {DateTime? start}) {
  final s = start ?? DateTime(2026, 1, 1);
  return [
    for (var i = 0; i < kgs.length; i++)
      DailyWeight(
        day: s.add(Duration(days: i)),
        weightKg: kgs[i],
      ),
  ];
}

/// Convenience: the values of all milestones of a given [kind], in order.
List<double> valuesOf(List<Milestone> ms, MilestoneKind kind) => [
  for (final m in ms.where((m) => m.kind == kind)) m.value,
];

void main() {
  group('detectMilestones - empty / non-progress', () {
    test('empty series -> empty', () {
      expect(detectMilestones(const []), isEmpty);
    });

    test('flat series -> empty', () {
      expect(detectMilestones(seriesFrom([80, 80, 80])), isEmpty);
    });

    test('upward-only series emits NOTHING (no punitive milestones)', () {
      final ms = detectMilestones(seriesFrom([80, 81, 82, 85, 90]), goalKg: 70);
      expect(ms, isEmpty);
    });

    test('non-positive stepKg -> empty', () {
      expect(detectMilestones(seriesFrom([90, 85, 80]), stepKg: 0), isEmpty);
    });
  });

  group('detectMilestones - weightLost', () {
    test('steady loss emits each whole-kg milestone in order', () {
      // 90 -> 86 loses 4 kg, so 1,2,3,4 kg lost.
      final ms = detectMilestones(seriesFrom([90, 89, 88, 87, 86]));
      expect(valuesOf(ms, MilestoneKind.weightLost), [1, 2, 3, 4]);
    });

    test('emits at the first day each step is reached', () {
      final ms = detectMilestones(seriesFrom([90, 88, 88, 87]));
      final lost = ms.where((m) => m.kind == MilestoneKind.weightLost).toList();
      // Day index 1 reaches 2 kg lost (90->88): both 1 and 2 emit on that day.
      expect(lost[0].value, 1);
      expect(lost[0].day, DateTime(2026, 1, 2));
      expect(lost[1].value, 2);
      expect(lost[1].day, DateTime(2026, 1, 2));
      // 3 kg lost first reached on day index 3 (90->87).
      expect(lost[2].value, 3);
      expect(lost[2].day, DateTime(2026, 1, 4));
    });

    test('respects a custom stepKg', () {
      // step 5: 90 -> 80 crosses 5 and 10 kg lost.
      final ms = detectMilestones(seriesFrom([90, 88, 85, 82, 80]), stepKg: 5);
      expect(valuesOf(ms, MilestoneKind.weightLost), [5, 10]);
    });

    test('a regain after a loss does NOT re-emit passed milestones', () {
      // Lose to 86 (1..4), regain to 89, then lose again past 86 to 84.
      final ms = detectMilestones(seriesFrom([90, 88, 86, 89, 87, 85, 84]));
      // First pass: 1,2,3,4. Regain emits nothing. Re-loss only adds NEW
      // deeper steps 5 and 6 (down to 84), never repeating 1..4.
      expect(valuesOf(ms, MilestoneKind.weightLost), [1, 2, 3, 4, 5, 6]);
    });
  });

  group('detectMilestones - percent to goal & goalReached', () {
    test('emits 25/50/75 then goalReached at first crossing', () {
      // start 90, goal 80 -> span 10. Values reach 25%(87.5), 50%(85),
      // 75%(82.5), 100%(<=80).
      final ms = detectMilestones(seriesFrom([90, 87, 85, 82, 80]), goalKg: 80);
      expect(valuesOf(ms, MilestoneKind.percentToGoal), [25, 50, 75]);
      expect(valuesOf(ms, MilestoneKind.goalReached), [80]);
    });

    test('goalReached fires once even past the goal', () {
      final ms = detectMilestones(seriesFrom([90, 80, 79, 78]), goalKg: 80);
      expect(valuesOf(ms, MilestoneKind.goalReached), [80]);
    });

    test('no percent/goal milestones without a goal', () {
      final ms = detectMilestones(seriesFrom([90, 85, 80]));
      expect(valuesOf(ms, MilestoneKind.percentToGoal), isEmpty);
      expect(valuesOf(ms, MilestoneKind.goalReached), isEmpty);
    });

    test('a goal at/above start (gaining direction) is ignored', () {
      // Goal above start: we never frame gaining as the target.
      final lost = detectMilestones(seriesFrom([80, 78, 76]), goalKg: 90);
      expect(valuesOf(lost, MilestoneKind.percentToGoal), isEmpty);
      expect(valuesOf(lost, MilestoneKind.goalReached), isEmpty);
      // weightLost still works on its own.
      expect(valuesOf(lost, MilestoneKind.weightLost), [1, 2, 3, 4]);
    });

    test('percent waypoints do not re-emit on a regain', () {
      // Reach 50% (85), regain to 88, dip back to 85: still only one 50%.
      final ms = detectMilestones(seriesFrom([90, 85, 88, 85]), goalKg: 80);
      expect(valuesOf(ms, MilestoneKind.percentToGoal), [25, 50]);
    });
  });

  group('detectMilestones - newLow', () {
    test(
      'emits a new low when the series sets a fresh minimum below start',
      () {
        final ms = detectMilestones(seriesFrom([90, 88, 86]));
        final lows = valuesOf(ms, MilestoneKind.newLow);
        expect(lows, [88, 86]);
      },
    );

    test('does not spam: tiny dips within a step do not re-emit', () {
      // After 88, dips of < 1 kg (87.8) should not fire another new low.
      final ms = detectMilestones(seriesFrom([90, 88, 87.8, 87.9]));
      expect(valuesOf(ms, MilestoneKind.newLow), [88]);
    });

    test('no new low for an upward series', () {
      final ms = detectMilestones(seriesFrom([80, 81, 82]));
      expect(valuesOf(ms, MilestoneKind.newLow), isEmpty);
    });
  });

  group('Milestone key & label', () {
    final day = DateTime(2026, 1, 1);

    test('key is stable per kind+value', () {
      final m = Milestone(kind: MilestoneKind.weightLost, day: day, value: 5);
      expect(m.key, 'weightLost:5.0');
    });

    test('labels read naturally', () {
      expect(
        Milestone(kind: MilestoneKind.weightLost, day: day, value: 5).label,
        '5 kg lost',
      );
      expect(
        Milestone(kind: MilestoneKind.percentToGoal, day: day, value: 50).label,
        'Halfway to goal',
      );
      expect(
        Milestone(kind: MilestoneKind.percentToGoal, day: day, value: 25).label,
        '25% to goal',
      );
      expect(
        Milestone(kind: MilestoneKind.goalReached, day: day, value: 80).label,
        'Goal reached!',
      );
      expect(
        Milestone(kind: MilestoneKind.newLow, day: day, value: 78.2).label,
        'New low: 78.2 kg',
      );
    });
  });

  group('newestUnseen', () {
    test('returns the most recent milestone not in seenKeys', () {
      final ms = detectMilestones(seriesFrom([90, 89, 88, 87]));
      // The last milestone in chronological order is the deepest new low (87);
      // with it marked seen, the newest remaining unseen one is "3 kg lost".
      final seen = {ms.last.key};
      final next = newestUnseen(ms, seen);
      expect(next, isNotNull);
      expect(next!.key, 'weightLost:3.0');
      expect(next.kind, MilestoneKind.weightLost);
    });

    test('returns null when everything is seen', () {
      final ms = detectMilestones(seriesFrom([90, 89]));
      final seen = {for (final m in ms) m.key};
      expect(newestUnseen(ms, seen), isNull);
    });

    test('returns null for an empty list', () {
      expect(newestUnseen(const [], <String>{}), isNull);
    });
  });
}
