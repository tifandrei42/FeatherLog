import 'package:featherlog/domain/bmi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateBmi', () {
    test('computes a known value', () {
      // 80 kg at 178 cm -> 25.25 (rounded)
      expect(calculateBmi(weightKg: 80, heightCm: 178), closeTo(25.25, 0.01));
    });

    test('a square-metre case is exact', () {
      // 1 m tall, 20 kg -> 20.0 exactly
      expect(calculateBmi(weightKg: 20, heightCm: 100), 20.0);
    });

    test('rejects non-positive weight', () {
      expect(
        () => calculateBmi(weightKg: 0, heightCm: 170),
        throwsArgumentError,
      );
    });

    test('rejects non-positive height', () {
      expect(
        () => calculateBmi(weightKg: 70, heightCm: 0),
        throwsArgumentError,
      );
    });
  });

  group('bmiCategoryFor', () {
    test('classifies representative values', () {
      expect(bmiCategoryFor(17.0), BmiCategory.underweight);
      expect(bmiCategoryFor(22.0), BmiCategory.normal);
      expect(bmiCategoryFor(27.0), BmiCategory.overweight);
      expect(bmiCategoryFor(32.0), BmiCategory.obeseClassI);
      expect(bmiCategoryFor(37.0), BmiCategory.obeseClassII);
      expect(bmiCategoryFor(42.0), BmiCategory.obeseClassIII);
    });

    test('band boundaries are closed at the lower edge', () {
      expect(bmiCategoryFor(18.5), BmiCategory.normal);
      expect(bmiCategoryFor(25.0), BmiCategory.overweight);
      expect(bmiCategoryFor(30.0), BmiCategory.obeseClassI);
      expect(bmiCategoryFor(35.0), BmiCategory.obeseClassII);
      expect(bmiCategoryFor(40.0), BmiCategory.obeseClassIII);
    });

    test('every category has a non-empty label', () {
      for (final c in BmiCategory.values) {
        expect(c.label, isNotEmpty);
      }
    });
  });
}
