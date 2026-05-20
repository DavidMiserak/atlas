import '../database/app_database.dart';
import '../database/database_constants.dart';
import '../models/session.dart';

class SessionRepository {
  /// Create a new session (workout instance)
  Future<int> createSession(Session session) async {
    final db = await getDatabase();
    return await db.insert(TABLE_SESSIONS, session.toMap());
  }

  /// Get session by ID
  Future<Session?> getSessionById(int sessionId) async {
    final db = await getDatabase();

    final sessionMaps = await db.query(
      TABLE_SESSIONS,
      where: '$COL_SESSION_ID = ?',
      whereArgs: [sessionId],
    );

    if (sessionMaps.isEmpty) return null;
    return Session.fromMap(sessionMaps.first);
  }

  /// Get all sessions for a workout template
  Future<List<Session>> getSessionsByWorkoutId(int workoutId) async {
    final db = await getDatabase();

    final sessionMaps = await db.query(
      TABLE_SESSIONS,
      where: '$COL_SESSION_WORKOUT_ID = ?',
      whereArgs: [workoutId],
      orderBy: '$COL_SESSION_DATE_COMPLETED DESC',
    );

    return sessionMaps.map((map) => Session.fromMap(map)).toList();
  }

  /// Create a session exercise (variant selection for this session)
  Future<int> createSessionExercise(SessionExercise exercise) async {
    final db = await getDatabase();
    return await db.insert(TABLE_SESSION_EXERCISES, exercise.toMap());
  }

  /// Update session exercise (e.g., when swapping variant mid-session)
  Future<int> updateSessionExercise(SessionExercise exercise) async {
    final db = await getDatabase();
    return await db.update(
      TABLE_SESSION_EXERCISES,
      exercise.toMap(),
      where: '$COL_SESSION_EXERCISE_ID = ?',
      whereArgs: [exercise.id],
    );
  }

  /// Get session exercises for a session
  Future<List<SessionExercise>> getSessionExercises(int sessionId) async {
    final db = await getDatabase();

    final exerciseMaps = await db.query(
      TABLE_SESSION_EXERCISES,
      where: '$COL_SESSION_EXERCISE_SESSION_ID = ?',
      whereArgs: [sessionId],
    );

    return exerciseMaps
        .map((map) => SessionExercise.fromMap(map))
        .toList();
  }

  /// Log a set (record reps, weight, RPE)
  Future<int> logSet(SessionSet set) async {
    final db = await getDatabase();
    return await db.insert(TABLE_SESSION_SETS, set.toMap());
  }

  /// Get sets for a session exercise
  Future<List<SessionSet>> getSessionSets(int sessionExerciseId) async {
    final db = await getDatabase();

    final setMaps = await db.query(
      TABLE_SESSION_SETS,
      where: '$COL_SESSION_SET_SESSION_EXERCISE_ID = ?',
      whereArgs: [sessionExerciseId],
      orderBy: '$COL_SESSION_SET_NUMBER ASC',
    );

    return setMaps.map((map) => SessionSet.fromMap(map)).toList();
  }

  /// Get all sessions logged between two dates
  Future<List<Session>> getSessionsBetweenDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await getDatabase();

    final sessionMaps = await db.query(
      TABLE_SESSIONS,
      where: '$COL_SESSION_DATE_COMPLETED BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: '$COL_SESSION_DATE_COMPLETED DESC',
    );

    return sessionMaps.map((map) => Session.fromMap(map)).toList();
  }

  /// Mark session as deload
  Future<int> markSessionAsDeload(int sessionId) async {
    final db = await getDatabase();
    return await db.update(
      TABLE_SESSIONS,
      {COL_SESSION_IS_DELOAD: 1},
      where: '$COL_SESSION_ID = ?',
      whereArgs: [sessionId],
    );
  }

  /// Update session notes
  Future<int> updateSessionNotes(int sessionId, String notes) async {
    final db = await getDatabase();
    return await db.update(
      TABLE_SESSIONS,
      {COL_SESSION_NOTES: notes},
      where: '$COL_SESSION_ID = ?',
      whereArgs: [sessionId],
    );
  }
}
