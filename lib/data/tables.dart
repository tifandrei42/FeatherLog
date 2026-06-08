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

/// One logged measurement. Belongs to a profile. Stores a full [measuredAt]
/// timestamp and is NOT constrained to one row per day, so multiple readings on
/// the same day are kept without data loss (DATA_MODEL.md §3). The trend/stats
/// aggregate to one value per day in the domain layer.
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Full timestamp of the reading (date + time). Not unique — several readings
  /// per day are allowed; aggregation to a single daily value happens on read.
  DateTimeColumn get measuredAt => dateTime()();

  /// Canonical weight in kilograms (always kg, regardless of display unit).
  RealColumn get weightKg => real()();

  TextColumn get note => text().nullable()();

  /// Optional body-composition percentages (0–100), nullable so existing rows
  /// and weight-only entries stay valid. Free in FeatherLog (DATA_MODEL.md §8).
  RealColumn get bodyFatPct => real().nullable()();
  RealColumn get musclePct => real().nullable()();
  RealColumn get waterPct => real().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Body measurements (waist, chest, hips, neck, thigh, …), stored **long
/// format**: one row per reading with a [type] discriminator, so adding a new
/// body part is data, not a schema migration. Value is canonical centimetres;
/// display conversion (cm/in) happens in the UI via units.dart. Like
/// WeightEntries, multiple readings per day are allowed.
class BodyMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Full timestamp of the reading.
  DateTimeColumn get measuredAt => dateTime()();

  /// Which body part, e.g. 'waist' | 'chest' | 'hips' | 'neck' | 'thigh'.
  TextColumn get type => text()();

  /// Canonical measurement in centimetres.
  RealColumn get valueCm => real()();

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

  /// Selected accent palette id (see `featherPalettes`). Display-only preference.
  TextColumn get palette => text().withDefault(const Constant('meadow'))();

  /// Opt-in: check GitHub for a newer release on launch. Off by default so the
  /// app stays zero-network unless the user asks for it (PRIVACY.md).
  BoolColumn get checkUpdates => boolean().withDefault(const Constant(false))();

  /// The release tag the user dismissed from the update banner (e.g. 'v1.2.0'),
  /// so a declined update isn't shown again. Null until something is dismissed.
  TextColumn get dismissedUpdateVersion => text().nullable()();
}
