import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/units.dart';
import '../providers/database_provider.dart';
import '../providers/data_providers.dart';
import 'widgets/shiny_button.dart';

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
  late final TextEditingController _bodyFatController;
  late final TextEditingController _muscleController;
  late final TextEditingController _waterController;
  late DateTime _date;

  /// When adding (not editing), the most recent logged weight (canonical kg).
  /// Pre-fills the field and seeds the steppers, so a typical log is a couple
  /// of taps rather than a full re-type.
  double? _prefillKg;

  bool get _isEditing => widget.existing != null;

  WeightUnit get _unit {
    final unit = ref.read(settingsProvider).value?.weightUnit;
    return unit == 'lb' ? WeightUnit.lb : WeightUnit.kg;
  }

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.measuredAt ?? _today();
    final existingKg = widget.existing?.weightKg;
    // When adding, seed from the most recent reading (entriesProvider is
    // newest-first) so the steppers start from a sensible value.
    if (existingKg == null) {
      final entries = ref.read(entriesProvider).value;
      if (entries != null && entries.isNotEmpty) {
        _prefillKg = entries.first.weightKg;
      }
    }
    final initialKg = existingKg ?? _prefillKg;
    _weightController = TextEditingController(
      text: initialKg == null
          ? ''
          : _formatNumber(weightFromKg(initialKg, _unit)),
    );
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
    _bodyFatController = TextEditingController(
      text: _pctText(widget.existing?.bodyFatPct),
    );
    _muscleController = TextEditingController(
      text: _pctText(widget.existing?.musclePct),
    );
    _waterController = TextEditingController(
      text: _pctText(widget.existing?.waterPct),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    _bodyFatController.dispose();
    _muscleController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _formatNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Display text for an optional stored percentage (blank when unset).
  static String _pctText(double? v) => v == null ? '' : _formatNumber(v);

  /// Nudges the weight field by [delta] in the *displayed* unit (the +/-
  /// steppers and their hold-to-repeat). Rounds to 0.1 to avoid float noise and
  /// clamps at 0. When the field is empty it starts from the pre-filled weight.
  void _step(double delta) {
    final current = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final base =
        current ??
        (_prefillKg == null ? 0.0 : weightFromKg(_prefillKg!, _unit));
    var next = base + delta;
    if (next < 0) next = 0;
    next = (next * 10).roundToDouble() / 10; // snap to 0.1
    final text = _formatNumber(next);
    _weightController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

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
    final bodyFat = _parsePct(_bodyFatController);
    final muscle = _parsePct(_muscleController);
    final water = _parsePct(_waterController);
    final dao = ref.read(databaseProvider).weightEntryDao;
    final existing = widget.existing;

    if (existing == null) {
      // New reading: stamp with the chosen day at the current time so distinct
      // readings stay ordered.
      final now = DateTime.now();
      final measuredAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
        now.second,
      );
      await dao.addReading(
        measuredAt: measuredAt,
        weightKg: weightKg,
        note: note.isEmpty ? null : note,
        bodyFatPct: bodyFat,
        musclePct: muscle,
        waterPct: water,
      );
    } else {
      // Edit: keep the original time-of-day, apply the (possibly changed) date.
      final original = existing.measuredAt;
      final measuredAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        original.hour,
        original.minute,
        original.second,
      );
      await dao.updateReading(
        id: existing.id,
        measuredAt: measuredAt,
        weightKg: weightKg,
        note: note.isEmpty ? null : note,
        bodyFatPct: bodyFat,
        musclePct: muscle,
        waterPct: water,
      );
    }
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

  /// Parses an optional 0–100 percentage field; blank → null.
  double? _parsePct(TextEditingController c) {
    final text = c.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Validates an optional percentage: blank allowed, otherwise 0–100.
  static String? _validatePct(String? raw) {
    final text = raw?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return null;
    final v = double.tryParse(text);
    if (v == null) return 'Not a number';
    if (v < 0 || v > 100) return '0–100%';
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
            // Weight front-and-centre with +/- steppers (hold to repeat) so the
            // common "about the same as last time" log is a couple of taps.
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  semanticLabel: 'Decrease weight',
                  onStep: () => _step(-0.1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    autofocus: true,
                    textAlign: TextAlign.center,
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
                ),
                const SizedBox(width: 12),
                _StepButton(
                  icon: Icons.add,
                  semanticLabel: 'Increase weight',
                  onStep: () => _step(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(dateLabel),
            ),
            const SizedBox(height: 8),
            // Note + body composition fold away (progressive disclosure) so the
            // fast path stays uncluttered.
            _DetailsSection(
              note: _noteController,
              bodyFat: _bodyFatController,
              muscle: _muscleController,
              water: _waterController,
              validator: _validatePct,
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
}

/// The optional fields (note + body-composition percentages) folded behind one
/// collapsible "details" disclosure, so the fast logging path stays a weight
/// and a Save. Composition maps to the nullable columns on the weigh-in row, so
/// it's captured alongside weight (as a smart scale does).
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.note,
    required this.bodyFat,
    required this.muscle,
    required this.water,
    required this.validator,
  });

  final TextEditingController note;
  final TextEditingController bodyFat;
  final TextEditingController muscle;
  final TextEditingController water;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Hide the ExpansionTile's default top/bottom dividers for a cleaner sheet.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
        title: const Text('Add a note or body composition (optional)'),
        children: [
          TextFormField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(bodyFat, 'Body fat')),
              const SizedBox(width: 12),
              Expanded(child: _field(muscle, 'Muscle')),
            ],
          ),
          const SizedBox(height: 12),
          _field(water, 'Water'),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          suffixText: '%',
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      );
}

/// A round +/- button that fires once on tap and then repeats while held
/// (hold-to-repeat), used by the weight steppers. Uses [GestureDetector] for
/// the press-and-hold semantics, with an explicit [Semantics] button label
/// since it isn't a standard button widget.
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onStep,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;

  void _start() {
    widget.onStep(); // immediate single step on press
    _timer?.cancel();
    // After a short hold, repeat until released.
    _timer = Timer(const Duration(milliseconds: 400), () {
      _timer = Timer.periodic(
        const Duration(milliseconds: 90),
        (_) => widget.onStep(),
      );
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.secondaryContainer,
          ),
          child: Icon(widget.icon, color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
