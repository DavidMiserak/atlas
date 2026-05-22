import '../data/models/workout.dart';
import 'warmup_set_configs.dart';

/// Seconds per rep for barbell set execution (~4–6 s/rep).
const int kSecondsPerRep = 5;

/// Load, unrack, log, RPE per set.
const int kSetOverheadSeconds = 50;

/// Rack change, walk, variant screen between exercises.
const int kExerciseTransitionSeconds = 120;

/// Navigation, occasional 1RM prompt, water.
const int kSessionBufferSeconds = 300;

const int _roundingBucketSeconds = 900; // 15 minutes
const int _roundingStepMinutes = 15;
const int _minEstimateMinutes = 15;
const int _maxEstimateMinutes = 195;

class _ExpandedSet {
  final int reps;
  final int restSeconds;

  const _ExpandedSet({required this.reps, required this.restSeconds});
}

List<_ExpandedSet> _expandSetsForSlot(ExerciseSlot slot) {
  final sets = <_ExpandedSet>[];
  final templates = slot.setTemplates;
  if (templates.isEmpty) return sets;

  if (slot.isMainLift) {
    final workingRest = templates.first.restSeconds;
    for (final config in buildWarmupSetConfigs(workingRest)) {
      sets.add(
        _ExpandedSet(
          reps: config.reps,
          restSeconds: config.targetRestSeconds,
        ),
      );
    }
  }

  for (final template in templates) {
    sets.add(
      _ExpandedSet(
        reps: template.repsTargetMin ?? 5,
        restSeconds: template.restSeconds,
      ),
    );
  }

  return sets;
}

int _secondsForSlot(ExerciseSlot slot, {required bool includeTransition}) {
  final sets = _expandSetsForSlot(slot);
  if (sets.isEmpty) return includeTransition ? kExerciseTransitionSeconds : 0;

  var seconds = 0;
  for (final set in sets) {
    seconds += set.reps * kSecondsPerRep + kSetOverheadSeconds;
  }
  for (var i = 0; i < sets.length - 1; i++) {
    seconds += sets[i].restSeconds;
  }
  if (includeTransition) {
    seconds += kExerciseTransitionSeconds;
  }
  return seconds;
}

/// Raw seconds before 15-minute rounding (for tests).
int estimateWorkoutSeconds(Workout workout) {
  final slots = workout.exerciseSlots.toList()
    ..sort((a, b) => a.slotOrder.compareTo(b.slotOrder));

  var totalSeconds = kSessionBufferSeconds;
  for (var i = 0; i < slots.length; i++) {
    totalSeconds += _secondsForSlot(
      slots[i],
      includeTransition: i > 0,
    );
  }
  return totalSeconds;
}

int estimateWorkoutMinutes(Workout workout) {
  final totalSeconds = estimateWorkoutSeconds(workout);
  final rounded = ((totalSeconds / _roundingBucketSeconds).ceil() *
          _roundingStepMinutes)
      .clamp(_minEstimateMinutes, _maxEstimateMinutes);
  return rounded;
}

String formatEstimatedDuration(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h ${minutes}m';
}
