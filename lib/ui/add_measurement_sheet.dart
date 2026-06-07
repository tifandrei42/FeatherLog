import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/units.dart';
import '../providers/data_providers.dart';
import '../providers/database_provider.dart';
import 'widgets/shiny_button.dart';

/// The body parts offered by default. Stored lower-case (canonical) so grouping
/// is stable; the column is free-text, so new parts never need a migration.
const _measurementTypes = [
  'waist',
  'chest',
  'hips',
  'neck',
  'thigh',
  'arm',
  'calf',
];

/// Shows the add/edit body-measurement modal. Pass [existing] to edit a row.
Future<void> showAddMeasurementSheet(
  BuildContext context, {
  BodyMeasurement? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddMeasurementSheet(existing: existing),
    ),
  );
}

class AddMeasurementSheet extends ConsumerStatefulWidget {
  const AddMeasurementSheet({super.key, this.existing});

  final BodyMeasurement? existing;

  @override
  ConsumerState<AddMeasurementSheet> createState() =>
      _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends ConsumerState<AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late String _type;

  bool get _isEditing => widget.existing != null;

  LengthUnit get _unit {
    final u = ref.read(settingsProvider).value?.lengthUnit;
    return u == 'in' ? LengthUnit.inch : LengthUnit.cm;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _date = existing?.measuredAt ?? _today();
    _type = existing?.type ?? _measurementTypes.first;
    _valueController = TextEditingController(
      text: existing == null ? '' : _fmt(lengthFromCm(existing.valueCm, _unit)),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _fmt(double v) =>
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

  String? _validateValue(String? raw) {
    final text = raw?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return 'Enter a measurement';
    final value = double.tryParse(text);
    if (value == null) return 'Not a number';
    if (value <= 0) return 'Must be greater than 0';
    if (lengthToCm(value, _unit) > 500) return 'That seems too high';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_valueController.text.replaceAll(',', '.'));
    final valueCm = lengthToCm(value, _unit);
    final note = _noteController.text.trim();
    final dao = ref.read(databaseProvider).bodyMeasurementDao;
    final existing = widget.existing;

    if (existing == null) {
      final now = DateTime.now();
      final measuredAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
        now.second,
      );
      await dao.addMeasurement(
        measuredAt: measuredAt,
        type: _type,
        valueCm: valueCm,
        note: note.isEmpty ? null : note,
      );
    } else {
      final original = existing.measuredAt;
      final measuredAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        original.hour,
        original.minute,
        original.second,
      );
      await dao.updateMeasurement(
        id: existing.id,
        measuredAt: measuredAt,
        type: _type,
        valueCm: valueCm,
        note: note.isEmpty ? null : note,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    await ref.read(databaseProvider).bodyMeasurementDao.deleteMeasurement(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _unit == LengthUnit.inch ? 'in' : 'cm';
    final dateLabel = DateFormat.yMMMMd().format(_date);
    // Include any custom type from an edited row alongside the defaults.
    final types = {..._measurementTypes, _type}.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit measurement' : 'Add measurement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final t in types)
                  ChoiceChip(
                    label: Text(_titleCase(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(dateLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Measurement',
                suffixText: unitLabel,
                border: const OutlineInputBorder(),
              ),
              validator: _validateValue,
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
                ShinyButton(label: 'Save', icon: Icons.check, onPressed: _save),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
