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

    test('all program.json variants have an initial 1RM record', () async {
      await loadSeedData();
      final db = await getDatabase();
      final currentRecords = await db.query(
        tableVariantOneRmHistory,
        where: '$col1rmHistoryIsCurrent = 1',
      );
      // 33 variants defined in program.json each get one seeded 1RM record;
      // extra variants added by seedVariants() from exercises.json have no 1RM
      expect(currentRecords.length, 33);
    });

    test('Back Squat has initial 1RM of 135', () async {
      await loadSeedData();
      final db = await getDatabase();
      final backSquat = await db.query(
        tableExerciseVariants,
        where: '$colVariantName = ?',
        whereArgs: ['Back Squat'],
        limit: 1,
      );
      expect(backSquat.isNotEmpty, isTrue);
      final variantId = backSquat.first[colVariantId] as int;
      final oneRm = await db.query(
        tableVariantOneRmHistory,
        where:
            '$col1rmHistoryVariantId = ? AND $col1rmHistoryIsCurrent = 1',
        whereArgs: [variantId],
        limit: 1,
      );
      expect(oneRm.isNotEmpty, isTrue);
      expect((oneRm.first[col1rmHistoryWeight] as num).toDouble(), 135.0);
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
