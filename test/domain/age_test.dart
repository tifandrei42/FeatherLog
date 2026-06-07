import 'package:featherlog/domain/age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ageInYears', () {
    test('null birth date yields null', () {
      expect(ageInYears(null, asOf: DateTime(2026, 6, 7)), isNull);
    });

    test('counts completed years after the birthday', () {
      final born = DateTime(2000, 3, 15);
      expect(ageInYears(born, asOf: DateTime(2026, 6, 7)), 26);
    });

    test('does not count the current year before the birthday', () {
      final born = DateTime(2000, 9, 15);
      expect(ageInYears(born, asOf: DateTime(2026, 6, 7)), 25);
    });

    test('increments exactly on the birthday', () {
      final born = DateTime(2000, 6, 7);
      expect(ageInYears(born, asOf: DateTime(2026, 6, 6)), 25);
      expect(ageInYears(born, asOf: DateTime(2026, 6, 7)), 26);
    });

    test('ignores time-of-day on the birthday', () {
      final born = DateTime(2000, 6, 7, 23, 59);
      expect(ageInYears(born, asOf: DateTime(2026, 6, 7, 0, 1)), 26);
    });

    test('a leap-day birthday is handled', () {
      final born = DateTime(2000, 2, 29);
      // In a non-leap year, the day before Mar 1 still counts as not-yet.
      expect(ageInYears(born, asOf: DateTime(2026, 2, 28)), 25);
      expect(ageInYears(born, asOf: DateTime(2026, 3, 1)), 26);
    });

    test('a future birth date yields null, never a negative age', () {
      final born = DateTime(2030, 1, 1);
      expect(ageInYears(born, asOf: DateTime(2026, 6, 7)), isNull);
    });

    test('age 0 for an infant born earlier this year', () {
      final born = DateTime(2026, 1, 1);
      expect(ageInYears(born, asOf: DateTime(2026, 6, 7)), 0);
    });
  });

  group('adultBmiBandsApply', () {
    test('unknown birth date defaults to applicable', () {
      expect(adultBmiBandsApply(null, asOf: DateTime(2026, 6, 7)), isTrue);
    });

    test('a teen (known under 20) is not applicable', () {
      final born = DateTime(2010, 1, 1); // age 16
      expect(adultBmiBandsApply(born, asOf: DateTime(2026, 6, 7)), isFalse);
    });

    test('exactly 20 is applicable', () {
      final born = DateTime(2006, 6, 7); // turns 20 on asOf
      expect(adultBmiBandsApply(born, asOf: DateTime(2026, 6, 7)), isTrue);
    });

    test('19 (one day before turning 20) is not applicable', () {
      final born = DateTime(2006, 6, 8); // still 19 on asOf
      expect(adultBmiBandsApply(born, asOf: DateTime(2026, 6, 7)), isFalse);
    });
  });
}
