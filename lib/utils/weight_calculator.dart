import 'dart:math';

enum OneRmFormula {
  rpeRts,
  epley,
  brzycki,
  lombardi;

  String toStorageKey() => switch (this) {
        rpeRts => 'rpe_rts',
        epley => 'epley',
        brzycki => 'brzycki',
        lombardi => 'lombardi',
      };

  static OneRmFormula fromStorageKey(String key) => switch (key) {
        'epley' => epley,
        'brzycki' => brzycki,
        'lombardi' => lombardi,
        _ => rpeRts,
      };

  String get displayName => switch (this) {
        rpeRts => 'RPE / Rate of Perceived Exertion (default)',
        epley => 'Epley (rep-based)',
        brzycki => 'Brzycki (rep-based, 1–10 reps)',
        lombardi => 'Lombardi (rep-based)',
      };
}

/// Calculates a percentage of a base weight, rounded to nearest 5 lbs
///
/// Example: calculatePercentageWeight(310, 0.825) = 255.75 → 255 lbs
double calculatePercentageWeight(double baseWeight, double percentage) {
  if (baseWeight <= 0) return 0;
  final calculated = baseWeight * percentage;
  return _roundToNearest5(calculated);
}

/// Calculates warm-up progression (50%, 70%, 90% of first working set weight)
///
/// Returns a list of [warm-up 1, warm-up 2, warm-up 3] weights in lbs
/// Example: calculateWarmupProgression(260) = [130, 182, 234]
List<double> calculateWarmupProgression(double firstWorkingSetWeight) {
  if (firstWorkingSetWeight <= 0) return [0, 0, 0];

  return [
    calculatePercentageWeight(firstWorkingSetWeight, 0.50),
    calculatePercentageWeight(firstWorkingSetWeight, 0.70),
    calculatePercentageWeight(firstWorkingSetWeight, 0.90),
  ];
}

const rpeToPercent = {10: 1.00, 9: 0.94, 8: 0.88, 7: 0.82, 6: 0.76};

/// Estimates working weight from a 1RM and RPE target using standard RPE→%1RM table
double estimateWorkingWeightFromRpe(double oneRm, int rpeTarget) {
  final percentage = rpeToPercent[rpeTarget] ?? 0.75;
  return calculatePercentageWeight(oneRm, percentage);
}

/// Calculates estimated 1RM from actual weight lifted at given RPE
/// Uses standard RPE table to determine percentage of 1RM
/// Example: 135 lbs at RPE 7 (82% of 1RM) = 135 / 0.82 = ~164 lbs 1RM
double calculateOneRmFromLift(double weightLifted, int rpe) {
  final percentage = rpeToPercent[rpe] ?? 0.75;
  if (percentage == 0) return 0;
  return weightLifted / percentage;
}

/// Rounds a weight to the nearest 5 lbs
///
/// Examples:
/// - 182 → 180 (round to nearest 5, 182 is closer to 180)
/// - 183 → 185 (round to nearest 5, 183 is closer to 185)
/// - 259.875 → 260 (rounds to nearest 5)
double _roundToNearest5(double weight) {
  return (weight / 5).round() * 5.0;
}

/// Validates user input for reps (must be 1-999)
bool isValidReps(int reps) {
  return reps > 0 && reps <= 999;
}

/// Validates user input for weight (must be 0.1-999.9 lbs)
bool isValidWeight(double weight) {
  return weight > 0 && weight <= 999.9;
}

/// Validates user input for RPE (must be 1-10)
bool isValidRpe(int rpe) {
  return rpe >= 1 && rpe <= 10;
}

/// Estimates 1RM using the selected formula.
///
/// For rep-based formulas (Epley, Brzycki, Lombardi), [repsCompleted] is
/// required. If null, returns 0.0 (caller should treat as hard skip).
/// Guards: reps <= 0 returns [weightLifted]; Brzycki clamped to <= 20 reps.
double calculateOneRmFromLiftWithFormula(
  double weightLifted,
  int rpe,
  int? repsCompleted, {
  OneRmFormula formula = OneRmFormula.rpeRts,
}) {
  if (formula == OneRmFormula.rpeRts) {
    return calculateOneRmFromLift(weightLifted, rpe);
  }
  // Rep-based formulas require repsCompleted.
  if (repsCompleted == null) return 0.0;
  if (repsCompleted <= 0) return weightLifted;

  return switch (formula) {
    OneRmFormula.rpeRts => calculateOneRmFromLift(weightLifted, rpe),
    OneRmFormula.epley => weightLifted * (1 + repsCompleted / 30),
    OneRmFormula.brzycki => () {
        // Formula only reliable for 1–10 reps; clamp at 20 to avoid
        // near-singularity (reps=36 would give 36× weight as 1RM).
        if (repsCompleted > 20) {
          return weightLifted * (1 + repsCompleted / 30); // Epley fallback
        }
        return weightLifted * 36.0 / (37 - repsCompleted);
      }(),
    OneRmFormula.lombardi => weightLifted * pow(repsCompleted.toDouble(), 0.1),
  };
}
