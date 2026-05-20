class SessionSummary {
  final int sessionId;
  final String workoutName;
  final DateTime dateCompleted;
  final int exerciseCount;
  final int totalSetsLogged;
  final double totalVolume;

  SessionSummary({
    required this.sessionId,
    required this.workoutName,
    required this.dateCompleted,
    required this.exerciseCount,
    required this.totalSetsLogged,
    required this.totalVolume,
  });

  SessionSummary.fromMap(Map<String, dynamic> map)
      : sessionId = map['session_id'],
        workoutName = map['workout_name'],
        dateCompleted = DateTime.parse(map['date_completed']),
        exerciseCount = map['exercise_count'],
        totalSetsLogged = map['total_sets'],
        totalVolume = (map['total_volume'] as num).toDouble();
}

class SessionDetailExercise {
  final String slotName;
  final String variantName;
  final List<SessionDetailSet> sets;

  SessionDetailExercise({
    required this.slotName,
    required this.variantName,
    required this.sets,
  });
}

class SessionDetailSet {
  final int setNumber;
  final String setType;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final double? targetWeight;
  final int? targetRpe;
  final int? actualReps;
  final double? actualWeight;
  final int? actualRpe;

  SessionDetailSet({
    required this.setNumber,
    required this.setType,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetWeight,
    this.targetRpe,
    this.actualReps,
    this.actualWeight,
    this.actualRpe,
  });

  SessionDetailSet.fromMap(Map<String, dynamic> map)
      : setNumber = map['set_number'],
        setType = map['set_type'],
        targetRepsMin = map['reps_target_min'],
        targetRepsMax = map['reps_target_max'],
        targetWeight = _computeTargetWeight(
          map['percentage_1rm'],
          map['one_rm_at_session_time'],
        ),
        targetRpe = map['rpe_target'],
        actualReps = map['reps_completed'],
        actualWeight = map['weight_lifted'],
        actualRpe = map['rpe_actual'];

  static double? _computeTargetWeight(
    double? percentage1rm,
    double? oneRmAtSessionTime,
  ) {
    if (percentage1rm == null || oneRmAtSessionTime == null) return null;
    final computed = percentage1rm * oneRmAtSessionTime;
    return (computed / 5).round() * 5.0;
  }
}
