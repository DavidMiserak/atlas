import '../database/app_database.dart';
import '../database/database_constants.dart';
import '../models/session.dart';

class SessionRepository {
  Future<int> createSession(Session session) async {
    final db = await getDatabase();
    return await db.insert(tableSessions, session.toMap());
  }

  Future<Session?> getSessionById(int sessionId) async {
    final db = await getDatabase();
    final sessionMaps = await db.query(
      tableSessions,
      where: '$colSessionId = ?',
      whereArgs: [sessionId],
    );
    if (sessionMaps.isEmpty) return null;
    return Session.fromMap(sessionMaps.first);
  }

  Future<List<Session>> getSessionsByWorkoutId(int workoutId) async {
    final db = await getDatabase();
    final sessionMaps = await db.query(
      tableSessions,
      where: '$colSessionWorkoutId = ?',
      whereArgs: [workoutId],
      orderBy: '$colSessionDateCompleted DESC',
    );
    return sessionMaps.map((map) => Session.fromMap(map)).toList();
  }

  Future<int> createSessionExercise(SessionExercise exercise) async {
    final db = await getDatabase();
    return await db.insert(tableSessionExercises, exercise.toMap());
  }

  Future<int> updateSessionExercise(SessionExercise exercise) async {
    final db = await getDatabase();
    return await db.update(
      tableSessionExercises,
      exercise.toMap(),
      where: '$colSessionExerciseId = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<List<SessionExercise>> getSessionExercises(int sessionId) async {
    final db = await getDatabase();
    final exerciseMaps = await db.query(
      tableSessionExercises,
      where: '$colSessionExerciseSessionId = ?',
      whereArgs: [sessionId],
    );
    return exerciseMaps.map((map) => SessionExercise.fromMap(map)).toList();
  }

  Future<int> logSet(SessionSet set) async {
    final db = await getDatabase();
    return await db.insert(tableSessionSets, set.toMap());
  }

  Future<List<SessionSet>> getSessionSets(int sessionExerciseId) async {
    final db = await getDatabase();
    final setMaps = await db.query(
      tableSessionSets,
      where: '$colSessionSetSessionExerciseId = ?',
      whereArgs: [sessionExerciseId],
      orderBy: '$colSessionSetNumber ASC',
    );
    return setMaps.map((map) => SessionSet.fromMap(map)).toList();
  }

  Future<List<Session>> getSessionsBetweenDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await getDatabase();
    final sessionMaps = await db.query(
      tableSessions,
      where: '$colSessionDateCompleted BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: '$colSessionDateCompleted DESC',
    );
    return sessionMaps.map((map) => Session.fromMap(map)).toList();
  }

  Future<int> markSessionAsDeload(int sessionId) async {
    final db = await getDatabase();
    return await db.update(
      tableSessions,
      {colSessionIsDeload: 1},
      where: '$colSessionId = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> updateSessionNotes(int sessionId, String notes) async {
    final db = await getDatabase();
    return await db.update(
      tableSessions,
      {colSessionNotes: notes},
      where: '$colSessionId = ?',
      whereArgs: [sessionId],
    );
  }

  Future<double?> getHighestWeightForVariant(int variantId) async {
    final db = await getDatabase();
    final result = await db.rawQuery(
      'SELECT MAX($colSessionSetWeightLifted) as max_weight FROM $tableSessionSets '
      'INNER JOIN $tableSessionExercises ON '
      '$tableSessionSets.$colSessionSetSessionExerciseId = $tableSessionExercises.$colSessionExerciseId '
      'WHERE $tableSessionExercises.$colSessionExerciseChosenVariantId = ?',
      [variantId],
    );
    if (result.isEmpty || result.first['max_weight'] == null) return null;
    return (result.first['max_weight'] as num?)?.toDouble();
  }
}
