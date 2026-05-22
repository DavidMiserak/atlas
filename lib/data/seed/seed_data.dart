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
    final existing = await db.query(
      tablePrograms,
      where: '$colProgramName = ?',
      whereArgs: ['4-Day Novice Bodybuilding'],
      limit: 1,
    );

    developer.log('loadSeedData: Found ${existing.length} existing programs');

    if (existing.isNotEmpty) {
      final slots = await db.query(tableExerciseSlots);
      developer.log('loadSeedData: Found ${slots.length} exercise slots');
      if (slots.length >= 20) {
        developer.log('loadSeedData: Data already loaded, skipping');
        return;
      }
    }

    developer.log('loadSeedData: Clearing existing data');
    await db.delete(tablePrograms);
    await db.delete(tableWorkouts);
    await db.delete(tableExerciseSlots);
    await db.delete(tableExerciseVariants);
    await db.delete(tableSetTemplates);
    await db.delete(tableVariantOneRmHistory);
    await db.execute(
        "DELETE FROM sqlite_sequence WHERE name IN ('$tablePrograms', '$tableWorkouts', '$tableExerciseSlots', '$tableExerciseVariants', '$tableSetTemplates', '$tableVariantOneRmHistory')");
  } catch (e) {
    developer.log('loadSeedData: Error during deletion: $e');
  }

  developer.log('loadSeedData: Loading program.json');
  final jsonString = await rootBundle.loadString('assets/data/program.json');
  final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
  final programs = jsonData['programs'] as List<dynamic>;

  developer.log('loadSeedData: Starting transaction');
  try {
    await db.transaction<void>((txn) async {
      for (final programData in programs.cast<Map<String, dynamic>>()) {
        final now = DateTime.now().toIso8601String();
        // Seed 1RMs 30 days back so the progression cooldown doesn't fire on first session
        final seedDate = DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String();
        final programId = await txn.insert(tablePrograms, {
          colProgramName: programData['name'] as String,
          colProgramVersion: programData['version'] as String,
          colProgramDescription: programData['description'] as String,
          colProgramCreatedAt: now,
          colProgramUpdatedAt: now,
        });

        developer.log('loadSeedData: Created program with ID $programId');

        for (final workout
            in (programData['workouts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          final workoutId = await txn.insert(tableWorkouts, {
            colWorkoutProgramId: programId,
            colWorkoutName: workout['name'] as String,
            colWorkoutDayNumber: workout['day_number'] as int,
            colWorkoutOrderInProgram: workout['order_in_program'] as int,
            colWorkoutNotes: (workout['notes'] as String?) ?? '',
          });

          for (final slot
              in (workout['exercise_slots'] as List<dynamic>).cast<Map<String, dynamic>>()) {
            final slotId = await txn.insert(tableExerciseSlots, {
              colSlotWorkoutId: workoutId,
              colSlotName: slot['name'] as String,
              colSlotOrder: slot['order'] as int,
              colSlotCategory: slot['category'] as String,
            });

            final tpl = slot['set_template'] as Map<String, dynamic>;
            final sets = (tpl['sets'] as int?) ?? 3;
            final restSeconds = tpl['rest_seconds'] as int;
            final reps = tpl['reps'] as int;
            final isPercentage = tpl['type'] == 'percentage';

            for (int i = 1; i <= sets; i++) {
              final row = <String, dynamic>{
                colSetTemplateSlotId: slotId,
                colSetTemplateSetNumber: i,
                colSetTemplateSetType: 'working',
                colSetTemplateRepsMin: reps,
                colSetTemplateRepsMax: reps,
                colSetTemplateRestSeconds: restSeconds,
              };
              if (isPercentage) {
                row[colSetTemplatePercentage1rm] = tpl['percentage_1rm'] as double;
              } else {
                row[colSetTemplateRpeTarget] = tpl['rpe_target'] as int;
              }
              await txn.insert(tableSetTemplates, row);
            }

            for (final variant
                in (slot['variants'] as List<dynamic>).cast<Map<String, dynamic>>()) {
              final variantId = await txn.insert(tableExerciseVariants, {
                colVariantSlotId: slotId,
                colVariantName: variant['name'] as String,
                colVariantDescription: variant['description'] as String,
              });

              await txn.insert(tableVariantOneRmHistory, {
                col1rmHistoryVariantId: variantId,
                col1rmHistoryWeight:
                    (variant['initial_one_rm'] as num).toDouble(),
                col1rmHistoryDate: seedDate,
                col1rmHistoryNotes: 'Initial estimate',
                col1rmHistoryIsCurrent: 1,
              });
            }
          }
        }
      }
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

Future<void> seedWarmupItems(Database db) async {
  try {
    final count = await db.query(tableWarmupItems, limit: 1);
    if (count.isNotEmpty) {
      developer.log('seedWarmupItems: Warmup items already exist, skipping');
      return;
    }

    final jsonString = await rootBundle.loadString('assets/data/warmup.json');
    final jsonData = jsonDecode(jsonString) as List<dynamic>;

    for (final item in jsonData) {
      await db.insert(tableWarmupItems, {
        colWarmupItemName: item['name'],
        colWarmupItemReps: item['reps'],
        colWarmupItemOrder: item['order'],
      });
    }
    developer.log('seedWarmupItems: Seeded ${jsonData.length} warmup items');
  } catch (e) {
    developer.log('seedWarmupItems: Error: $e');
  }
}

Future<void> seedVariants(Database db) async {
  try {
    final jsonString =
        await rootBundle.loadString('assets/data/exercises.json');
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
            await db.insert(tableExerciseVariants, {
              colVariantSlotId: slotId,
              colVariantName: variantName,
              colVariantDescription: variantName,
            });
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
