import 'package:featherlog/domain/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weight conversions', () {
    test('kg -> lb known value', () {
      expect(kgToLb(100), closeTo(220.462, 0.001));
    });

    test('lb -> kg known value', () {
      expect(lbToKg(220.462), closeTo(100, 0.001));
    });

    test('round-trips back to the original', () {
      expect(lbToKg(kgToLb(73.5)), closeTo(73.5, 1e-9));
    });
  });

  group('length conversions', () {
    test('cm -> in known value', () {
      expect(cmToIn(2.54), closeTo(1.0, 1e-9));
    });

    test('in -> cm known value', () {
      expect(inToCm(10), closeTo(25.4, 1e-9));
    });

    test('round-trips back to the original', () {
      expect(cmToIn(inToCm(178)), closeTo(178, 1e-9));
    });
  });

  group('canonical helpers', () {
    test('weightFromKg / weightToKg respect the unit', () {
      expect(weightFromKg(80, WeightUnit.kg), 80);
      expect(weightFromKg(80, WeightUnit.lb), closeTo(176.37, 0.01));
      expect(weightToKg(176.370, WeightUnit.lb), closeTo(80, 0.01));
    });

    test('lengthFromCm / lengthToCm respect the unit', () {
      expect(lengthFromCm(180, LengthUnit.cm), 180);
      expect(lengthFromCm(180, LengthUnit.inch), closeTo(70.866, 0.001));
      expect(lengthToCm(70.866, LengthUnit.inch), closeTo(180, 0.01));
    });

    test('switching display units never changes the stored value', () {
      // The canonical value is the invariant: convert out and back in.
      const storedKg = 64.2;
      final shownAsLb = weightFromKg(storedKg, WeightUnit.lb);
      expect(weightToKg(shownAsLb, WeightUnit.lb), closeTo(storedKg, 1e-9));
    });
  });
}
