import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/utils/weight_calculator.dart';

void main() {
  group('calculatePercentageWeight', () {
    test('calculates 82.5% of 310 lbs correctly (MVP primary use case)', () {
      final weight = calculatePercentageWeight(310, 0.825);
      expect(weight, 255.0); // 310 * 0.825 = 255.75 → 255
    });

    test('calculates 50% of 260 lbs correctly', () {
      final weight = calculatePercentageWeight(260, 0.50);
      expect(weight, 130.0);
    });

    test('calculates 70% of 260 lbs correctly', () {
      final weight = calculatePercentageWeight(260, 0.70);
      expect(weight, 180.0); // 260 * 0.70 = 182 → round to nearest 5 = 180
    });

    test('calculates 90% of 260 lbs correctly', () {
      final weight = calculatePercentageWeight(260, 0.90);
      expect(weight, 235.0); // 260 * 0.90 = 234 → round to nearest 5 = 235
    });

    test('rounds to nearest 5 lbs', () {
      // Test edge cases
      expect(calculatePercentageWeight(100, 0.51), 50.0); // 51 → 50
      expect(calculatePercentageWeight(100, 0.53), 55.0); // 53 → 55
      expect(calculatePercentageWeight(100, 0.525), 55.0); // 52.5 → 55
    });

    test('returns 0 for zero base weight', () {
      final weight = calculatePercentageWeight(0, 0.825);
      expect(weight, 0.0);
    });

    test('returns 0 for negative base weight', () {
      final weight = calculatePercentageWeight(-100, 0.825);
      expect(weight, 0.0);
    });
  });

  group('calculateWarmupProgression', () {
    test('calculates correct warm-up progression (MVP primary use case)', () {
      final warmups = calculateWarmupProgression(260);
      expect(warmups, [130.0, 180.0, 235.0]); // 50%, 70% rounded, 90% rounded
    });

    test('calculates warm-up progression for 310 lbs', () {
      final warmups = calculateWarmupProgression(310);
      expect(warmups[0], 155.0); // 50%
      expect(warmups[1], 215.0); // 70% = 217 → 215
      expect(warmups[2], 280.0); // 90% = 279 → 280
    });

    test('returns [0, 0, 0] for zero weight', () {
      final warmups = calculateWarmupProgression(0);
      expect(warmups, [0.0, 0.0, 0.0]);
    });

    test('returns [0, 0, 0] for negative weight', () {
      final warmups = calculateWarmupProgression(-100);
      expect(warmups, [0.0, 0.0, 0.0]);
    });

    test('handles small weights correctly', () {
      final warmups = calculateWarmupProgression(10);
      expect(warmups[0], 5.0); // 50%
      expect(warmups[1], 5.0); // 70% = 7 → round to nearest 5 = 5
      expect(warmups[2], 10.0); // 90% = 9 → round to nearest 5 = 10
    });
  });

  group('Input Validation', () {
    test('isValidReps returns true for 1-999', () {
      expect(isValidReps(1), true);
      expect(isValidReps(10), true);
      expect(isValidReps(999), true);
    });

    test('isValidReps returns false for invalid values', () {
      expect(isValidReps(0), false);
      expect(isValidReps(-1), false);
      expect(isValidReps(1000), false);
    });

    test('isValidWeight returns true for 0.1-999.9 lbs', () {
      expect(isValidWeight(0.1), true);
      expect(isValidWeight(100.0), true);
      expect(isValidWeight(999.9), true);
    });

    test('isValidWeight returns false for invalid values', () {
      expect(isValidWeight(0.0), false);
      expect(isValidWeight(-10.0), false);
      expect(isValidWeight(1000.0), false);
    });

    test('isValidRpe returns true for 1-10', () {
      expect(isValidRpe(1), true);
      expect(isValidRpe(5), true);
      expect(isValidRpe(10), true);
    });

    test('isValidRpe returns false for invalid values', () {
      expect(isValidRpe(0), false);
      expect(isValidRpe(-1), false);
      expect(isValidRpe(11), false);
    });
  });
}
