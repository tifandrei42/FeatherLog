/// Pure-Dart age derivation and BMI-interpretation context from the profile's
/// optional birth date.
///
/// This file has no Flutter or database imports by design (see DESIGN.md §1):
/// the domain layer is plain Dart so it can be unit-tested trivially. Nothing
/// here reads the wall clock — anything that depends on "now" takes an injected
/// [asOf] so the library stays pure and testable (mirrors stats.dart).
///
/// Deliberate non-goal (RESEARCH.md §3): we do NOT change the adult WHO BMI
/// bands by age or sex. For adults those bands are age/sex-independent, and for
/// children/teens BMI must be read against age/sex percentiles — which this app
/// does not implement. So the only thing age buys us here is honesty: a flag
/// that tells the UI when the adult bands should NOT be presented as if they
/// applied.
library;

/// The age in whole years at [asOf], or null when [birthDate] is unknown.
///
/// Counts completed years: the result only increments on or after the birthday.
/// A birth date in the future (relative to [asOf]) yields null rather than a
/// negative age, so a mis-entered date can never produce nonsense downstream.
int? ageInYears(DateTime? birthDate, {required DateTime asOf}) {
  if (birthDate == null) return null;

  // Compare on calendar-day granularity so a time-of-day difference can't flip
  // the birthday check.
  final born = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final on = DateTime(asOf.year, asOf.month, asOf.day);
  if (born.isAfter(on)) return null;

  var age = on.year - born.year;
  // If this year's birthday hasn't happened yet, we haven't completed that year.
  final hadBirthday =
      on.month > born.month || (on.month == born.month && on.day >= born.day);
  if (!hadBirthday) age--;
  return age;
}

/// The age below which the adult WHO BMI bands stop being the right lens.
///
/// The WHO adult classification applies to adults; children and adolescents
/// (roughly 2–19) need BMI-for-age percentiles instead. We use 20 as the
/// conservative adult threshold (RESEARCH.md §3).
const int adultBmiMinAge = 20;

/// Whether the adult WHO BMI bands can be presented as applicable.
///
/// Returns false only when the birth date is known *and* the derived age is
/// below [adultBmiMinAge] — i.e. we have positive evidence the person is a
/// child/teen, for whom adult bands are misleading. When the birth date is
/// unknown we return true: the app is an adult-oriented tool and there is no
/// reason to override its default interpretation (the BMI explainer already
/// notes BMI is a screening tool, not a diagnosis).
bool adultBmiBandsApply(DateTime? birthDate, {required DateTime asOf}) {
  final age = ageInYears(birthDate, asOf: asOf);
  if (age == null) return true;
  return age >= adultBmiMinAge;
}
