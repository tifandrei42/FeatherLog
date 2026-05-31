/// Pure-Dart unit conversions.
///
/// Canonical storage is always metric — weight in kilograms, length in
/// centimetres (see DATA_MODEL.md §4). Units are a *display* concern: convert
/// on read for the UI, convert back to canonical before writing. The stored
/// numbers never change when the user flips kg↔lb, which avoids the classic
/// "changing units corrupts history" bug.
library;

/// Display unit for weight. Canonical unit is [WeightUnit.kg].
enum WeightUnit { kg, lb }

/// Display unit for length. Canonical unit is [LengthUnit.cm].
enum LengthUnit { cm, inch }

/// Exact conversion factors.
const double _poundsPerKilogram = 2.2046226218487757;
const double _centimetresPerInch = 2.54;

/// kg → lb.
double kgToLb(double kg) => kg * _poundsPerKilogram;

/// lb → kg.
double lbToKg(double lb) => lb / _poundsPerKilogram;

/// cm → inches.
double cmToIn(double cm) => cm / _centimetresPerInch;

/// inches → cm.
double inToCm(double inches) => inches * _centimetresPerInch;

/// Converts a canonical kilogram value into [unit] for display.
double weightFromKg(double kg, WeightUnit unit) => switch (unit) {
  WeightUnit.kg => kg,
  WeightUnit.lb => kgToLb(kg),
};

/// Converts a user-entered weight in [unit] back to canonical kilograms.
double weightToKg(double value, WeightUnit unit) => switch (unit) {
  WeightUnit.kg => value,
  WeightUnit.lb => lbToKg(value),
};

/// Converts a canonical centimetre value into [unit] for display.
double lengthFromCm(double cm, LengthUnit unit) => switch (unit) {
  LengthUnit.cm => cm,
  LengthUnit.inch => cmToIn(cm),
};

/// Converts a user-entered length in [unit] back to canonical centimetres.
double lengthToCm(double value, LengthUnit unit) => switch (unit) {
  LengthUnit.cm => value,
  LengthUnit.inch => inToCm(value),
};
