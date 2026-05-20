import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../database/database_constants.dart';
import '../database/app_database.dart';

Future<void> loadSeedData() async {
  developer.log('loadSeedData: Starting seed data load');
  final db = await getDatabase();
  developer.log('loadSeedData: Database initialized');

  try {
    // First check if tables exist by querying for programs
    final existing = await db.query(
      tablePrograms,
      where: '$colProgramName = ?',
      whereArgs: ['4-Day Novice Bodybuilding'],
      limit: 1,
    );

    developer.log('loadSeedData: Found ${existing.length} existing programs');

    if (existing.isNotEmpty) {
      // Check if we have enough exercise slots (should be 20+)
      final slots = await db.query(tableExerciseSlots);
      developer.log('loadSeedData: Found ${slots.length} exercise slots');
      if (slots.length >= 20) {
        developer.log('loadSeedData: Data already loaded, skipping');
        return; // Already fully loaded
      }
    }

    developer.log('loadSeedData: Clearing existing data');
    // Clear all tables before reloading
    await db.delete(tablePrograms);
    await db.delete(tableWorkouts);
    await db.delete(tableExerciseSlots);
    await db.delete(tableExerciseVariants);
    await db.delete(tableSetTemplates);
    await db.delete(tableVariantOneRmHistory);
    // Reset auto-increment counters
    await db.execute("DELETE FROM sqlite_sequence WHERE name IN ('$tablePrograms', '$tableWorkouts', '$tableExerciseSlots', '$tableExerciseVariants', '$tableSetTemplates', '$tableVariantOneRmHistory')");
  } catch (e) {
    developer.log('loadSeedData: Error during deletion: $e');
    // Ignore errors during deletion
  }

  developer.log('loadSeedData: Starting transaction');
  try {
    await db.transaction<void>((txn) async {
      final programId = await txn.insert(
        tablePrograms,
        {
          colProgramName: '4-Day Novice Bodybuilding',
          colProgramVersion: 'v1',
          colProgramDescription:
              'A structured 4-day split for strength and hypertrophy',
          colProgramCreatedAt: DateTime.now().toIso8601String(),
          colProgramUpdatedAt: DateTime.now().toIso8601String(),
        },
      );

      developer.log('loadSeedData: Created program with ID $programId');

      await _seedDay1(txn, programId);
      developer.log('loadSeedData: Seeded Day 1');
      await _seedDay2(txn, programId);
      developer.log('loadSeedData: Seeded Day 2');
      await _seedDay3(txn, programId);
      developer.log('loadSeedData: Seeded Day 3');
      await _seedDay4(txn, programId);
      developer.log('loadSeedData: Seeded Day 4');
    });
    developer.log('loadSeedData: Transaction completed successfully');
  } catch (e) {
    developer.log('loadSeedData: Error during transaction: $e');
    rethrow;
  }

  developer.log('loadSeedData: Starting warmup seeding');
  await seedWarmupItems(db);
  developer.log('loadSeedData: Warmup seeding completed');

  developer.log('loadSeedData: Starting variant seeding');
  await seedVariants(db);
  developer.log('loadSeedData: Variant seeding completed');
}

