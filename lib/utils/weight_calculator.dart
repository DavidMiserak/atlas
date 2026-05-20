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

/// Estimates working weight from a 1RM and RPE target using standard RPE→%1RM table
double estimateWorkingWeightFromRpe(double oneRm, int rpeTarget) {
  const rpeToPercent = {
    10: 1.00,
    9: 0.94,
    8: 0.88,
    7: 0.82,
    6: 0.76,
  };
  final percentage = rpeToPercent[rpeTarget] ?? 0.75;
  return calculatePercentageWeight(oneRm, percentage);
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
