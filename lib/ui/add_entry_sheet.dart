import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/units.dart';
import '../providers/database_provider.dart';
import '../providers/data_providers.dart';

/// Shows the add/edit weight entry modal. Pass [existing] to edit a row.
Future<void> showAddEntrySheet(BuildContext context, {WeightEntry? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddEntrySheet(existing: existing),
    ),
  );
}

class AddEntrySheet extends ConsumerStatefulWidget {
  const AddEntrySheet({super.key, this.existing});

  final WeightEntry? existing;

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late DateTime _date;

  bool get _isEditing => widget.existing != null;

  WeightUnit get _unit {
    final unit = ref.read(settingsProvider).value?.weightUnit;
    return unit == 'lb' ? WeightUnit.lb : WeightUnit.kg;
  }

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? _today();
    final existingKg = widget.existing?.weightKg;
    _weightController = TextEditingController(
      text: existingKg == null
          ? ''
          : _formatNumber(weightFromKg(existingKg, _unit)),
    );
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _formatNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: _today(),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_weightController.text.replaceAll(',', '.'));
    final weightKg = weightToKg(value, _unit);
    final note = _noteController.text.trim();

    await ref
        .read(databaseProvider)
        .weightEntryDao
        .upsertForDate(
          date: _date,
          weightKg: weightKg,
          note: note.isEmpty ? null : note,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    await ref.read(databaseProvider).weightEntryDao.deleteEntry(id);
    if (mounted) Navigator.of(context).pop();
  }

  String? _validateWeight(String? raw) {
    final text = raw?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return 'Enter a weight';
    final value = double.tryParse(text);
    if (value == null) return 'Not a number';
    if (value <= 0) return 'Must be greater than 0';
    // Sanity bound in the displayed unit (about 1000 lb / 454 kg).
    final kg = weightToKg(value, _unit);
    if (kg > 454) return 'That seems too high';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _unit == WeightUnit.lb ? 'lb' : 'kg';
    final dateLabel = DateFormat.yMMMMd().format(_date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit entry' : 'Log weight',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(dateLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: unitLabel,
                border: const OutlineInputBorder(),
              ),
              validator: _validateWeight,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const Spacer(),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