Future<void> _seedDay1(Transaction txn, int programId) async {
  final workoutId = await txn.insert(
    tableWorkouts,
    {
      colWorkoutProgramId: programId,
      colWorkoutName: 'Day 1: Lower Strength',
      colWorkoutDayNumber: 1,
      colWorkoutOrderInProgram: 1,
      colWorkoutNotes: 'Strength focus on lower body',
    },
  );

  // Squat Variant
  final squatSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Squat Variant',
      colSlotOrder: 1,
      colSlotCategory: 'Compound Lower',
    },
  );

  // ignore: unused_local_variable
  final backSquatId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: squatSlotId,
      colVariantName: 'Back Squat',
      colVariantDescription: 'Barbell back squat',
    },
  );

  final frontSquatId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: squatSlotId,
      colVariantName: 'Front Squat',
      colVariantDescription: 'Barbell front squat',
    },
  );

  await _addSetTemplates(txn, squatSlotId, reps: 5, percentage: 0.825);
  // await _addOneRm(txn, backSquatId, 135); // REMOVED FOR TESTING 1RM ESTIMATION
  await _addOneRm(txn, frontSquatId, 135);

  // Deadlift Variant
  final deadliftSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Deadlift Variant',
      colSlotOrder: 2,
      colSlotCategory: 'Compound Lower',
    },
  );

  final convDeadliftId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: deadliftSlotId,
      colVariantName: 'Conventional Deadlift',
      colVariantDescription: 'Conventional deadlift',
    },
  );

  final sumoDeadliftId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: deadliftSlotId,
      colVariantName: 'Sumo Deadlift',
      colVariantDescription: 'Sumo deadlift',
    },
  );

  await _addSetTemplates(txn, deadliftSlotId, reps: 5, percentage: 0.825);
  await _addOneRm(txn, convDeadliftId, 135);
  await _addOneRm(txn, sumoDeadliftId, 135);

  // Single Leg Variant
  final singleLegSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Single Leg Variant',
      colSlotOrder: 3,
      colSlotCategory: 'Accessory',
    },
  );

  final splitSquatId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: singleLegSlotId,
      colVariantName: 'Bulgarian Split Squat',
      colVariantDescription: 'Single leg strength',
    },
  );

  final lungesId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: singleLegSlotId,
      colVariantName: 'Walking Lunges',
      colVariantDescription: 'Walking lunges',
    },
  );

  await _addSetTemplatesRPE(txn, singleLegSlotId, reps: 8, rpe: 8);
  await _addOneRm(txn, splitSquatId, 50);
  await _addOneRm(txn, lungesId, 50);

  // Standing Calf Raise
  final calfSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Standing Calf Raise',
      colSlotOrder: 4,
      colSlotCategory: 'Accessory',
    },
  );

  final barbellCalfId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: calfSlotId,
      colVariantName: 'Barbell Calf Raise',
      colVariantDescription: 'Standing barbell calf raise',
    },
  );

  final machineCalfId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: calfSlotId,
      colVariantName: 'Calf Raise Machine',
      colVariantDescription: 'Calf raise machine',
    },
  );

  await _addSetTemplatesRPE(txn, calfSlotId, reps: 8, rpe: 8, sets: 4);
  await _addOneRm(txn, barbellCalfId, 135);
  await _addOneRm(txn, machineCalfId, 135);
}

Future<void> _seedDay2(Transaction txn, int programId) async {
  final workoutId = await txn.insert(
    tableWorkouts,
    {
      colWorkoutProgramId: programId,
      colWorkoutName: 'Day 2: Upper Strength',
      colWorkoutDayNumber: 2,
      colWorkoutOrderInProgram: 2,
      colWorkoutNotes: 'Strength focus on upper body',
    },
  );

  // Horizontal Push
  final benchSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Horizontal Push',
      colSlotOrder: 1,
      colSlotCategory: 'Compound Upper',
    },
  );

  final barbellBenchId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: benchSlotId,
      colVariantName: 'Barbell Bench Press',
      colVariantDescription: 'Flat barbell bench',
    },
  );

  final dumbbellBenchId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: benchSlotId,
      colVariantName: 'Dumbbell Bench Press',
      colVariantDescription: 'Dumbbell bench press',
    },
  );

  await _addSetTemplates(txn, benchSlotId, reps: 5, percentage: 0.825);
  await _addOneRm(txn, barbellBenchId, 135);
  await _addOneRm(txn, dumbbellBenchId, 135);

  // Horizontal Pull
  final rowSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Horizontal Pull',
      colSlotOrder: 2,
      colSlotCategory: 'Compound Upper',
    },
  );

  final barbellRowId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: rowSlotId,
      colVariantName: 'Barbell Row',
      colVariantDescription: 'Barbell bent-over row',
    },
  );

  final dumbbellRowId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: rowSlotId,
      colVariantName: 'Dumbbell Row',
      colVariantDescription: 'Dumbbell row',
    },
  );

  await _addSetTemplatesRPE(txn, rowSlotId, reps: 5, rpe: 8);
  await _addOneRm(txn, barbellRowId, 45);
  await _addOneRm(txn, dumbbellRowId, 25);

  // Vertical Push
  final ohpSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Vertical Push',
      colSlotOrder: 3,
      colSlotCategory: 'Compound Upper',
    },
  );

  final ohpId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: ohpSlotId,
      colVariantName: 'Overhead Press',
      colVariantDescription: 'Standing overhead press',
    },
  );

  final shoulderPressId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: ohpSlotId,
      colVariantName: 'Dumbbell Shoulder Press',
      colVariantDescription: 'Dumbbell shoulder press',
    },
  );

  await _addSetTemplates(txn, ohpSlotId, reps: 8, percentage: 0.725, sets: 2);
  await _addOneRm(txn, ohpId, 95);
  await _addOneRm(txn, shoulderPressId, 95);

  // Vertical Pull
  final pullSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Vertical Pull',
      colSlotOrder: 4,
      colSlotCategory: 'Compound Upper',
    },
  );

  final pullupId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: pullSlotId,
      colVariantName: 'Pull-ups',
      colVariantDescription: 'Bodyweight pull-ups',
    },
  );

  final chinupId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: pullSlotId,
      colVariantName: 'Chin-ups',
      colVariantDescription: 'Bodyweight chin-ups',
    },
  );

  await _addSetTemplatesRPE(txn, pullSlotId, reps: 8, rpe: 8, sets: 2);
  await _addOneRm(txn, pullupId, 160);
  await _addOneRm(txn, chinupId, 160);

  // Chest Flys
  final flySlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Chest Flys',
      colSlotOrder: 5,
      colSlotCategory: 'Accessory',
    },
  );

  final dumbbellFlyId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: flySlotId,
      colVariantName: 'Dumbbell Flys',
      colVariantDescription: 'Incline dumbbell flys',
    },
  );

  final cableFlyId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: flySlotId,
      colVariantName: 'Cable Flys',
      colVariantDescription: 'Cable machine flys',
    },
  );

  await _addSetTemplatesRPE(txn, flySlotId, reps: 15, rpe: 8, sets: 2);
  await _addOneRm(txn, dumbbellFlyId, 25);
  await _addOneRm(txn, cableFlyId, 135);
}

