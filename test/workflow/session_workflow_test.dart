import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/models/session.dart';
import 'package:atlas/data/repositories/session_repository.dart';
import 'package:atlas/data/seed/seed_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    useInMemoryDatabaseForTesting();
  });

  setUp(() async {
    await closeDatabase();
  });

  tearDown(() async {
    await closeDatabase();
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<int> createSession({bool isDeload = false}) async {
    return SessionRepository().createSession(Session(
      workoutId: 1,
      dateCompleted: DateTime.now(),
      isDeload: isDeload,
    ));
  }

  Future<int> createSessionExercise(
      int sessionId, int slotId, int variantId) async {
    final db = await getDatabase();
    return db.insert(tableSessionExercises, {
      colSessionExerciseSessionId: sessionId,
      colSessionExerciseSlotId: slotId,
      colSessionExerciseChosenVariantId: variantId,
    });
  }

  Future<void> logSet(
    int seId,
    int setNumber, {
    int reps = 5,
    double weight = 200.0,
    bool isWarmup = false,
    double? oneRmAtSessionTime,
    int? rpeActual,
  }) async {
    await SessionRepository().logSet(SessionSet(
      sessionExerciseId: seId,
      setNumber: setNumber,
      repsCompleted: reps,
      weightLifted: weight,
      isWarmup: isWarmup,
      oneRmAtSessionTime: oneRmAtSessionTime,
      rpeActual: rpeActual,
    ));
  }

  /// Returns the slotId and variantId for the first slot in workout 1.
  Future<Map<String, int>> firstSlot() async {
    final db = await getDatabase();
    final slots = await db.query(
      tableExerciseSlots,
      where: '$colSlotWorkoutId = ?',
      whereArgs: [1],
      orderBy: '$colSlotOrder ASC',
      limit: 1,
    );
    final slotId = slots.first[colSlotId] as int;
    final variants = await db.query(
      tableExerciseVariants,
      where: '$colVariantSlotId = ?',
      whereArgs: [slotId],
      limit: 1,
    );
    return {
      'slotId': slotId,
      'variantId': variants.first[colVariantId] as int,
    };
  }

  // ── Tests ──────────────────────────────────────────────────────────────────

  group('Session Workflow', () {
    test('1. Warm-up and working sets stored with correct isWarmup flags',
        () async {
      await loadSeedData();
      final ids = await firstSlot();
      final sessionId = await createSession();
      final seId =
          await createSessionExercise(sessionId, ids['slotId']!, ids['variantId']!);

      // 3 warm-ups + 3 working sets (typical Day 1 squat pattern)
      await logSet(seId, 1, reps: 5, weight: 130.0, isWarmup: true);
      await logSet(seId, 2, reps: 4, weight: 180.0, isWarmup: true);
      await logSet(seId, 3, reps: 2, weight: 230.0, isWarmup: true);
      await logSet(seId, 4, reps: 5, weight: 255.0);
      await logSet(seId, 5, reps: 5, weight: 255.0);
      await logSet(seId, 6, reps: 5, weight: 255.0);

      final repo = SessionRepository();
      final allSets = await repo.getSessionSets(seId);
      final warmups = allSets.where((s) => s.isWarmup).toList();
      final working = allSets.where((s) => !s.isWarmup).toList();

      expect(allSets.length, 6);
      expect(warmups.length, 3);
      expect(working.length, 3);
      expect(working.first.weightLifted, 255.0);
      expect(working.first.repsCompleted, 5);
    });

    test('2. Session notes persist and are retrievable', () async {
      await loadSeedData();
      final repo = SessionRepository();
      final sessionId = await createSession();

      await repo.updateSessionNotes(
          sessionId, 'Felt strong. Good depth on squats.');

      final db = await getDatabase();
      final row = await db.query(
        tableSessions,
        where: '$colSessionId = ?',
        whereArgs: [sessionId],
      );
      expect(row.first[colSessionNotes], 'Felt strong. Good depth on squats.');
    });

    test('3. one_rm_at_session_time is stored with each set', () async {
      await loadSeedData();
      const currentOneRm = 310.0;
      final ids = await firstSlot();
      final sessionId = await createSession();
      final seId =
          await createSessionExercise(sessionId, ids['slotId']!, ids['variantId']!);

      await logSet(seId, 1, weight: 255.0, oneRmAtSessionTime: currentOneRm);

      final sets = await SessionRepository().getSessionSets(seId);
      expect(sets.first.oneRmAtSessionTime, currentOneRm);
    });

    test('4. Multiple exercises in one session → correct exercise count',
        () async {
      await loadSeedData();
      final db = await getDatabase();
      final repo = SessionRepository();
      final sessionId = await createSession();

      final slots = await db.query(
        tableExerciseSlots,
        where: '$colSlotWorkoutId = ?',
        whereArgs: [1],
      );
      for (final slot in slots) {
        final slotId = slot[colSlotId] as int;
        final variants = await db.query(
          tableExerciseVariants,
          where: '$colVariantSlotId = ?',
          whereArgs: [slotId],
          limit: 1,
        );
        if (variants.isEmpty) continue;
        final variantId = variants.first[colVariantId] as int;
        final seId = await createSessionExercise(sessionId, slotId, variantId);
        await logSet(seId, 1, weight: 200.0);
      }

      final exercises = await repo.getSessionExercises(sessionId);
      expect(exercises.length, slots.length);
    });

    test('5. Volume calculation: 3×5 @ 255 lbs = 3825 lbs', () async {
      await loadSeedData();
      final ids = await firstSlot();
      final sessionId = await createSession();
      final seId =
          await createSessionExercise(sessionId, ids['slotId']!, ids['variantId']!);

      await logSet(seId, 1, reps: 5, weight: 255.0);
      await logSet(seId, 2, reps: 5, weight: 255.0);
      await logSet(seId, 3, reps: 5, weight: 255.0);

      final sets = await SessionRepository().getSessionSets(seId);
      final volume = sets.fold<double>(
        0.0,
        (sum, s) => sum + ((s.weightLifted ?? 0) * (s.repsCompleted ?? 0)),
      );
      expect(volume, 3825.0);
    });

    test('6. Deload flag stored and readable from DB', () async {
      await loadSeedData();
      final repo = SessionRepository();
      final sessionId = await createSession(isDeload: true);
      final session = await repo.getSessionById(sessionId);
      expect(session?.isDeload, true);
    });

    test('7. getSessionSetsForExercises returns sets grouped by seId', () async {
      await loadSeedData();
      final db = await getDatabase();
      final repo = SessionRepository();
      final sessionId = await createSession();

      final slots = await db.query(
        tableExerciseSlots,
        where: '$colSlotWorkoutId = ?',
        whereArgs: [1],
        orderBy: '$colSlotOrder ASC',
        limit: 2,
      );

      final seIds = <int>[];
      for (final slot in slots) {
        final slotId = slot[colSlotId] as int;
        final variants = await db.query(
          tableExerciseVariants,
          where: '$colVariantSlotId = ?',
          whereArgs: [slotId],
          limit: 1,
        );
        if (variants.isEmpty) continue;
        final variantId = variants.first[colVariantId] as int;
        final seId = await createSessionExercise(sessionId, slotId, variantId);
        seIds.add(seId);
      }

      // Log 2 sets for first exercise, 3 for second
      await logSet(seIds[0], 1, weight: 255.0);
      await logSet(seIds[0], 2, weight: 255.0);
      await logSet(seIds[1], 1, weight: 130.0);
      await logSet(seIds[1], 2, weight: 130.0);
      await logSet(seIds[1], 3, weight: 130.0);

      final setsMap = await repo.getSessionSetsForExercises(seIds);
      expect(setsMap[seIds[0]]?.length, 2);
      expect(setsMap[seIds[1]]?.length, 3);
      expect(setsMap[seIds[1]]?.first.weightLifted, 130.0);
    });

    test('9. Variant swap mid-exercise — sets stay linked to session_exercise, not variant', () async {
      await loadSeedData();
      final db = await getDatabase();
      final ids = await firstSlot();
      final slotId = ids['slotId']!;

      // Get two variants for the same slot
      final variantRows = await db.query(tableExerciseVariants,
          where: '$colVariantSlotId = ?', whereArgs: [slotId]);
      expect(variantRows.length, greaterThanOrEqualTo(2),
          reason: 'seed data should have at least 2 variants per slot');
      final variantA = variantRows[0][colVariantId] as int;
      final variantB = variantRows[1][colVariantId] as int;

      final sessionId = await createSession();
      final seId = await createSessionExercise(sessionId, slotId, variantA);

      // Log 1 warmup with variant A active
      await logSet(seId, 1, isWarmup: true, weight: 95.0);

      // Simulate variant swap: update chosen_variant_id on the session_exercise
      await db.update(
        tableSessionExercises,
        {colSessionExerciseChosenVariantId: variantB},
        where: '$colSessionExerciseId = ?',
        whereArgs: [seId],
      );

      // Log 2 working sets with variant B active
      await logSet(seId, 2, weight: 200.0);
      await logSet(seId, 3, weight: 200.0);

      // All 3 sets are still linked to the same session_exercise
      final sets = await SessionRepository().getSessionSets(seId);
      expect(sets.length, 3);
      expect(sets.where((s) => s.isWarmup).length, 1);
      expect(sets.where((s) => !s.isWarmup).length, 2);

      // No duplicate session_exercise records created
      final seRows = await db.query(tableSessionExercises,
          where: '$colSessionExerciseSessionId = ?', whereArgs: [sessionId]);
      expect(seRows.length, 1);

      // chosen_variant_id updated to variant B
      expect(seRows.first[colSessionExerciseChosenVariantId], variantB);
    });

    test('8. Sets ordered by set_number ASC within each exercise', () async {
      await loadSeedData();
      final ids = await firstSlot();
      final sessionId = await createSession();
      final seId =
          await createSessionExercise(sessionId, ids['slotId']!, ids['variantId']!);

      // Insert out-of-order to confirm SQL ordering
      await logSet(seId, 3, weight: 270.0);
      await logSet(seId, 1, weight: 255.0);
      await logSet(seId, 2, weight: 260.0);

      final sets = await SessionRepository().getSessionSets(seId);
      expect(sets[0].setNumber, 1);
      expect(sets[1].setNumber, 2);
      expect(sets[2].setNumber, 3);
      expect(sets[2].weightLifted, 270.0);
    });
  });
}
