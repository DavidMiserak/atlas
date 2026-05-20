import '../database/app_database.dart';
import '../database/database_constants.dart';
import '../models/program.dart';
import '../models/workout.dart';

class ProgramRepository {
  /// Get program by ID with all associated workouts and exercise data
  Future<Program?> getProgramById(int programId) async {
    final db = await getDatabase();

    final programMap = await db.query(
      TABLE_PROGRAMS,
      where: '$COL_PROGRAM_ID = ?',
      whereArgs: [programId],
    );

    if (programMap.isEmpty) return null;

    final program = Program.fromMap(programMap.first);

    // Load workouts
    final workoutMaps = await db.query(
      TABLE_WORKOUTS,
      where: '$COL_WORKOUT_PROGRAM_ID = ?',
      whereArgs: [programId],
      orderBy: '$COL_WORKOUT_ORDER_IN_PROGRAM ASC',
    );

    final workouts = <Workout>[];
    for (final workoutMap in workoutMaps) {
      final workout = Workout.fromMap(workoutMap);
      final slots = await _getExerciseSlotsForWorkout(workout.id!);
      workouts.add(workout.copyWith(exerciseSlots: slots));
    }

    return program.copyWith(workouts: workouts);
  }

  /// Get all programs
  Future<List<Program>> getAllPrograms() async {
    final db = await getDatabase();
    final programMaps = await db.query(TABLE_PROGRAMS);
    return programMaps.map((map) => Program.fromMap(map)).toList();
  }

  /// Create a new program
  Future<int> createProgram(Program program) async {
    final db = await getDatabase();
    return await db.insert(TABLE_PROGRAMS, program.toMap());
  }

  /// Get exercise variant by ID
  Future<ExerciseVariant?> getVariantById(int variantId) async {
    final db = await getDatabase();

    final variantMaps = await db.query(
      TABLE_EXERCISE_VARIANTS,
      where: '$COL_VARIANT_ID = ?',
      whereArgs: [variantId],
    );

    if (variantMaps.isEmpty) return null;
    return ExerciseVariant.fromMap(variantMaps.first);
  }

  /// Get set templates for a slot
  Future<List<SetTemplate>> getSetTemplatesForSlot(int slotId) async {
    return _getSetTemplatesForSlot(slotId);
  }

  /// Get exercise slots for a workout with variants and set templates
  Future<List<ExerciseSlot>> _getExerciseSlotsForWorkout(
      int workoutId) async {
    final db = await getDatabase();

    final slotMaps = await db.query(
      TABLE_EXERCISE_SLOTS,
      where: '$COL_SLOT_WORKOUT_ID = ?',
      whereArgs: [workoutId],
      orderBy: '$COL_SLOT_ORDER ASC',
    );

    final slots = <ExerciseSlot>[];
    for (final slotMap in slotMaps) {
      final slot = ExerciseSlot.fromMap(slotMap);
      final variants = await _getVariantsForSlot(slot.id!);
      final templates = await _getSetTemplatesForSlot(slot.id!);
      slots.add(
        slot.copyWith(
          variants: variants,
          setTemplates: templates,
        ),
      );
    }

    return slots;
  }

  /// Get exercise variants for a slot
  Future<List<ExerciseVariant>> _getVariantsForSlot(int slotId) async {
    final db = await getDatabase();

    final variantMaps = await db.query(
      TABLE_EXERCISE_VARIANTS,
      where: '$COL_VARIANT_SLOT_ID = ?',
      whereArgs: [slotId],
    );

    return variantMaps.map((map) => ExerciseVariant.fromMap(map)).toList();
  }

  /// Get set templates for a slot
  Future<List<SetTemplate>> _getSetTemplatesForSlot(int slotId) async {
    final db = await getDatabase();

    final templateMaps = await db.query(
      TABLE_SET_TEMPLATES,
      where: '$COL_SET_TEMPLATE_SLOT_ID = ?',
      whereArgs: [slotId],
      orderBy: '$COL_SET_TEMPLATE_SET_NUMBER ASC',
    );

    return templateMaps.map((map) => SetTemplate.fromMap(map)).toList();
  }
}