Future<void> _seedDay3(Transaction txn, int programId) async {
  final workoutId = await txn.insert(
    tableWorkouts,
    {
      colWorkoutProgramId: programId,
      colWorkoutName: 'Day 3: Lower Volume',
      colWorkoutDayNumber: 3,
      colWorkoutOrderInProgram: 3,
      colWorkoutNotes: 'Volume focus on lower body',
    },
  );

  // Hip Hinge Variant
  final hipHingeSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Hip Hinge Variant',
      colSlotOrder: 1,
      colSlotCategory: 'Compound Lower',
    },
  );

  final rDLId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: hipHingeSlotId,
      colVariantName: 'Romanian Deadlift',
      colVariantDescription: 'Romanian deadlift',
    },
  );

  final goodMorningId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: hipHingeSlotId,
      colVariantName: 'Good Morning',
      colVariantDescription: 'Good morning exercise',
    },
  );

  await _addSetTemplatesRPE(txn, hipHingeSlotId, reps: 8, rpe: 8);
  await _addOneRm(txn, rDLId, 135);
  await _addOneRm(txn, goodMorningId, 25);

  // Leg Press Variant
  final legPressSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Leg Press Variant',
      colSlotOrder: 2,
      colSlotCategory: 'Compound Lower',
    },
  );

  final legPressId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: legPressSlotId,
      colVariantName: 'Leg Press Machine',
      colVariantDescription: 'Leg press machine',
    },
  );

  await _addSetTemplatesRPE(txn, legPressSlotId, reps: 8, rpe: 8);
  await _addOneRm(txn, legPressId, 135);

  // Leg Extension
  final legExtSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Leg Extension',
      colSlotOrder: 3,
      colSlotCategory: 'Accessory',
    },
  );

  final legExtId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: legExtSlotId,
      colVariantName: 'Leg Extension Machine',
      colVariantDescription: 'Leg extension machine',
    },
  );

  await _addSetTemplatesRPE(txn, legExtSlotId, reps: 12, rpe: 8);
  await _addOneRm(txn, legExtId, 135);

  // Leg Curl
  final legCurlSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Leg Curl',
      colSlotOrder: 4,
      colSlotCategory: 'Accessory',
    },
  );

  final legCurlId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: legCurlSlotId,
      colVariantName: 'Seated Leg Curl',
      colVariantDescription: 'Seated leg curl machine',
    },
  );

  await _addSetTemplatesRPE(txn, legCurlSlotId, reps: 12, rpe: 8);
  await _addOneRm(txn, legCurlId, 135);

  // Seated Calf Raise
  final seatedCalfSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Seated Calf Raise',
      colSlotOrder: 5,
      colSlotCategory: 'Accessory',
    },
  );

  final seatedCalfId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: seatedCalfSlotId,
      colVariantName: 'Seated Calf Raise Machine',
      colVariantDescription: 'Seated calf raise machine',
    },
  );

  await _addSetTemplatesRPE(txn, seatedCalfSlotId, reps: 15, rpe: 8, sets: 4);
  await _addOneRm(txn, seatedCalfId, 135);
}

