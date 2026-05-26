import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/repositories/session_repository.dart';

void main() {
  late SessionRepository repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    useInMemoryDatabaseForTesting();
  });

  setUp(() async {
    await closeDatabase();
    repo = SessionRepository();
    // Trigger schema creation.
    await getDatabase();
  });

  tearDown(() async {
    await closeDatabase();
  });

  Future<void> insertSession({
    required int id,
    required int workoutId,
    required String status,
    DateTime? dateCompleted,
  }) async {
    final db = await getDatabase();
    // Use UTC so SQLite's strftime('%s','now') comparisons are timezone-stable.
    final ts = (dateCompleted ?? DateTime.now()).toUtc();
    await db.insert(tableSessions, {
      colSessionId: id,
      colSessionWorkoutId: workoutId,
      colSessionStatus: status,
      colSessionDateCompleted: ts.toIso8601String(),
      colSessionIsDemo: 0,
    });
  }

  Future<void> insertSessionExercise({
    required int id,
    required int sessionId,
  }) async {
    final db = await getDatabase();
    await db.insert(tableSessionExercises, {
      colSessionExerciseId: id,
      colSessionExerciseSessionId: sessionId,
      colSessionExerciseSlotId: 1,
      colSessionExerciseChosenVariantId: 1,
    });
  }

  Future<void> insertSet({
    required int seId,
    required bool isWarmup,
  }) async {
    final db = await getDatabase();
    await db.insert(tableSessionSets, {
      colSessionSetSessionExerciseId: seId,
      colSessionSetIsWarmup: isWarmup ? 1 : 0,
      colSessionSetNumber: 1,
    });
  }

  test('returns empty map when no in_progress sessions exist', () async {
    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, isEmpty);
  });

  test('returns logged set count for one in_progress session', () async {
    await insertSession(id: 1, workoutId: 1, status: sessionStatusInProgress);
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSet(seId: 10, isWarmup: false);
    await insertSet(seId: 10, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, {1: 2});
  });

  test('returns 0 for in_progress session with no sets logged', () async {
    await insertSession(id: 1, workoutId: 1, status: sessionStatusInProgress);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, {1: 0});
  });

  test('handles multiple workouts in_progress simultaneously', () async {
    await insertSession(id: 1, workoutId: 1, status: sessionStatusInProgress);
    await insertSession(id: 2, workoutId: 2, status: sessionStatusInProgress);
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSessionExercise(id: 20, sessionId: 2);
    await insertSet(seId: 10, isWarmup: false);
    await insertSet(seId: 20, isWarmup: false);
    await insertSet(seId: 20, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, {1: 1, 2: 2});
  });

  test('does not return completed sessions', () async {
    await insertSession(id: 1, workoutId: 1, status: sessionStatusCompleted);
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSet(seId: 10, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, isEmpty);
  });

  test('does not return abandoned sessions', () async {
    await insertSession(id: 1, workoutId: 1, status: sessionStatusAbandoned);
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSet(seId: 10, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, isEmpty);
  });

  test('does not return sessions older than 24 hours', () async {
    final stale = DateTime.now().subtract(const Duration(hours: 25));
    await insertSession(
      id: 1,
      workoutId: 1,
      status: sessionStatusInProgress,
      dateCompleted: stale,
    );
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSet(seId: 10, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, isEmpty);
  });

  test('returns session from 23 hours ago (within threshold)', () async {
    final recent = DateTime.now().subtract(const Duration(hours: 23));
    await insertSession(
      id: 1,
      workoutId: 1,
      status: sessionStatusInProgress,
      dateCompleted: recent,
    );
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSet(seId: 10, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, {1: 1});
  });

  test('counts only non-warmup sets', () async {
    await insertSession(id: 1, workoutId: 1, status: sessionStatusInProgress);
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSet(seId: 10, isWarmup: true);
    await insertSet(seId: 10, isWarmup: true);
    await insertSet(seId: 10, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, {1: 1});
  });

  test('pins to latest session when multiple in_progress exist for same workout', () async {
    // session 2 is the latest; only its sets should be counted
    await insertSession(id: 1, workoutId: 1, status: sessionStatusInProgress);
    await insertSession(id: 2, workoutId: 1, status: sessionStatusInProgress);
    await insertSessionExercise(id: 10, sessionId: 1);
    await insertSessionExercise(id: 20, sessionId: 2);
    await insertSet(seId: 10, isWarmup: false);
    await insertSet(seId: 10, isWarmup: false);
    await insertSet(seId: 10, isWarmup: false);
    await insertSet(seId: 20, isWarmup: false);

    final result = await repo.getInProgressWorkoutCompletionCounts();
    expect(result, {1: 1});
  });
}
