import '../database/app_database.dart';
import '../database/database_constants.dart';
import '../models/program.dart';
import '../models/workout.dart';

class ProgramRepository {
  Future<Program?> getProgramById(int programId) async {
    final db = await getDatabase();

    final programMap = await db.query(
      tablePrograms,
      where: '$colProgramId = ?',
      whereArgs: [programId],
    );

    if (programMap.isEmpty) return null;

    final program = Program.fromMap(programMap.first);

    final workoutMaps = await db.query(
      tableWorkouts,
      where: '$colWorkoutProgramId = ?',
      whereArgs: [programId],
      orderBy: '$colWorkoutOrderInProgram ASC',
    );

    final workouts = <Workout>[];
    for (final workoutMap in workoutMaps) {
      final workout = Workout.fromMap(workoutMap);
      final slots = await _getExerciseSlotsForWorkout(workout.id!);
      workouts.add(workout.copyWith(exerciseSlots: slots));
    }

    return program.copyWith(workouts: workouts);
  }

  Future<List<Program>> getAllPrograms() async {
    final db = await getDatabase();
    final programMaps = await db.query(tablePrograms);
    return programMaps.map((map) => Program.fromMap(map)).toList();
  }

  Future<int> createProgram(Program program) async {
    final db = await getDatabase();
    return await db.insert(tablePrograms, program.toMap());
  }

  Future<ExerciseSlot?> getSlotById(int slotId) async {
    final db = await getDatabase();
    final rows = await db.query(
      tableExerciseSlots,
      where: '$colSlotId = ?',
      whereArgs: [slotId],
      limit: 1,
    );
    return rows.isEmpty ? null : ExerciseSlot.fromMap(rows.first);
  }

  Future<ExerciseVariant?> getVariantById(int variantId) async {
    final db = await getDatabase();
    final variantMaps = await db.query(
      tableExerciseVariants,
      where: '$colVariantId = ?',
      whereArgs: [variantId],
    );
    if (variantMaps.isEmpty) return null;
    return ExerciseVariant.fromMap(variantMaps.first);
  }

  Future<List<SetTemplate>> getSetTemplatesForSlot(int slotId) async {
    return _getSetTemplatesForSlot(slotId);
  }

  Future<List<ExerciseSlot>> _getExerciseSlotsForWorkout(int workoutId) async {
    final db = await getDatabase();
    final slotMaps = await db.query(
      tableExerciseSlots,
      where: '$colSlotWorkoutId = ?',
      whereArgs: [workoutId],
      orderBy: '$colSlotOrder ASC',
    );

    final slots = <ExerciseSlot>[];
    for (final slotMap in slotMaps) {
      final slot = ExerciseSlot.fromMap(slotMap);
      final variants = await _getVariantsForSlot(slot.id!);
      final templates = await _getSetTemplatesForSlot(slot.id!);
      slots.add(slot.copyWith(variants: variants, setTemplates: templates));
    }
    return slots;
  }

  Future<List<ExerciseVariant>> _getVariantsForSlot(int slotId) async {
    final db = await getDatabase();
    final variantMaps = await db.query(
      tableExerciseVariants,
      where: '$colVariantSlotId = ?',
      whereArgs: [slotId],
    );
    return variantMaps.map((map) => ExerciseVariant.fromMap(map)).toList();
  }

  Future<List<SetTemplate>> _getSetTemplatesForSlot(int slotId) async {
    final db = await getDatabase();
    final templateMaps = await db.query(
      tableSetTemplates,
      where: '$colSetTemplateSlotId = ?',
      whereArgs: [slotId],
      orderBy: '$colSetTemplateSetNumber ASC',
    );
    return templateMaps.map((map) => SetTemplate.fromMap(map)).toList();
  }
}
