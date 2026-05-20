class Session {
  final int? id;
  final int workoutId;
  final DateTime dateCompleted;
  final bool isDeload;
  final String? notes;

  Session({
    this.id,
    required this.workoutId,
    required this.dateCompleted,
    this.isDeload = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': id,
      'workout_id': workoutId,
      'date_completed': dateCompleted.toIso8601String(),
      'is_deload': isDeload ? 1 : 0,
      'notes': notes,
    };
  }

  static Session fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['session_id'] as int?,
      workoutId: map['workout_id'] as int,
      dateCompleted: DateTime.parse(map['date_completed'] as String),
      isDeload: (map['is_deload'] as int?) == 1,
      notes: map['notes'] as String?,
    );
  }
}

class SessionExercise {
  final int? id;
  final int sessionId;
  final int slotId;
  final int chosenVariantId;

  SessionExercise({
    this.id,
    required this.sessionId,
    required this.slotId,
    required this.chosenVariantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_exercise_id': id,
      'session_id': sessionId,
      'slot_id': slotId,
      'chosen_variant_id': chosenVariantId,
    };
  }

  static SessionExercise fromMap(Map<String, dynamic> map) {
    return SessionExercise(
      id: map['session_exercise_id'] as int?,
      sessionId: map['session_id'] as int,
      slotId: map['slot_id'] as int,
      chosenVariantId: map['chosen_variant_id'] as int,
    );
  }

  SessionExercise copyWith({
    int? id,
    int? sessionId,
    int? slotId,
    int? chosenVariantId,
  }) {
    return SessionExercise(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      slotId: slotId ?? this.slotId,
      chosenVariantId: chosenVariantId ?? this.chosenVariantId,
    );
  }
}

class SessionSet {
  final int? id;
  final int sessionExerciseId;
  final int setNumber;
  final int? repsCompleted;
  final double? weightLifted;
  final double? oneRmAtSessionTime;
  final int? rpeActual;
  final String? notes;
  final DateTime? timestamp;

  SessionSet({
    this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    this.repsCompleted,
    this.weightLifted,
    this.oneRmAtSessionTime,
    this.rpeActual,
    this.notes,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_set_id': id,
      'session_exercise_id': sessionExerciseId,
      'set_number': setNumber,
      'reps_completed': repsCompleted,
      'weight_lifted': weightLifted,
      'one_rm_at_session_time': oneRmAtSessionTime,
      'rpe_actual': rpeActual,
      'notes': notes,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  static SessionSet fromMap(Map<String, dynamic> map) {
    return SessionSet(
      id: map['session_set_id'] as int?,
      sessionExerciseId: map['session_exercise_id'] as int,
      setNumber: map['set_number'] as int,
      repsCompleted: map['reps_completed'] as int?,
      weightLifted: map['weight_lifted'] as double?,
      oneRmAtSessionTime: map['one_rm_at_session_time'] as double?,
      rpeActual: map['rpe_actual'] as int?,
      notes: map['notes'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : null,
    );
  }
}

class OneRmHistory {
  final int? id;
  final int variantId;
  final double weight;
  final DateTime date;
  final String? notes;
  final bool isCurrent;

  OneRmHistory({
    this.id,
    required this.variantId,
    required this.weight,
    required this.date,
    this.notes,
    required this.isCurrent,
  });

  Map<String, dynamic> toMap() {
    return {
      'history_id': id,
      'variant_id': variantId,
      'weight': weight,
      'date': date.toIso8601String(),
      'notes': notes,
      'is_current': isCurrent ? 1 : 0,
    };
  }

  static OneRmHistory fromMap(Map<String, dynamic> map) {
    return OneRmHistory(
      id: map['history_id'] as int?,
      variantId: map['variant_id'] as int,
      weight: map['weight'] as double,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      isCurrent: (map['is_current'] as int?) == 1,
    );
  }
}
