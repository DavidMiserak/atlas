class PrRecord {
  final String variantName;
  final double prev;
  final double value;
  final bool is1rm;

  const PrRecord({
    required this.variantName,
    required this.prev,
    required this.value,
    required this.is1rm,
  });
}

class SessionSummary {
  final int sessionId;
  final String workoutName;
  final DateTime dateCompleted;
  final int exerciseCount;
  final int totalSetsLogged;
  final double totalVolume;
  final List<PrRecord> newPrs;
  final bool hasSessionNote;
  final bool hasSetNote;

  SessionSummary({
    required this.sessionId,
    required this.workoutName,
    required this.dateCompleted,
    required this.exerciseCount,
    required this.totalSetsLogged,
    required this.totalVolume,
    this.newPrs = const [],
    this.hasSessionNote = false,
    this.hasSetNote = false,
  });

  SessionSummary.fromMap(Map<String, dynamic> map)
      : sessionId = map['session_id'],
        workoutName = map['workout_name'],
        dateCompleted = DateTime.parse(map['date_completed']),
        exerciseCount = map['exercise_count'],
        totalSetsLogged = map['total_sets'],
        totalVolume = (map['total_volume'] as num).toDouble(),
        newPrs = const [],
        hasSessionNote = (map['has_session_note'] as int? ?? 0) != 0,
        hasSetNote = (map['has_set_note'] as int? ?? 0) != 0;
}

class SessionDetailExercise {
  final String slotName;
  final String variantName;
  final List<SessionDetailSet> sets;
  final double? sessionPr;
  final double? allTimePr;
  final double? session1rm;
  final double? allTime1rm;
  final List<PrRecord> newPrs;

  SessionDetailExercise({
    required this.slotName,
    required this.variantName,
    required this.sets,
    this.sessionPr,
    this.allTimePr,
    this.session1rm,
    this.allTime1rm,
    this.newPrs = const [],
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
  final double? oneRmAtSessionTime;
  final String? notes;

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
    this.oneRmAtSessionTime,
    this.notes,
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
        actualRpe = map['rpe_actual'],
        oneRmAtSessionTime = (map['one_rm_at_session_time'] as num?)?.toDouble(),
        notes = map['notes'] as String?;

  static double? _computeTargetWeight(
    double? percentage1rm,
    double? oneRmAtSessionTime,
  ) {
    if (percentage1rm == null || oneRmAtSessionTime == null) return null;
    final computed = percentage1rm * oneRmAtSessionTime;
    return (computed / 5).round() * 5.0;
  }
}
