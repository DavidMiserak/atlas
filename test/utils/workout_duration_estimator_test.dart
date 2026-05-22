import 'package:atlas/data/models/workout.dart';
import 'package:atlas/utils/workout_duration_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

Workout _workoutWithSlots(List<ExerciseSlot> slots) {
  return Workout(
    id: 1,
    programId: 1,
    name: 'Test Day',
    dayNumber: 1,
    orderInProgram: 1,
    exerciseSlots: slots,
  );
}

ExerciseSlot _slot({
  required int slotOrder,
  required bool isMainLift,
  required List<SetTemplate> templates,
}) {
  return ExerciseSlot(
    id: slotOrder,
    workoutId: 1,
    name: 'Slot $slotOrder',
    slotOrder: slotOrder,
    isMainLift: isMainLift,
    setTemplates: templates,
  );
}

SetTemplate _template({
  required int setNumber,
  int reps = 5,
  int restSeconds = 180,
}) {
  return SetTemplate(
    slotId: 1,
    setNumber: setNumber,
    setType: 'working',
    repsTargetMin: reps,
    restSeconds: restSeconds,
  );
}

void main() {
  group('formatEstimatedDuration', () {
    test('formats sub-hour as 0h Xm', () {
      expect(formatEstimatedDuration(45), '0h 45m');
    });

    test('formats hour and remainder', () {
      expect(formatEstimatedDuration(75), '1h 15m');
    });
  });

  group('estimateWorkoutSeconds', () {
    test('counts rest only between sets not after last set', () {
      final workout = _workoutWithSlots([
        _slot(
          slotOrder: 1,
          isMainLift: false,
          templates: [
            _template(setNumber: 1, reps: 5, restSeconds: 100),
            _template(setNumber: 2, reps: 5, restSeconds: 100),
            _template(setNumber: 3, reps: 5, restSeconds: 100),
          ],
        ),
      ]);

      // 3 sets: work 3*(5*5+50)=225, rest 2*100=200, buffer 300 → 725
      expect(estimateWorkoutSeconds(workout), 725);
    });

    test('main lift includes warmup reps and rests', () {
      final accessoryOnly = _workoutWithSlots([
        _slot(
          slotOrder: 1,
          isMainLift: false,
          templates: [_template(setNumber: 1, reps: 5, restSeconds: 180)],
        ),
      ]);
      final withWarmups = _workoutWithSlots([
        _slot(
          slotOrder: 1,
          isMainLift: true,
          templates: [_template(setNumber: 1, reps: 5, restSeconds: 180)],
        ),
      ]);

      expect(
        estimateWorkoutSeconds(withWarmups),
        greaterThan(estimateWorkoutSeconds(accessoryOnly)),
      );
    });

    test('adds transition between exercises not before first', () {
      final oneExercise = _workoutWithSlots([
        _slot(
          slotOrder: 1,
          isMainLift: false,
          templates: [_template(setNumber: 1)],
        ),
      ]);
      final twoExercises = _workoutWithSlots([
        _slot(
          slotOrder: 1,
          isMainLift: false,
          templates: [_template(setNumber: 1)],
        ),
        _slot(
          slotOrder: 2,
          isMainLift: false,
          templates: [_template(setNumber: 1)],
        ),
      ]);

      expect(
        estimateWorkoutSeconds(twoExercises) -
            estimateWorkoutSeconds(oneExercise),
        195, // second slot work + transition
      );
    });
  });

  group('estimateWorkoutMinutes', () {
    test('rounds up to 15-minute buckets', () {
      final workout = _workoutWithSlots([
        _slot(
          slotOrder: 1,
          isMainLift: false,
          templates: [_template(setNumber: 1, reps: 5, restSeconds: 60)],
        ),
      ]);

      final minutes = estimateWorkoutMinutes(workout);
      expect(minutes % 15, 0);
      expect(minutes, greaterThanOrEqualTo(15));
    });

    test('heavy lower day with two main lifts is at least 60 minutes', () {
      SetTemplate triple(int rest) => _template(
            setNumber: 1,
            reps: 5,
            restSeconds: rest,
          );

      final workout = _workoutWithSlots([
        _slot(
          slotOrder: 1,
          isMainLift: true,
          templates: [
            triple(180),
            _template(setNumber: 2, reps: 5, restSeconds: 180),
            _template(setNumber: 3, reps: 5, restSeconds: 180),
          ],
        ),
        _slot(
          slotOrder: 2,
          isMainLift: true,
          templates: [
            triple(180),
            _template(setNumber: 2, reps: 5, restSeconds: 180),
            _template(setNumber: 3, reps: 5, restSeconds: 180),
          ],
        ),
        _slot(
          slotOrder: 3,
          isMainLift: false,
          templates: [
            _template(setNumber: 1, reps: 8, restSeconds: 120),
            _template(setNumber: 2, reps: 8, restSeconds: 120),
            _template(setNumber: 3, reps: 8, restSeconds: 120),
          ],
        ),
        _slot(
          slotOrder: 4,
          isMainLift: false,
          templates: [
            _template(setNumber: 1, reps: 8, restSeconds: 90),
            _template(setNumber: 2, reps: 8, restSeconds: 90),
            _template(setNumber: 3, reps: 8, restSeconds: 90),
            _template(setNumber: 4, reps: 8, restSeconds: 90),
          ],
        ),
      ]);

      expect(estimateWorkoutMinutes(workout), greaterThanOrEqualTo(60));
    });
  });
}
