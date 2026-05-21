import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/utils/weight_calculator.dart';

void main() {
  group('OneRmFormula storage keys round-trip', () {
    for (final formula in OneRmFormula.values) {
      test('${formula.name} survives toStorageKey / fromStorageKey', () {
        expect(OneRmFormula.fromStorageKey(formula.toStorageKey()), formula);
      });
    }

    test('unknown key defaults to rpeRts', () {
      expect(OneRmFormula.fromStorageKey('garbage'), OneRmFormula.rpeRts);
    });
  });

  group('calculateOneRmFromLiftWithFormula — rpeRts', () {
    test('delegates to RPE lookup (rpe=8, reps ignored)', () {
      // RPE path does not use repsCompleted at all
      final r1 = calculateOneRmFromLiftWithFormula(300, 8, null, formula: OneRmFormula.rpeRts);
      final r2 = calculateOneRmFromLiftWithFormula(300, 8, 5, formula: OneRmFormula.rpeRts);
      expect(r1, equals(r2));
      expect(r1, greaterThan(300));
    });
  });

  group('calculateOneRmFromLiftWithFormula — null / zero reps guard', () {
    for (final formula in [OneRmFormula.epley, OneRmFormula.brzycki, OneRmFormula.lombardi]) {
      test('${formula.name}: null reps → 0.0 (hard skip)', () {
        expect(
          calculateOneRmFromLiftWithFormula(300, 8, null, formula: formula),
          0.0,
        );
      });

      test('${formula.name}: reps=0 → returns weightLifted as 1RM', () {
        expect(
          calculateOneRmFromLiftWithFormula(300, 8, 0, formula: formula),
          300.0,
        );
      });
    }
  });

  group('calculateOneRmFromLiftWithFormula — Epley', () {
    test('1 rep at 300 lbs → 1RM ≈ 310 (300*(1+1/30))', () {
      final result = calculateOneRmFromLiftWithFormula(300, 8, 1, formula: OneRmFormula.epley);
      expect(result, closeTo(310.0, 0.1));
    });

    test('5 reps at 300 lbs → 1RM ≈ 350', () {
      final result = calculateOneRmFromLiftWithFormula(300, 8, 5, formula: OneRmFormula.epley);
      expect(result, closeTo(350.0, 0.1));
    });

    test('37 reps (high reps) → result is positive and > weight', () {
      final result = calculateOneRmFromLiftWithFormula(100, 8, 37, formula: OneRmFormula.epley);
      expect(result, greaterThan(100));
    });
  });

  group('calculateOneRmFromLiftWithFormula — Brzycki', () {
    test('1 rep at 300 lbs → 1RM = 300 (300*36/36)', () {
      final result = calculateOneRmFromLiftWithFormula(300, 8, 1, formula: OneRmFormula.brzycki);
      expect(result, closeTo(300.0, 0.01));
    });

    test('5 reps at 300 lbs → 1RM = 337.5 (300*36/32)', () {
      final result = calculateOneRmFromLiftWithFormula(300, 8, 5, formula: OneRmFormula.brzycki);
      expect(result, closeTo(337.5, 0.01));
    });

    test('reps=20 (boundary) uses Brzycki formula', () {
      final result = calculateOneRmFromLiftWithFormula(100, 8, 20, formula: OneRmFormula.brzycki);
      // 100 * 36 / (37 - 20) = 100 * 36 / 17 ≈ 211.76
      expect(result, closeTo(211.76, 0.01));
    });

    test('reps=21 (above boundary) falls back to Epley', () {
      final epley = calculateOneRmFromLiftWithFormula(100, 8, 21, formula: OneRmFormula.epley);
      final brzycki = calculateOneRmFromLiftWithFormula(100, 8, 21, formula: OneRmFormula.brzycki);
      expect(brzycki, closeTo(epley, 0.01));
    });

    test('reps=36 does NOT produce a catastrophically high 1RM', () {
      final result = calculateOneRmFromLiftWithFormula(100, 8, 36, formula: OneRmFormula.brzycki);
      // Falls back to Epley: 100*(1+36/30) = 100*2.2 = 220, not 4860
      expect(result, lessThan(300));
    });
  });

  group('calculateOneRmFromLiftWithFormula — Lombardi', () {
    test('1 rep at 300 lbs → 1RM = 300 (pow(1,0.1)=1)', () {
      final result = calculateOneRmFromLiftWithFormula(300, 8, 1, formula: OneRmFormula.lombardi);
      expect(result, closeTo(300.0, 0.01));
    });

    test('5 reps at 300 lbs → 1RM ≈ 355.4 (300*5^0.1)', () {
      final result = calculateOneRmFromLiftWithFormula(300, 8, 5, formula: OneRmFormula.lombardi);
      // 5^0.1 ≈ 1.1746..., 300 * 1.1746 ≈ 352.4
      expect(result, greaterThan(300));
      expect(result, lessThan(400));
    });
  });
}
