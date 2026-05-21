import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/repositories/one_rm_repository.dart';
import 'package:atlas/data/repositories/program_repository.dart';
import 'package:atlas/data/models/session.dart';
import 'package:atlas/data/repositories/session_repository.dart';
import 'package:atlas/data/seed/seed_data.dart';
import 'package:atlas/utils/progression_service.dart';

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

  // Helpers

  Future<int> insertSession({bool isDeload = false, DateTime? date}) async {
    final repo = SessionRepository();
    // workoutId 1 exists after loadSeedData (Day 1: Lower Strength)
    return repo.createSession(Session(
      workoutId: 1,
      dateCompleted: date ?? DateTime.now(),
      isDeload: isDeload,
    ));
  }

  Future<int> insertSessionExercise(
      int sessionId, int slotId, int variantId) async {
    final db = await getDatabase();
    return db.insert(tableSessionExercises, {
      colSessionExerciseSessionId: sessionId,
      colSessionExerciseSlotId: slotId,
      colSessionExerciseChosenVariantId: variantId,
    });
  }

  Future<void> insertWorkingSet(
    int sessionExerciseId, {
    required int setNumber,
    int? repsCompleted,
    double? weightLifted,
  }) async {
    final db = await getDatabase();
    await db.insert(tableSessionSets, {
      colSessionSetSessionExerciseId: sessionExerciseId,
      colSessionSetNumber: setNumber,
      colSessionSetRepsCompleted: repsCompleted,
      colSessionSetWeightLifted: weightLifted,
      colSessionSetIsWarmup: 0,
    });
  }

  Future<void> insertWarmupSet(
      int sessionExerciseId, int setNumber) async {
    final db = await getDatabase();
    await db.insert(tableSessionSets, {
      colSessionSetSessionExerciseId: sessionExerciseId,
      colSessionSetNumber: setNumber,
      colSessionSetRepsCompleted: 5,
      colSessionSetWeightLifted: 95.0,
      colSessionSetIsWarmup: 1,
    });
  }

  /// Returns {slotId, variantId, repsTargetMin} for the named slot.
  Future<Map<String, dynamic>> slotInfo(String slotName) async {
    final db = await getDatabase();
    final slots = await db.query(tableExerciseSlots,
        where: '$colSlotName = ?', whereArgs: [slotName], limit: 1);
    final slotId = slots.first[colSlotId] as int;

    final variants = await db.query(tableExerciseVariants,
        where: '$colVariantSlotId = ?', whereArgs: [slotId], limit: 1);
    final variantId = variants.first[colVariantId] as int;

    final templates = await db.query(tableSetTemplates,
        where: '$colSetTemplateSlotId = ? AND $colSetTemplateSetType = ?',
        whereArgs: [slotId, 'working'],
        orderBy: '$colSetTemplateSetNumber ASC',
        limit: 1);
    final repsTargetMin = templates.first[colSetTemplateRepsMin] as int?;

    return {'slotId': slotId, 'variantId': variantId, 'repsTargetMin': repsTargetMin};
  }

  group('ProgressionService', () {
    final service = ProgressionService();

    test('1. All working sets completed → progression earned, correct new 1RM',
        () async {
      await loadSeedData();
      final info = await slotInfo('Squat Variant');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      await insertWorkingSet(seId,
          setNumber: 1, repsCompleted: repsMin, weightLifted: 195.0);
      await insertWorkingSet(seId,
          setNumber: 2, repsCompleted: repsMin, weightLifted: 195.0);
      await insertWorkingSet(seId,
          setNumber: 3, repsCompleted: repsMin, weightLifted: 195.0);

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results.length, 1);
      expect(results.first.slotName, 'Squat Variant');
      expect(results.first.previousWeight, 195.0);
      expect(results.first.newSuggestedWeight, 205.0); // +10
      expect(results.first.incrementLbs, 10.0);

      // Verify new 1RM written to DB
      final newOneRm =
          await OneRmRepository().getCurrentOneRm(variantId);
      expect(newOneRm, isNotNull);
      // new_1rm = (195 + 10) / percentage; just check it's larger than original
      expect(newOneRm!, greaterThan(195.0));
    });

    test('2. One set short on reps → no progression', () async {
      await loadSeedData();
      final info = await slotInfo('Squat Variant');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      await insertWorkingSet(seId,
          setNumber: 1, repsCompleted: repsMin, weightLifted: 195.0);
      await insertWorkingSet(seId,
          setNumber: 2, repsCompleted: repsMin, weightLifted: 195.0);
      // Third set fails (repsMin - 1)
      await insertWorkingSet(seId,
          setNumber: 3, repsCompleted: repsMin - 1, weightLifted: 195.0);

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results, isEmpty);
    });

    test('3. Set with null repsCompleted → treated as 0, no progression',
        () async {
      await loadSeedData();
      final info = await slotInfo('Squat Variant');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      await insertWorkingSet(seId,
          setNumber: 1, repsCompleted: repsMin, weightLifted: 195.0);
      // Null reps = not completed
      await insertWorkingSet(seId,
          setNumber: 2, repsCompleted: null, weightLifted: 195.0);

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results, isEmpty);
    });

    test('4. Squat Variant → 10 lb increment', () async {
      await loadSeedData();
      final info = await slotInfo('Squat Variant');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      for (var i = 1; i <= 3; i++) {
        await insertWorkingSet(seId,
            setNumber: i, repsCompleted: repsMin, weightLifted: 195.0);
      }

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results.length, 1);
      expect(results.first.incrementLbs, 10.0);
    });

    test('5. Horizontal Push → 5 lb increment', () async {
      await loadSeedData();
      final info = await slotInfo('Horizontal Push');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      final sessionId = await insertSession(
        date: DateTime.now().add(const Duration(days: 8)),
      );
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      for (var i = 1; i <= 3; i++) {
        await insertWorkingSet(seId,
            setNumber: i, repsCompleted: repsMin, weightLifted: 130.0);
      }

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results.length, 1);
      expect(results.first.incrementLbs, 5.0);
    });

    test('6. RPE-only exercise → 5 lb increment', () async {
      await loadSeedData();
      final info = await slotInfo('Triceps Isolation');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      final sessionId = await insertSession(
        date: DateTime.now().add(const Duration(days: 8)),
      );
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      for (var i = 1; i <= 2; i++) {
        await insertWorkingSet(seId,
            setNumber: i, repsCompleted: repsMin, weightLifted: 100.0);
      }

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results.length, 1);
      expect(results.first.incrementLbs, 5.0);
    });

    test('7. No working sets logged (only warmups) → no progression', () async {
      await loadSeedData();
      final info = await slotInfo('Squat Variant');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      await insertWarmupSet(seId, 1);
      await insertWarmupSet(seId, 2);
      await insertWarmupSet(seId, 3);

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results, isEmpty);
    });

    test('8. Deload session → returns empty list, no 1RM updates', () async {
      await loadSeedData();
      final info = await slotInfo('Squat Variant');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      // Record initial 1RM to verify it's unchanged after the deload session
      final oneRmBefore =
          await OneRmRepository().getCurrentOneRm(variantId);

      final sessionId = await insertSession(isDeload: true);
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      for (var i = 1; i <= 3; i++) {
        await insertWorkingSet(seId,
            setNumber: i, repsCompleted: repsMin, weightLifted: 195.0);
      }

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results, isEmpty);

      // 1RM must not have changed
      final oneRmAfter =
          await OneRmRepository().getCurrentOneRm(variantId);
      expect(oneRmAfter, equals(oneRmBefore));
    });

    test('9. Set template with null repsTargetMin → exercise skipped',
        () async {
      await loadSeedData();
      final db = await getDatabase();

      // Insert a minimal slot with a working template that has null repsTargetMin
      final slotId = await db.insert(tableExerciseSlots, {
        colSlotWorkoutId: 1,
        colSlotName: 'Custom Slot',
        colSlotOrder: 99,
      });
      final variantId = await db.insert(tableExerciseVariants, {
        colVariantSlotId: slotId,
        colVariantName: 'Custom Exercise',
      });
      await db.insert(tableSetTemplates, {
        colSetTemplateSlotId: slotId,
        colSetTemplateSetNumber: 1,
        colSetTemplateSetType: 'working',
        colSetTemplateRepsMin: null, // no rep target defined
        colSetTemplatePercentage1rm: 0.80,
        colSetTemplateRestSeconds: 180,
      });

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      await insertWorkingSet(seId,
          setNumber: 1, repsCompleted: 8, weightLifted: 150.0);

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results, isEmpty);
    });

    test('10. All reps met but weightLifted is null → exercise skipped',
        () async {
      await loadSeedData();
      final info = await slotInfo('Squat Variant');
      final slotId = info['slotId'] as int;
      final variantId = info['variantId'] as int;
      final repsMin = info['repsTargetMin'] as int;

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      // Reps logged but no weight (bodyweight exercise edge case)
      await insertWorkingSet(seId,
          setNumber: 1, repsCompleted: repsMin, weightLifted: null);
      await insertWorkingSet(seId,
          setNumber: 2, repsCompleted: repsMin, weightLifted: null);
      await insertWorkingSet(seId,
          setNumber: 3, repsCompleted: repsMin, weightLifted: null);

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results, isEmpty);
    });

    test('11. RPE target outside rpeToPercent range → exercise skipped',
        () async {
      await loadSeedData();
      final db = await getDatabase();

      // Insert a slot with rpe_target = 5, which is not in {6,7,8,9,10}
      final slotId = await db.insert(tableExerciseSlots, {
        colSlotWorkoutId: 1,
        colSlotName: 'Odd RPE Slot',
        colSlotOrder: 98,
      });
      final variantId = await db.insert(tableExerciseVariants, {
        colVariantSlotId: slotId,
        colVariantName: 'Odd RPE Exercise',
      });
      await db.insert(tableSetTemplates, {
        colSetTemplateSlotId: slotId,
        colSetTemplateSetNumber: 1,
        colSetTemplateSetType: 'working',
        colSetTemplateRepsMin: 8,
        colSetTemplateRpeTarget: 5, // outside {6,7,8,9,10}
        colSetTemplateRestSeconds: 90,
      });

      final sessionId = await insertSession();
      final seId = await insertSessionExercise(sessionId, slotId, variantId);
      await insertWorkingSet(seId,
          setNumber: 1, repsCompleted: 8, weightLifted: 100.0);

      final results = await service.evaluateAndApplyProgression(
        sessionId,
        SessionRepository(),
        OneRmRepository(),
        ProgramRepository(),
      );

      expect(results, isEmpty);
    });
  });
}
