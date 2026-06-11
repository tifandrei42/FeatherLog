import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/bmi.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import '../providers/database_provider.dart';
import 'add_entry_sheet.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/delta_pill.dart';

/// The full, browsable log: every reading, newest first, grouped by month.
///
/// Reached from the Trends "Recent" section ("See all") rather than a 5th tab —
/// the bottom nav stays at four destinations (UI_DESIGN.md §8), and Trends keeps
/// a compact preview while the complete, editable history lives one tap away.
///
/// Each row: tap to edit, swipe ← to delete (with an undo snackbar — deletion is
/// never final), swipe → to edit. Multiple readings on one day each get a row.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(entriesProvider);
    final settings = ref.watch(settingsProvider).value;
    final profile = ref.watch(profileProvider).value;
    final unit = settings?.weightUnit == 'lb' ? WeightUnit.lb : WeightUnit.kg;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text("Couldn't load your data")),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xxxl),
                child: Text(
                  'No entries yet.\nLog your first weight to start your history.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          final rows = _buildRows(entries);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              return switch (row) {
                _MonthRow(:final label) => Padding(
                  padding: EdgeInsets.only(
                    top: i == 0 ? 8 : Spacing.lg,
                    bottom: Spacing.sm,
                    left: 4,
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _EntryRow(:final entry, :final previous) => _SwipeableEntry(
                  entry: entry,
                  previous: previous,
                  unit: unit,
                  heightCm: profile?.heightCm,
                ),
              };
            },
          );
        },
      ),
    );
  }

  /// Flattens the newest-first [entries] into month headers + entry rows, each
  /// entry carrying its previous (older) reading so it can show a delta. The
  /// older neighbour is the next item in the list (entries are newest-first).
  static List<_Row> _buildRows(List<WeightEntry> entries) {
    final rows = <_Row>[];
    String? lastKey;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final key = '${e.measuredAt.year}-${e.measuredAt.month}';
      if (key != lastKey) {
        rows.add(_MonthRow(DateFormat.yMMMM().format(e.measuredAt)));
        lastKey = key;
      }
      rows.add(_EntryRow(e, i + 1 < entries.length ? entries[i + 1] : null));
    }
    return rows;
  }
}

sealed class _Row {
  const _Row();
}

class _MonthRow extends _Row {
  const _MonthRow(this.label);
  final String label;
}

class _EntryRow extends _Row {
  const _EntryRow(this.entry, this.previous);
  final WeightEntry entry;
  final WeightEntry? previous;
}

/// One history row wrapped in a [Dismissible] for swipe actions.
///
/// `confirmDismiss` always returns false: the row is never removed by the
/// Dismissible itself. Instead the DB write (delete or edit) drives the change,
/// and the reactive entries stream updates the list. This sidesteps the classic
/// "dismissed Dismissible still in the tree" crash that happens when a
/// stream-backed list and the Dismissible both try to remove the same item.
class _SwipeableEntry extends ConsumerWidget {
  const _SwipeableEntry({
    required this.entry,
    required this.previous,
    required this.unit,
    this.heightCm,
  });

  final WeightEntry entry;
  final WeightEntry? previous;
  final WeightUnit unit;
  final double? heightCm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey('history-entry-${entry.id}'),
      // Swipe → (startToEnd) edits; swipe ← (endToStart) deletes.
      background: _swipeBg(
        color: theme.colorScheme.secondaryContainer,
        fg: theme.colorScheme.onSecondaryContainer,
        icon: Icons.edit_outlined,
        label: 'Edit',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        color: theme.colorScheme.errorContainer,
        fg: theme.colorScheme.onErrorContainer,
        icon: Icons.delete_outline,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _deleteWithUndo(context, ref);
        } else {
          await showAddEntrySheet(context, existing: entry);
        }
        return false; // the stream handles row removal; never self-dismiss
      },
      child: _HistoryEntryTile(
        entry: entry,
        previous: previous,
        unit: unit,
        heightCm: heightCm,
      ),
    );
  }

  Future<void> _deleteWithUndo(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(databaseProvider).weightEntryDao;
    final messenger = ScaffoldMessenger.of(context);
    final removed = entry; // capture the full row for a faithful restore
    await dao.deleteEntry(removed.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Entry deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => dao.restoreEntry(removed),
        ),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required Color fg,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    final row = <Widget>[
      Icon(icon, color: fg),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
      ),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerRight
            ? row.reversed.toList()
            : row,
      ),
    );
  }
}

/// A single reading row: weight, date/time (+ BMI when height is known), an
/// optional note, and a "since the previous log" delta pill. Tap to edit.
/// Mirrors the compact Trends "Recent" row so the two read as one family.
class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({
    required this.entry,
    required this.previous,
    required this.unit,
    this.heightCm,
  });

  final WeightEntry entry;
  final WeightEntry? previous;
  final WeightUnit unit;
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
      ..write(DateFormat.MMMEd().format(entry.measuredAt))
      ..write(' · ')
      ..write(DateFormat.Hm().format(entry.measuredAt));
    if (bmi != null) meta.write(' · BMI ${bmi.toStringAsFixed(1)}');

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
        child: InkWell(
          onTap: () => showAddEntrySheet(context, existing: entry),
          child: Padding(
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
          ),
        ),
      ),
    );
  }
}
