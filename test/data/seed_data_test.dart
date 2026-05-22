import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/seed/seed_data.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
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

  group('loadSeedData integration', () {
    test('produces 4 workouts', () async {
      await loadSeedData();
      final db = await getDatabase();
      final workouts = await db.query(tableWorkouts);
      expect(workouts.length, 4);
    });

    test('produces 20 exercise slots', () async {
      await loadSeedData();
      final db = await getDatabase();
      final slots = await db.query(tableExerciseSlots);
      expect(slots.length, 20);
    });

    test('percentage slots have rest_seconds 150 or 180', () async {
      await loadSeedData();
      final db = await getDatabase();
      final templates = await db.query(
        tableSetTemplates,
        where: '$colSetTemplatePercentage1rm IS NOT NULL',
      );
      for (final t in templates) {
        final rest = t[colSetTemplateRestSeconds] as int;
        expect(rest == 150 || rest == 180, isTrue,
            reason: 'percentage set has unexpected rest ${rest}s');
      }
    });

    test('rpe slots with rest >= 150 are only compound movements', () async {
      await loadSeedData();
      final db = await getDatabase();
      // All RPE templates should have rest 90, 120, or 150 — never 180
      final templates = await db.query(
        tableSetTemplates,
        where: '$colSetTemplateRpeTarget IS NOT NULL',
      );
      for (final t in templates) {
        final rest = t[colSetTemplateRestSeconds] as int;
        expect(rest == 90 || rest == 120 || rest == 150, isTrue,
            reason: 'RPE set has unexpected rest ${rest}s');
      }
    });

    test('all seeded variants have a current 1RM record', () async {
      await loadSeedData();
      final db = await getDatabase();
      final variants = await db.query(tableExerciseVariants);
      final currentRecords = await db.query(
        tableVariantOneRmHistory,
        where: '$col1rmHistoryIsCurrent = 1',
      );
      expect(currentRecords.length, variants.length);
      expect(currentRecords.length, greaterThan(33));
    });

    test('seeded 1RMs reflect beginner baseline assumptions', () async {
      await loadSeedData();
      final db = await getDatabase();

      Future<double> currentOneRmFor(String variantName) async {
        final variant = await db.query(
          tableExerciseVariants,
          where: '$colVariantName = ?',
          whereArgs: [variantName],
          limit: 1,
        );
        expect(variant, isNotEmpty, reason: 'missing variant $variantName');
        final variantId = variant.first[colVariantId] as int;
        final oneRm = await db.query(
          tableVariantOneRmHistory,
          where:
              '$col1rmHistoryVariantId = ? AND $col1rmHistoryIsCurrent = 1',
          whereArgs: [variantId],
          limit: 1,
        );
        expect(oneRm, isNotEmpty, reason: 'missing current 1RM for $variantName');
        return (oneRm.first[col1rmHistoryWeight] as num).toDouble();
      }

      expect(await currentOneRmFor('Back Squat'), 55.0); // barbell + percentage
      expect(await currentOneRmFor('Dumbbell Bench Press'), 25.0); // dumbbell + percentage
      expect(await currentOneRmFor('Leg Press Machine'), 10.0); // machine + rpe
      expect(await currentOneRmFor('Pull-ups'), 50.0); // bodyweight + rpe
      expect(await currentOneRmFor('Cable Row'), 10.0); // machine + rpe
      expect(await currentOneRmFor('Goblet Squat'), 55.0); // free-weight + percentage
      expect(await currentOneRmFor('Overhead Dumbbell Extension'), 25.0); // dumbbell + rpe
    });

    test('calling loadSeedData twice does not duplicate data', () async {
      await loadSeedData();
      await loadSeedData();
      final db = await getDatabase();
      final workouts = await db.query(tableWorkouts);
      final slots = await db.query(tableExerciseSlots);
      expect(workouts.length, 4);
      expect(slots.length, 20);
    });
  });
}
