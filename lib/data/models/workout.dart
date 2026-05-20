class Workout {
  final int? id;
  final int programId;
  final String name;
  final int dayNumber;
  final int orderInProgram;
  final String? notes;
  final List<ExerciseSlot> exerciseSlots;

  Workout({
    this.id,
    required this.programId,
    required this.name,
    required this.dayNumber,
    required this.orderInProgram,
    this.notes,
    this.exerciseSlots = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'workout_id': id,
      'program_id': programId,
      'name': name,
      'day_number': dayNumber,
      'order_in_program': orderInProgram,
      'notes': notes,
    };
  }

  static Workout fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['workout_id'] as int?,
      programId: map['program_id'] as int,
      name: map['name'] as String,
      dayNumber: map['day_number'] as int,
      orderInProgram: map['order_in_program'] as int,
      notes: map['notes'] as String?,
    );
  }

  Workout copyWith({
    int? id,
    int? programId,
    String? name,
    int? dayNumber,
    int? orderInProgram,
    String? notes,
    List<ExerciseSlot>? exerciseSlots,
  }) {
    return Workout(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      dayNumber: dayNumber ?? this.dayNumber,
      orderInProgram: orderInProgram ?? this.orderInProgram,
      notes: notes ?? this.notes,
      exerciseSlots: exerciseSlots ?? this.exerciseSlots,
    );
  }
}

class ExerciseSlot {
  final int? id;
  final int workoutId;
  final String name;
  final int slotOrder;
  final String? category;
  final List<ExerciseVariant> variants;
  final List<SetTemplate> setTemplates;

  ExerciseSlot({
    this.id,
    required this.workoutId,
    required this.name,
    required this.slotOrder,
    this.category,
    this.variants = const [],
    this.setTemplates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'slot_id': id,
      'workout_id': workoutId,
      'name': name,
      'slot_order': slotOrder,
      'category': category,
    };
  }

  static ExerciseSlot fromMap(Map<String, dynamic> map) {
    return ExerciseSlot(
      id: map['slot_id'] as int?,
      workoutId: map['workout_id'] as int,
      name: map['name'] as String,
      slotOrder: map['slot_order'] as int,
      category: map['category'] as String?,
    );
  }

  ExerciseSlot copyWith({
    int? id,
    int? workoutId,
    String? name,
    int? slotOrder,
    String? category,
    List<ExerciseVariant>? variants,
    List<SetTemplate>? setTemplates,
  }) {
    return ExerciseSlot(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      name: name ?? this.name,
      slotOrder: slotOrder ?? this.slotOrder,
      category: category ?? this.category,
      variants: variants ?? this.variants,
      setTemplates: setTemplates ?? this.setTemplates,
    );
  }
}

class ExerciseVariant {
  final int? id;
  final int slotId;
  final String name;
  final String? description;

  ExerciseVariant({
    this.id,
    required this.slotId,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'variant_id': id,
      'slot_id': slotId,
      'name': name,
      'description': description,
    };
  }

  static ExerciseVariant fromMap(Map<String, dynamic> map) {
    return ExerciseVariant(
      id: map['variant_id'] as int?,
      slotId: map['slot_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }
}

class SetTemplate {
  final int? id;
  final int slotId;
  final int setNumber;
  final String setType; // 'warm-up', 'working', 'back-off'
  final int? repsTargetMin;
  final int? repsTargetMax;
  final double? percentage1rm;
  final int? rpeTarget;
  final int restSeconds;

  SetTemplate({
    this.id,
    required this.slotId,
    required this.setNumber,
    required this.setType,
    this.repsTargetMin,
    this.repsTargetMax,
    this.percentage1rm,
    this.rpeTarget,
    required this.restSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'set_template_id': id,
      'slot_id': slotId,
      'set_number': setNumber,
      'set_type': setType,
      'reps_target_min': repsTargetMin,
      'reps_target_max': repsTargetMax,
      'percentage_1rm': percentage1rm,
      'rpe_target': rpeTarget,
      'rest_seconds': restSeconds,
    };
  }

  static SetTemplate fromMap(Map<String, dynamic> map) {
    return SetTemplate(
      id: map['set_template_id'] as int?,
      slotId: map['slot_id'] as int,
      setNumber: map['set_number'] as int,
      setType: map['set_type'] as String,
      repsTargetMin: map['reps_target_min'] as int?,
      repsTargetMax: map['reps_target_max'] as int?,
      percentage1rm: map['percentage_1rm'] as double?,
      rpeTarget: map['rpe_target'] as int?,
      restSeconds: map['rest_seconds'] as int,
    );
  }
}