Future<void> _seedDay4(Transaction txn, int programId) async {
  final workoutId = await txn.insert(
    tableWorkouts,
    {
      colWorkoutProgramId: programId,
      colWorkoutName: 'Day 4: Upper Volume',
      colWorkoutDayNumber: 4,
      colWorkoutOrderInProgram: 4,
      colWorkoutNotes: 'Volume focus on upper body',
    },
  );

  // Horizontal Push (Volume)
  final benchSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Horizontal Push',
      colSlotOrder: 1,
      colSlotCategory: 'Compound Upper',
    },
  );

  final benchVolId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: benchSlotId,
      colVariantName: 'Barbell Bench Press',
      colVariantDescription: 'Flat barbell bench',
    },
  );

  await _addSetTemplates(txn, benchSlotId, reps: 10, percentage: 0.675);
  await _addOneRm(txn, benchVolId, 135);

  // Horizontal Pull (Volume)
  final rowVolSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Horizontal Pull',
      colSlotOrder: 2,
      colSlotCategory: 'Compound Upper',
    },
  );

  final rowVolId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: rowVolSlotId,
      colVariantName: 'Barbell Row',
      colVariantDescription: 'Barbell bent-over row',
    },
  );

  await _addSetTemplatesRPE(txn, rowVolSlotId, reps: 10, rpe: 8);
  await _addOneRm(txn, rowVolId, 135);

  // Incline Push
  final inclinePushSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Incline Push',
      colSlotOrder: 3,
      colSlotCategory: 'Accessory',
    },
  );

  final inclineBenchId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: inclinePushSlotId,
      colVariantName: 'Incline Barbell Press',
      colVariantDescription: 'Incline barbell press',
    },
  );

  final inclineDumbId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: inclinePushSlotId,
      colVariantName: 'Incline Dumbbell Press',
      colVariantDescription: 'Incline dumbbell press',
    },
  );

  await _addSetTemplatesRPE(txn, inclinePushSlotId, reps: 12, rpe: 8, sets: 2);
  await _addOneRm(txn, inclineBenchId, 135);
  await _addOneRm(txn, inclineDumbId, 25);

  // Vertical Pull (Volume)
  final latPullSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Vertical Pull',
      colSlotOrder: 4,
      colSlotCategory: 'Accessory',
    },
  );

  final latPulldownId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: latPullSlotId,
      colVariantName: 'Lat Pulldown',
      colVariantDescription: 'Lat pulldown machine',
    },
  );

  await _addSetTemplatesRPE(txn, latPullSlotId, reps: 12, rpe: 8, sets: 2);
  await _addOneRm(txn, latPulldownId, 135);

  // Triceps Isolation
  final tricepsSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Triceps Isolation',
      colSlotOrder: 5,
      colSlotCategory: 'Accessory',
    },
  );

  final dipsId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: tricepsSlotId,
      colVariantName: 'Tricep Dips',
      colVariantDescription: 'Bodyweight or assisted dips',
    },
  );

  final tricepPushId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: tricepsSlotId,
      colVariantName: 'Cable Tricep Pushdown',
      colVariantDescription: 'Cable tricep pushdown',
    },
  );

  await _addSetTemplatesRPE(txn, tricepsSlotId, reps: 12, rpe: 8, sets: 2);
  await _addOneRm(txn, dipsId, 135);
  await _addOneRm(txn, tricepPushId, 135);

  // Biceps Isolation
  final bicepsSlotId = await txn.insert(
    tableExerciseSlots,
    {
      colSlotWorkoutId: workoutId,
      colSlotName: 'Biceps Isolation',
      colSlotOrder: 6,
      colSlotCategory: 'Accessory',
    },
  );

  final barbellCurlId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: bicepsSlotId,
      colVariantName: 'Barbell Curls',
      colVariantDescription: 'Standing barbell curls',
    },
  );

  final dumbbellCurlId = await txn.insert(
    tableExerciseVariants,
    {
      colVariantSlotId: bicepsSlotId,
      colVariantName: 'Dumbbell Curls',
      colVariantDescription: 'Dumbbell curls',
    },
  );

  await _addSetTemplatesRPE(txn, bicepsSlotId, reps: 12, rpe: 8, sets: 2);
  await _addOneRm(txn, barbellCurlId, 135);
  await _addOneRm(txn, dumbbellCurlId, 135);
}

