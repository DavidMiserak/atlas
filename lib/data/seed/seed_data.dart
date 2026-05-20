import 'package:sqflite/sqflite.dart';
import '../database/database_constants.dart';
import '../database/app_database.dart';

/// Load seed data (4-day training program) into the database
/// Call this once on first app launch
Future<void> loadSeedData() async {
  final db = await getDatabase();

  // Check if program already exists
  final existing = await db.query(
    TABLE_PROGRAMS,
    where: '$COL_PROGRAM_NAME = ?',
    whereArgs: ['4-Day Novice Bodybuilding'],
    limit: 1,
  );

  if (existing.isNotEmpty) {
    // Already loaded
    return;
  }

  await db.transaction<void>((txn) async {
    // Insert program
    final programId = await txn.insert(
      TABLE_PROGRAMS,
      {
        COL_PROGRAM_NAME: '4-Day Novice Bodybuilding',
        COL_PROGRAM_VERSION: 'v1',
        COL_PROGRAM_DESCRIPTION: 'A structured 4-day split for strength and hypertrophy',
        COL_PROGRAM_CREATED_AT: DateTime.now().toIso8601String(),
        COL_PROGRAM_UPDATED_AT: DateTime.now().toIso8601String(),
      },
    );

    // Day 1: Lower Strength
    await _seedDay1(txn, programId);

    // Day 2: Upper Strength
    await _seedDay2(txn, programId);

    // Day 3: Lower Hypertrophy
    await _seedDay3(txn, programId);

    // Day 4: Upper Hypertrophy
    await _seedDay4(txn, programId);
  });
}

Future<void> _seedDay1(Transaction txn, int programId) async {
  final workoutId = await txn.insert(
    TABLE_WORKOUTS,
    {
      COL_WORKOUT_PROGRAM_ID: programId,
      COL_WORKOUT_NAME: 'Day 1: Lower Strength',
      COL_WORKOUT_DAY_NUMBER: 1,
      COL_WORKOUT_ORDER_IN_PROGRAM: 1,
      COL_WORKOUT_NOTES: 'Strength focus on lower body',
    },
  );

  // Exercise 1: Squat Variant
  final squatSlotId = await txn.insert(
    TABLE_EXERCISE_SLOTS,
    {
      COL_SLOT_WORKOUT_ID: workoutId,
      COL_SLOT_NAME: 'Squat Variant',
      COL_SLOT_ORDER: 1,
      COL_SLOT_CATEGORY: 'Compound Lower',
    },
  );

  // Squat variants
  final backSquatId = await txn.insert(
    TABLE_EXERCISE_VARIANTS,
    {
      COL_VARIANT_SLOT_ID: squatSlotId,
      COL_VARIANT_NAME: 'Back Squat',
      COL_VARIANT_DESCRIPTION: 'Barbell back squat',
    },
  );

  final frontSquatId = await txn.insert(
    TABLE_EXERCISE_VARIANTS,
    {
      COL_VARIANT_SLOT_ID: squatSlotId,
      COL_VARIANT_NAME: 'Front Squat',
      COL_VARIANT_DESCRIPTION: 'Barbell front squat',
    },
  );

  // Set templates for squat
  await txn.insert(
    TABLE_SET_TEMPLATES,
    {
      COL_SET_TEMPLATE_SLOT_ID: squatSlotId,
      COL_SET_TEMPLATE_SET_NUMBER: 1,
      COL_SET_TEMPLATE_SET_TYPE: 'warm-up',
      COL_SET_TEMPLATE_REPS_MIN: 8,
      COL_SET_TEMPLATE_REPS_MAX: 8,
      COL_SET_TEMPLATE_PERCENTAGE_1RM: null, // Calculated as 50% of first working set
      COL_SET_TEMPLATE_REST_SECONDS: 60,
    },
  );

  await txn.insert(
    TABLE_SET_TEMPLATES,
    {
      COL_SET_TEMPLATE_SLOT_ID: squatSlotId,
      COL_SET_TEMPLATE_SET_NUMBER: 2,
      COL_SET_TEMPLATE_SET_TYPE: 'warm-up',
      COL_SET_TEMPLATE_REPS_MIN: 4,
      COL_SET_TEMPLATE_REPS_MAX: 4,
      COL_SET_TEMPLATE_PERCENTAGE_1RM: null,
      COL_SET_TEMPLATE_REST_SECONDS: 90,
    },
  );

  await txn.insert(
    TABLE_SET_TEMPLATES,
    {
      COL_SET_TEMPLATE_SLOT_ID: squatSlotId,
      COL_SET_TEMPLATE_SET_NUMBER: 3,
      COL_SET_TEMPLATE_SET_TYPE: 'warm-up',
      COL_SET_TEMPLATE_REPS_MIN: 2,
      COL_SET_TEMPLATE_REPS_MAX: 2,
      COL_SET_TEMPLATE_PERCENTAGE_1RM: null,
      COL_SET_TEMPLATE_REST_SECONDS: 120,
    },
  );

  // Working sets
  for (int i = 1; i <= 5; i++) {
    await txn.insert(
      TABLE_SET_TEMPLATES,
      {
        COL_SET_TEMPLATE_SLOT_ID: squatSlotId,
        COL_SET_TEMPLATE_SET_NUMBER: 3 + i,
        COL_SET_TEMPLATE_SET_TYPE: 'working',
        COL_SET_TEMPLATE_REPS_MIN: 5,
        COL_SET_TEMPLATE_REPS_MAX: 5,
        COL_SET_TEMPLATE_PERCENTAGE_1RM: 0.825,
        COL_SET_TEMPLATE_RPE_TARGET: null,
        COL_SET_TEMPLATE_REST_SECONDS: 180,
      },
    );
  }

  // Initialize 1RM history for variants
  await txn.insert(
    TABLE_VARIANT_ONE_RM_HISTORY,
    {
      COL_1RM_HISTORY_VARIANT_ID: backSquatId,
      COL_1RM_HISTORY_WEIGHT: 310.0,
      COL_1RM_HISTORY_DATE: DateTime.now().toIso8601String(),
      COL_1RM_HISTORY_NOTES: 'Initial estimate',
      COL_1RM_HISTORY_IS_CURRENT: 1,
    },
  );

  await txn.insert(
    TABLE_VARIANT_ONE_RM_HISTORY,
    {
      COL_1RM_HISTORY_VARIANT_ID: frontSquatId,
      COL_1RM_HISTORY_WEIGHT: 280.0,
      COL_1RM_HISTORY_DATE: DateTime.now().toIso8601String(),
      COL_1RM_HISTORY_NOTES: 'Initial estimate',
      COL_1RM_HISTORY_IS_CURRENT: 1,
    },
  );
}

