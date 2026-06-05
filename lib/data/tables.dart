import 'package:drift/drift.dart';

/// drift table definitions for FeatherLog.
///
/// Canonical-units rule (DATA_MODEL.md §4): weight is always stored in
/// kilograms and length in centimetres. Units are a display concern handled in
/// the domain layer (see `lib/domain/units.dart`); the stored numbers never
/// change when the user flips kg↔lb. BMI and statistics are never stored — they
/// are derived on demand from these rows.

/// The person being tracked. Single row in v1; the design keeps an id so
/// multi-profile support later is a migration, not a rewrite.
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Required for BMI; nullable until the user sets it.
  RealColumn get heightCm => real().nullable()();

  /// Optional target weight (canonical kg).
  RealColumn get goalWeightKg => real().nullable()();

  /// Optional, may refine BMI context / future age-sex formulas.
  TextColumn get sex => text().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One logged measurement. Belongs to a profile; constrained to one entry per
/// calendar day (editable) via a unique index on [date].
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The day this measurement is for. Unique → one entry per day.
  DateTimeColumn get date => dateTime().unique()();

  /// Canonical weight in kilograms (always kg, regardless of display unit).
  RealColumn get weightKg => real()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Presentation preferences. Single row, kept separate from [Profiles] because
/// these are UI choices, not identity/health facts.
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'kg' | 'lb' — display unit only; storage is always kg.
  TextColumn get weightUnit => text().withDefault(const Constant('kg'))();

  /// 'cm' | 'in' — display unit only; storage is always cm.
  TextColumn get lengthUnit => text().withDefault(const Constant('cm'))();

  /// 'system' | 'light' | 'dark'.
  TextColumn get theme => text().withDefault(const Constant('system'))();

  BoolColumn get showMovingAvg => boolean().withDefault(const Constant(true))();
  BoolColumn get showGoalLine => boolean().withDefault(const Constant(true))();
}