Future<void> _addSetTemplates(
  Transaction txn,
  int slotId, {
  required int reps,
  required double percentage,
  int sets = 3,
  int restSeconds = 180,
}) async {
  for (int i = 1; i <= sets; i++) {
    await txn.insert(
      tableSetTemplates,
      {
        colSetTemplateSlotId: slotId,
        colSetTemplateSetNumber: i,
        colSetTemplateSetType: 'working',
        colSetTemplateRepsMin: reps,
        colSetTemplateRepsMax: reps,
        colSetTemplatePercentage1rm: percentage,
        colSetTemplateRestSeconds: restSeconds,
      },
    );
  }
}

Future<void> _addSetTemplatesRPE(
  Transaction txn,
  int slotId, {
  required int reps,
  required int rpe,
  int sets = 3,
  int restSeconds = 120,
}) async {
  for (int i = 1; i <= sets; i++) {
    await txn.insert(
      tableSetTemplates,
      {
        colSetTemplateSlotId: slotId,
        colSetTemplateSetNumber: i,
        colSetTemplateSetType: 'working',
        colSetTemplateRepsMin: reps,
        colSetTemplateRepsMax: reps,
        colSetTemplateRpeTarget: rpe,
        colSetTemplateRestSeconds: restSeconds,
      },
    );
  }
}

Future<void> _addOneRm(Transaction txn, int variantId, double weight) async {
  await txn.insert(
    tableVariantOneRmHistory,
    {
      col1rmHistoryVariantId: variantId,
      col1rmHistoryWeight: weight,
      col1rmHistoryDate: DateTime.now().toIso8601String(),
      col1rmHistoryNotes: 'Initial estimate',
      col1rmHistoryIsCurrent: 1,
    },
  );
}

Future<void> seedWarmupItems(Database db) async {
  try {
    final count = await db.query(
      tableWarmupItems,
      limit: 1,
    );
    if (count.isNotEmpty) {
      developer.log('seedWarmupItems: Warmup items already exist, skipping');
      return;
    }

    final jsonString = await rootBundle.loadString('assets/data/warmup.json');
    final jsonData = jsonDecode(jsonString) as List<dynamic>;

    for (final item in jsonData) {
      await db.insert(
        tableWarmupItems,
        {
          colWarmupItemName: item['name'],
          colWarmupItemReps: item['reps'],
          colWarmupItemOrder: item['order'],
        },
      );
    }
    developer.log('seedWarmupItems: Seeded ${jsonData.length} warmup items');
  } catch (e) {
    developer.log('seedWarmupItems: Error: $e');
  }
}

Future<void> seedVariants(Database db) async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/exercises.json');
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    int variantsAdded = 0;

    for (final entry in jsonData.entries) {
      final slotName = entry.key;
      final categories = entry.value as Map<String, dynamic>;

      final slotRows = await db.query(
        tableExerciseSlots,
        where: '$colSlotName = ?',
        whereArgs: [slotName],
      );

      for (final slot in slotRows) {
        final slotId = slot[colSlotId];

        final variants = <String>[];
        if (categories.containsKey('free_weight')) {
          variants.addAll(List<String>.from(categories['free_weight']));
        }
        if (categories.containsKey('machine')) {
          variants.addAll(List<String>.from(categories['machine']));
        }

        for (final variantName in variants) {
          final existing = await db.query(
            tableExerciseVariants,
            where: '$colVariantSlotId = ? AND $colVariantName = ?',
            whereArgs: [slotId, variantName],
            limit: 1,
          );

          if (existing.isEmpty) {
            await db.insert(
              tableExerciseVariants,
              {
                colVariantSlotId: slotId,
                colVariantName: variantName,
                colVariantDescription: variantName,
              },
            );
            variantsAdded++;
          }
        }
      }
    }
    developer.log('seedVariants: Added $variantsAdded new variants');
  } catch (e) {
    developer.log('seedVariants: Error: $e');
  }
}
