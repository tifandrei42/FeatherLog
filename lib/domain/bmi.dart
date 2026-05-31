/// Pure-Dart BMI calculation and WHO classification.
///
/// This file has no Flutter or database imports by design (see DESIGN.md §1):
/// the domain layer is plain Dart so it can be unit-tested trivially. The UI
/// never does this math itself — it asks this layer.
library;

/// WHO BMI categories for adults (see RESEARCH.md §3).
///
/// Note: BMI is a population-level screening tool, not a diagnosis, and these
/// adult bands do not apply to children/teens. Surface that honestly in the UI.
enum BmiCategory {
  underweight,
  normal,
  overweight,
  obeseClassI,
  obeseClassII,
  obeseClassIII,
}

/// Human-readable label for a [BmiCategory].
extension BmiCategoryLabel on BmiCategory {
  String get label => switch (this) {
    BmiCategory.underweight => 'Underweight',
    BmiCategory.normal => 'Normal',
    BmiCategory.overweight => 'Overweight',
    BmiCategory.obeseClassI => 'Obese (class I)',
    BmiCategory.obeseClassII => 'Obese (class II)',
    BmiCategory.obeseClassIII => 'Obese (class III)',
  };
}

/// Computes BMI from canonical units: `weight_kg / (height_m)^2`.
///
/// Both inputs must be positive; throws [ArgumentError] otherwise so callers
/// never silently produce NaN/Infinity.
double calculateBmi({required double weightKg, required double heightCm}) {
  if (weightKg <= 0) {
    throw ArgumentError.value(weightKg, 'weightKg', 'must be positive');
  }
  if (heightCm <= 0) {
    throw ArgumentError.value(heightCm, 'heightCm', 'must be positive');
  }
  final heightM = heightCm / 100.0;
  return weightKg / (heightM * heightM);
}

/// Classifies a BMI value into its WHO [BmiCategory].
///
/// Boundaries follow the WHO convention where each band is closed at its lower
/// edge (e.g. exactly 18.5 is [BmiCategory.normal], exactly 25.0 is
/// [BmiCategory.overweight]).
BmiCategory bmiCategoryFor(double bmi) {
  if (bmi < 18.5) return BmiCategory.underweight;
  if (bmi < 25.0) return BmiCategory.normal;
  if (bmi < 30.0) return BmiCategory.overweight;
  if (bmi < 35.0) return BmiCategory.obeseClassI;
  if (bmi < 40.0) return BmiCategory.obeseClassII;
  return BmiCategory.obeseClassIII;
}
