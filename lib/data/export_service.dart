import 'dart:convert';

import '../domain/bmi.dart';
import 'database.dart';

/// Serializes the user's data to the export formats in DATA_MODEL.md §7.
///
/// Pure string-producing functions (no file/share I/O) so they're easy to
/// unit-test. The current schema version written into JSON exports.
class ExportService {
  const ExportService();

  /// Export schema version (bumped when the export shape changes). v2 adds the
  /// optional body-composition fields; v1 files still import.
  static const schemaVersion = 2;

  /// ISO date (yyyy-MM-dd) of a timestamp, for the CSV convenience column.
  static String _isoDate(DateTime t) {
    final mm = t.month.toString().padLeft(2, '0');
    final dd = t.day.toString().padLeft(2, '0');
    return '${t.year}-$mm-$dd';
  }

  /// Lossless JSON backup (pretty-printed). [exportedAt] is injected so callers
  /// control the timestamp (keeps this function deterministic/testable).
  String toJson({
    required Profile? profile,
    required Setting? settings,
    required List<WeightEntry> entries,
    required DateTime exportedAt,
    List<BodyMeasurement> measurements = const [],
  }) {
    final map = {
      'schema_version': schemaVersion,
      'exported_at': exportedAt.toUtc().toIso8601String(),
      'profile': {
        'height_cm': profile?.heightCm,
        'goal_weight_kg': profile?.goalWeightKg,
        'sex': profile?.sex,
        'birth_date': profile?.birthDate?.toUtc().toIso8601String(),
      },
      'settings': {
        'weight_unit': settings?.weightUnit ?? 'kg',
        'length_unit': settings?.lengthUnit ?? 'cm',
        'theme': settings?.theme ?? 'system',
      },
      'entries': [
        for (final e in entries)
          {
            'measured_at': e.measuredAt.toUtc().toIso8601String(),
            'weight_kg': e.weightKg,
            'note': e.note,
            'body_fat_pct': e.bodyFatPct,
            'muscle_pct': e.musclePct,
            'water_pct': e.waterPct,
          },
      ],
      'measurements': [
        for (final m in measurements)
          {
            'measured_at': m.measuredAt.toUtc().toIso8601String(),
            'type': m.type,
            'value_cm': m.valueCm,
            'note': m.note,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Spreadsheet-friendly CSV. Includes a derived BMI column when height is
  /// known (computed at export time; never stored). Columns:
  /// measured_at, date, weight_kg, bmi, body_fat_pct, muscle_pct, water_pct, note.
  String toCsv({
    required Profile? profile,
    required List<WeightEntry> entries,
  }) {
    final height = profile?.heightCm;
    final buffer = StringBuffer()
      ..writeln(
        'measured_at,date,weight_kg,bmi,'
        'body_fat_pct,muscle_pct,water_pct,note',
      );
    for (final e in entries) {
      final bmi = (height != null && height > 0)
          ? calculateBmi(
              weightKg: e.weightKg,
              heightCm: height,
            ).toStringAsFixed(1)
          : '';
      final row = [
        e.measuredAt.toUtc().toIso8601String(),
        _isoDate(e.measuredAt),
        e.weightKg.toString(),
        bmi,
        e.bodyFatPct?.toString() ?? '',
        e.musclePct?.toString() ?? '',
        e.waterPct?.toString() ?? '',
        _csvField(e.note ?? ''),
      ];
      buffer.writeln(row.join(','));
    }
    return buffer.toString();
  }

  /// Quotes a CSV field if it contains a comma, quote, or newline (RFC 4180).
  static String _csvField(String value) {
    if (value.contains(RegExp('[",\n\r]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
