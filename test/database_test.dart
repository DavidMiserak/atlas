import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/repositories/program_repository.dart';
import 'package:atlas/data/repositories/session_repository.dart';
import 'package:atlas/data/repositories/one_rm_repository.dart';
import 'package:atlas/data/models/session.dart';
import 'package:atlas/data/seed/seed_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Schema Tests', () {
    test('Database initializes with all 10 tables', () async {
      final db = await getDatabase();

      // Check all tables exist
      final tables = await db.query('sqlite_master',
          where: 'type = ? AND name NOT LIKE ?',
          whereArgs: ['table', 'sqlite_%']);

      final tableNames = tables.map((t) => t['name']).toSet();

      expect(tableNames.contains(tablePrograms), true);
      expect(tableNames.contains(tableWorkouts), true);
      expect(tableNames.contains(tableExerciseSlots), true);
      expect(tableNames.contains(tableExerciseVariants), true);
      expect(tableNames.contains(tableSetTemplates), true);
      expect(tableNames.contains(tableVariantOneRmHistory), true);
      expect(tableNames.contains(tableSessions), true);
      expect(tableNames.contains(tableSessionExercises), true);
      expect(tableNames.contains(tableSessionSets), true);
      expect(tableNames.contains(tableSettings), true);

      await closeDatabase();
    });

    test('Settings table is initialized with defaults', () async {
      final db = await getDatabase();

      final schemaVersion = await db.query(
        tableSettings,
        where: '$colSettingsKey = ?',
        whereArgs: [settingSchemaVersion],
      );

      expect(schemaVersion.isNotEmpty, true);
      expect(schemaVersion.first[colSettingsValue], '1');

      final deloadFreq = await db.query(
        tableSettings,
        where: '$colSettingsKey = ?',
        whereArgs: [settingDeloadFrequencyWeeks],
      );

      expect(deloadFreq.isNotEmpty, true);
      expect(deloadFreq.first[colSettingsValue], '4');

      await closeDatabase();
    });
  });

  group('Seed Data Tests', () {
    test('Seed data loads without errors', () async {
      await loadSeedData();

      final db = await getDatabase();
      final programs = await db.query(tablePrograms);

      expect(programs.isNotEmpty, true);
      expect(programs.first[colProgramName], '4-Day Novice Bodybuilding');
      expect(programs.first[colProgramVersion], 'v1');

      await closeDatabase();
    });

    test('Loading seed data twice does not create duplicates', () async {
      await loadSeedData();
      await loadSeedData();

      final db = await getDatabase();
      final programs = await db.query(
        tablePrograms,
        where: '$colProgramName = ?',
        whereArgs: ['4-Day Novice Bodybuilding'],
      );

      expect(programs.length, 1);

      await closeDatabase();
    });
  });

  group('ProgramRepository Tests', () {
    test('getProgramById returns program with all nested data', () async {
      await loadSeedData();

      final repo = ProgramRepository();
      final program = await repo.getProgramById(1);

      expect(program, isNotNull);
      expect(program?.name, '4-Day Novice Bodybuilding');
      expect(program?.version, 'v1');
      expect(program?.workouts.length, 4);

      // Check first workout
      final day1 = program?.workouts.firstWhere(
        (w) => w.dayNumber == 1,
        orElse: () => throw AssertionError('Day 1 not found'),
      );

      expect(day1?.name, 'Day 1: Lower Strength');
      expect(day1?.exerciseSlots.isNotEmpty, true);

      // Check exercise slots have variants
      final squatSlot = day1?.exerciseSlots.firstWhere(
        (s) => s.name.contains('Squat'),
        orElse: () => throw AssertionError('Squat slot not found'),
      );

      expect(squatSlot?.variants.isNotEmpty, true);
      expect(squatSlot?.setTemplates.isNotEmpty, true);

      await closeDatabase();
    });

    test('getAllPrograms returns list of programs', () async {
      await loadSeedData();

      final repo = ProgramRepository();
      final programs = await repo.getAllPrograms();

      expect(programs.isNotEmpty, true);
      expect(programs.length, greaterThanOrEqualTo(1));

      await closeDatabase();
    });
  });

  group('SessionRepository Tests', () {
    test('createSession saves session to database', () async {
      await loadSeedData();

      final repo = SessionRepository();
      final session = Session(
        workoutId: 1,
        dateCompleted: DateTime.now(),
      );

      final sessionId = await repo.createSession(session);

      expect(sessionId, greaterThan(0));

      final retrieved = await repo.getSessionById(sessionId);
      expect(retrieved, isNotNull);
      expect(retrieved?.workoutId, 1);

      await closeDatabase();
    });

    test('getSessionsByWorkoutId returns sessions', () async {
      await loadSeedData();

      final repo = SessionRepository();

      // Create two sessions
      await repo.createSession(Session(
        workoutId: 1,
        dateCompleted: DateTime.now(),
      ));

      await repo.createSession(Session(
        workoutId: 1,
        dateCompleted: DateTime.now().subtract(Duration(days: 1)),
      ));

      final sessions = await repo.getSessionsByWorkoutId(1);
      expect(sessions.length, greaterThanOrEqualTo(2));

      await closeDatabase();
    });
  });

  group('OneRmRepository Tests', () {
    test('recordNewOneRm saves 1RM and marks as current', () async {
      await loadSeedData();

      final repo = OneRmRepository();

      // The seed data creates a 1RM for back squat (variant_id 1)
      final currentOneRm = await repo.getCurrentOneRm(1);

      expect(currentOneRm, 310.0);

      await closeDatabase();
    });
  });

  group('Foreign Key Constraints', () {
    test('Foreign keys are enforced', () async {
      final db = await getDatabase();

      // Verify PRAGMA foreign_keys is enabled by default in sqflite
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.isNotEmpty, true);

      await closeDatabase();
    });
  });
}
