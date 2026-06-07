import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// Outcome of parsing an import file. Either [ok] with parsed, ready-to-write
/// data, or a failure carrying a human-readable [error]. Parsing never throws
/// into the caller and never touches the database — the UI validates first,
/// then writes, so a malformed file can't corrupt existing data
/// (US-11.4, DATA_MODEL.md §6).
class ImportResult {
  const ImportResult._({
    this.error,
    this.entries = const [],
    this.heightCm,
    this.goalWeightKg,
    this.weightUnit,
    this.lengthUnit,
    this.theme,
  });

  factory ImportResult.failure(String error) => ImportResult._(error: error);

  factory ImportResult.success({
    required List<WeightEntriesCompanion> entries,
    double? heightCm,
    double? goalWeightKg,
    String? weightUnit,
    String? lengthUnit,
    String? theme,
  }) => ImportResult._(
    entries: entries,
    heightCm: heightCm,
    goalWeightKg: goalWeightKg,
    weightUnit: weightUnit,
    lengthUnit: lengthUnit,
    theme: theme,
  );

  final String? error;
  final List<WeightEntriesCompanion> entries;
  final double? heightCm;
  final double? goalWeightKg;
  final String? weightUnit;
  final String? lengthUnit;
  final String? theme;

  bool get isOk => error == null;
}

/// Parses a FeatherLog JSON export (the format written by [ExportService]).
class ImportService {
  const ImportService();

  static const supportedSchemaVersion = 2;

  /// Parses [jsonString] into an [ImportResult]. Returns a failure (never
  /// throws) for malformed JSON, wrong shape, unsupported schema, or invalid
  /// values. De-duplicates entries by `measured_at`, keeping the last
  /// occurrence (last-write-wins within the file).
  ImportResult parse(String jsonString) {
    Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      return ImportResult.failure("This file isn't valid JSON.");
    }
    if (decoded is! Map<String, dynamic>) {
      return ImportResult.failure(
        "This doesn't look like a FeatherLog backup.",
      );
    }

    final version = decoded['schema_version'];
    if (version is! int) {
      return ImportResult.failure('Missing or invalid schema_version.');
    }
    if (version > supportedSchemaVersion) {
      return ImportResult.failure(
        'This backup is from a newer version of FeatherLog.',
      );
    }

    final rawEntries = decoded['entries'];
    if (rawEntries is! List) {
      return ImportResult.failure('Backup has no entries list.');
    }

    // De-dupe by measured_at (last occurrence wins).
    final byTimestamp = <DateTime, WeightEntriesCompanion>{};
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) {
        return ImportResult.failure('An entry is malformed.');
      }
      final at = DateTime.tryParse('${raw['measured_at']}');
      final kg = (raw['weight_kg'] as num?)?.toDouble();
      if (at == null) {
        return ImportResult.failure('An entry has an invalid date.');
      }
      if (kg == null || kg <= 0 || kg > 1000) {
        return ImportResult.failure('An entry has an invalid weight.');
      }
      final note = raw['note'] as String?;

      // Optional body-composition percentages (absent in v1 files). Reject
      // out-of-range values rather than silently storing nonsense.
      final pct = _parsePercents(raw);
      if (pct == null) {
        return ImportResult.failure('An entry has an invalid percentage.');
      }

      byTimestamp[at] = WeightEntriesCompanion.insert(
        measuredAt: at,
        weightKg: kg,
        note: Value(note),
        bodyFatPct: Value(pct.bodyFat),
        musclePct: Value(pct.muscle),
        waterPct: Value(pct.water),
      );
    }

    final profile = decoded['profile'];
    final settings = decoded['settings'];

    return ImportResult.success(
      entries: byTimestamp.values.toList(),
      heightCm: profile is Map
          ? (profile['height_cm'] as num?)?.toDouble()
          : null,
      goalWeightKg: profile is Map
          ? (profile['goal_weight_kg'] as num?)?.toDouble()
          : null,
      weightUnit: settings is Map ? settings['weight_unit'] as String? : null,
      lengthUnit: settings is Map ? settings['length_unit'] as String? : null,
      theme: settings is Map ? settings['theme'] as String? : null,
    );
  }

  /// Parses the optional body-composition percentages from an entry map.
  /// Returns a record of (possibly null) values, or null if any present value
  /// is not a number in 0–100. Absent fields are valid and yield null.
  ({double? bodyFat, double? muscle, double? water})? _parsePercents(
    Map<String, dynamic> raw,
  ) {
    for (final key in const ['body_fat_pct', 'muscle_pct', 'water_pct']) {
      final v = raw[key];
      if (v == null) continue;
      if (v is! num || v < 0 || v > 100) return null;
    }
    double? read(String key) => (raw[key] as num?)?.toDouble();
    return (
      bodyFat: read('body_fat_pct'),
      muscle: read('muscle_pct'),
      water: read('water_pct'),
    );
  }
}
