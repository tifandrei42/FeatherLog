import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/export_service.dart';
import '../data/import_service.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import '../providers/database_provider.dart';

/// Grouped, calm settings list (UI_DESIGN.md §8.5, US-13.x): units, body
/// (height + goal), theme, default chart overlays, and an about/privacy note.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final profile = ref.watch(profileProvider).value;
    final dao = ref.read(databaseProvider);

    final weightUnit = settings?.weightUnit == 'lb'
        ? WeightUnit.lb
        : WeightUnit.kg;
    final lengthUnit = settings?.lengthUnit == 'in'
        ? LengthUnit.inch
        : LengthUnit.cm;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _header(context, 'Units'),
          ListTile(
            title: const Text('Weight'),
            trailing: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'kg', label: Text('kg')),
                ButtonSegment(value: 'lb', label: Text('lb')),
              ],
              selected: {settings?.weightUnit ?? 'kg'},
              onSelectionChanged: (s) =>
                  dao.settingsDao.updateWeightUnit(s.first),
            ),
          ),
          ListTile(
            title: const Text('Length'),
            trailing: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'cm', label: Text('cm')),
                ButtonSegment(value: 'in', label: Text('in')),
              ],
              selected: {settings?.lengthUnit ?? 'cm'},
              onSelectionChanged: (s) =>
                  dao.settingsDao.updateLengthUnit(s.first),
            ),
          ),

          _header(context, 'Body'),
          ListTile(
            title: const Text('Height'),
            subtitle: const Text('Used to calculate BMI'),
            trailing: Text(
              profile?.heightCm == null
                  ? 'Not set'
                  : _fmtLength(profile!.heightCm!, lengthUnit),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () =>
                _editHeight(context, ref, profile?.heightCm, lengthUnit),
          ),
          ListTile(
            title: const Text('Goal weight'),
            trailing: Text(
              profile?.goalWeightKg == null
                  ? 'Not set'
                  : _fmtWeight(profile!.goalWeightKg!, weightUnit),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () =>
                _editGoal(context, ref, profile?.goalWeightKg, weightUnit),
          ),

          _header(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            trailing: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'system', label: Text('System')),
                ButtonSegment(value: 'light', label: Text('Light')),
                ButtonSegment(value: 'dark', label: Text('Dark')),
              ],
              selected: {settings?.theme ?? 'system'},
              onSelectionChanged: (s) => dao.settingsDao.updateTheme(s.first),
            ),
          ),

          _header(context, 'Chart overlays'),
          SwitchListTile(
            title: const Text('7-day moving average'),
            subtitle: const Text('Show the smoothed trend line by default'),
            value: settings?.showMovingAvg ?? true,
            onChanged: (v) => dao.settingsDao.setShowMovingAvg(v),
          ),
          SwitchListTile(
            title: const Text('Goal line'),
            subtitle: const Text('Show your goal weight on the chart'),
            value: settings?.showGoalLine ?? true,
            onChanged: (v) => dao.settingsDao.setShowGoalLine(v),
          ),

          _header(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Export as JSON'),
            subtitle: const Text('Complete, restorable backup'),
            onTap: () => _export(context, ref, asCsv: false),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export as CSV'),
            subtitle: const Text('For spreadsheets (includes BMI)'),
            onTap: () => _export(context, ref, asCsv: true),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Import from JSON'),
            subtitle: const Text('Restore from a backup (replaces all data)'),
            onTap: () => _import(context, ref),
          ),

          _header(context, 'About'),
          const ListTile(
            title: Text('FeatherLog'),
            subtitle: Text(
              'A free, local-first weight & BMI tracker. Your data stays on '
              'your device — no accounts, no ads, no trackers.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref, {
    required bool asCsv,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    try {
      final entries = await db.weightEntryDao.getAllEntries();
      if (entries.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Nothing to export yet')),
        );
        return;
      }
      final profile = await db.profileDao.getOrCreateProfile();
      final settings = await db.settingsDao.getOrCreateSettings();
      const service = ExportService();

      final String content;
      final String filename;
      if (asCsv) {
        content = service.toCsv(profile: profile, entries: entries);
        filename = 'featherlog_export.csv';
      } else {
        content = service.toJson(
          profile: profile,
          settings: settings,
          entries: entries,
          exportedAt: DateTime.now(),
        );
        filename = 'featherlog_export.json';
      }

      if (kIsWeb) {
        // On web, share the bytes directly (triggers a download).
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                utf8.encode(content),
                name: filename,
                mimeType: asCsv ? 'text/csv' : 'application/json',
              ),
            ],
            fileNameOverrides: [filename],
          ),
        );
      } else {
        // On native, write to a temp file then share it.
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsString(content);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);

    const typeGroup = XTypeGroup(
      label: 'JSON backup',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    final picked = await openFile(acceptedTypeGroups: [typeGroup]);
    if (picked == null) return; // cancelled

    final String content;
    try {
      content = await picked.readAsString();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't read that file.")),
      );
      return;
    }

    // Parse + validate BEFORE touching the database.
    final result = const ImportService().parse(content);
    if (!result.isOk) {
      messenger.showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: Text(
          'This replaces all current data with ${result.entries.length} '
          'entries from the backup. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await db.applyImport(result);
      messenger.showSnackBar(
        SnackBar(content: Text('Restored ${result.entries.length} entries')),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Import failed. Your data is unchanged.')),
      );
    }
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.8,
      ),
    ),
  );

  String _fmtWeight(double kg, WeightUnit u) {
    final v = weightFromKg(kg, u);
    return '${v.toStringAsFixed(1)} ${u == WeightUnit.lb ? 'lb' : 'kg'}';
  }

  String _fmtLength(double cm, LengthUnit u) {
    final v = lengthFromCm(cm, u);
    return '${v.toStringAsFixed(u == LengthUnit.inch ? 1 : 0)} '
        '${u == LengthUnit.inch ? 'in' : 'cm'}';
  }

  Future<void> _editHeight(
    BuildContext context,
    WidgetRef ref,
    double? currentCm,
    LengthUnit unit,
  ) async {
    final label = unit == LengthUnit.inch ? 'in' : 'cm';
    final result = await _numberDialog(
      context,
      title: 'Height',
      suffix: label,
      initial: currentCm == null
          ? ''
          : lengthFromCm(
              currentCm,
              unit,
            ).toStringAsFixed(unit == LengthUnit.inch ? 1 : 0),
      validate: (v) {
        // Plausible human height: ~50–272 cm.
        final cm = lengthToCm(v, unit);
        if (cm < 50 || cm > 272) return 'Enter a realistic height';
        return null;
      },
    );
    if (result == null) return;
    await ref
        .read(databaseProvider)
        .profileDao
        .updateHeight(lengthToCm(result, unit));
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    double? currentKg,
    WeightUnit unit,
  ) async {
    final label = unit == WeightUnit.lb ? 'lb' : 'kg';
    final result = await _numberDialog(
      context,
      title: 'Goal weight',
      suffix: label,
      initial: currentKg == null
          ? ''
          : weightFromKg(currentKg, unit).toStringAsFixed(1),
      validate: (v) {
        // Plausible adult weight: up to ~454 kg.
        final kg = weightToKg(v, unit);
        if (kg > 454) return 'That seems too high';
        return null;
      },
    );
    if (result == null) return;
    await ref
        .read(databaseProvider)
        .profileDao
        .updateGoalWeight(weightToKg(result, unit));
  }

  /// Shared validated numeric-entry dialog. Returns the parsed value, or null
  /// if cancelled. [validate] receives the parsed positive number and returns
  /// an error string (shown inline) or null when acceptable.
  Future<double?> _numberDialog(
    BuildContext context, {
    required String title,
    required String suffix,
    required String initial,
    String? Function(double value)? validate,
  }) {
    return showDialog<double>(
      context: context,
      builder: (ctx) => _NumberDialog(
        title: title,
        suffix: suffix,
        initial: initial,
        validate: validate,
      ),
    );
  }
}

/// A small stateful numeric dialog with inline validation feedback.
class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.suffix,
    required this.initial,
    this.validate,
  });

  final String title;
  final String suffix;
  final String initial;
  final String? Function(double value)? validate;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim().replaceAll(',', '.');
    final v = double.tryParse(text);
    if (text.isEmpty) {
      setState(() => _error = 'Enter a value');
      return;
    }
    if (v == null) {
      setState(() => _error = 'Not a number');
      return;
    }
    if (v <= 0) {
      setState(() => _error = 'Must be greater than 0');
      return;
    }
    final custom = widget.validate?.call(v);
    if (custom != null) {
      setState(() => _error = custom);
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: widget.suffix,
          border: const OutlineInputBorder(),
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