Future<void> _seedDay2(Transaction txn, int programId) async {
  final workoutId = await txn.insert(
    TABLE_WORKOUTS,
    {
      COL_WORKOUT_PROGRAM_ID: programId,
      COL_WORKOUT_NAME: 'Day 2: Upper Strength',
      COL_WORKOUT_DAY_NUMBER: 2,
      COL_WORKOUT_ORDER_IN_PROGRAM: 2,
      COL_WORKOUT_NOTES: 'Strength focus on upper body',
    },
  );

  // Exercise 1: Bench Press Variant (simplified for MVP)
  final benchSlotId = await txn.insert(
    TABLE_EXERCISE_SLOTS,
    {
      COL_SLOT_WORKOUT_ID: workoutId,
      COL_SLOT_NAME: 'Horizontal Push',
      COL_SLOT_ORDER: 1,
      COL_SLOT_CATEGORY: 'Compound Upper',
    },
  );

  final barbellBenchId = await txn.insert(
    TABLE_EXERCISE_VARIANTS,
    {
      COL_VARIANT_SLOT_ID: benchSlotId,
      COL_VARIANT_NAME: 'Barbell Bench Press',
      COL_VARIANT_DESCRIPTION: 'Flat barbell bench',
    },
  );

  // Set templates
  await txn.insert(
    TABLE_SET_TEMPLATES,
    {
      COL_SET_TEMPLATE_SLOT_ID: benchSlotId,
      COL_SET_TEMPLATE_SET_NUMBER: 1,
      COL_SET_TEMPLATE_SET_TYPE: 'warm-up',
      COL_SET_TEMPLATE_REPS_MIN: 8,
      COL_SET_TEMPLATE_REPS_MAX: 8,
      COL_SET_TEMPLATE_PERCENTAGE_1RM: null,
      COL_SET_TEMPLATE_REST_SECONDS: 60,
    },
  );

  for (int i = 1; i <= 5; i++) {
    await txn.insert(
      TABLE_SET_TEMPLATES,
      {
        COL_SET_TEMPLATE_SLOT_ID: benchSlotId,
        COL_SET_TEMPLATE_SET_NUMBER: 1 + i,
        COL_SET_TEMPLATE_SET_TYPE: 'working',
        COL_SET_TEMPLATE_REPS_MIN: 5,
        COL_SET_TEMPLATE_REPS_MAX: 5,
        COL_SET_TEMPLATE_PERCENTAGE_1RM: 0.825,
        COL_SET_TEMPLATE_REST_SECONDS: 180,
      },
    );
  }

  await txn.insert(
    TABLE_VARIANT_ONE_RM_HISTORY,
    {
      COL_1RM_HISTORY_VARIANT_ID: barbellBenchId,
      COL_1RM_HISTORY_WEIGHT: 225.0,
      COL_1RM_HISTORY_DATE: DateTime.now().toIso8601String(),
      COL_1RM_HISTORY_NOTES: 'Initial estimate',
      COL_1RM_HISTORY_IS_CURRENT: 1,
    },
  );
}

Future<void> _seedDay3(Transaction txn, int programId) async {
  await txn.insert(
    TABLE_WORKOUTS,
    {
      COL_WORKOUT_PROGRAM_ID: programId,
      COL_WORKOUT_NAME: 'Day 3: Lower Hypertrophy',
      COL_WORKOUT_DAY_NUMBER: 3,
      COL_WORKOUT_ORDER_IN_PROGRAM: 3,
      COL_WORKOUT_NOTES: 'Hypertrophy focus on lower body',
    },
  );
  // TODO: Add exercise slots and variants for Day 3
}

Future<void> _seedDay4(Transaction txn, int programId) async {
  await txn.insert(
    TABLE_WORKOUTS,
    {
      COL_WORKOUT_PROGRAM_ID: programId,
      COL_WORKOUT_NAME: 'Day 4: Upper Hypertrophy',
      COL_WORKOUT_DAY_NUMBER: 4,
      COL_WORKOUT_ORDER_IN_PROGRAM: 4,
      COL_WORKOUT_NOTES: 'Hypertrophy focus on upper body',
    },
  );
  // TODO: Add exercise slots and variants for Day 4
}
