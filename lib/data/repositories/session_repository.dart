import '../database/app_database.dart';
import '../database/database_constants.dart';
import '../models/session.dart';
import '../models/session_review.dart';

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

  Future<int?> getLastUsedVariantId(int slotId) async {
    final db = await getDatabase();
    final rows = await db.rawQuery(
      '''
      SELECT se.$colSessionExerciseChosenVariantId
      FROM $tableSessionExercises se
      JOIN $tableSessions s ON se.$colSessionExerciseSessionId = s.$colSessionId
      WHERE se.$colSessionExerciseSlotId = ?
      ORDER BY s.$colSessionDateCompleted DESC
      LIMIT 1
    ''',
      [slotId],
    );
    if (rows.isEmpty) return null;
    return rows.first[colSessionExerciseChosenVariantId] as int?;
  }

  Future<Map<int, int>> getLastUsedVariantIdsForSlots(List<int> slotIds) async {
    final result = <int, int>{};
    for (final slotId in slotIds) {
      final variantId = await getLastUsedVariantId(slotId);
      if (variantId != null) {
        result[slotId] = variantId;
      }
    }
    return result;
  }

  Future<int> logSet(SessionSet set) async {
    final db = await getDatabase();
    return await db.insert(tableSessionSets, set.toMap());
  }

  Future<Map<int, List<SessionSet>>> getSessionSetsForExercises(
    List<int> seIds,
  ) async {
    if (seIds.isEmpty) return {};
    final db = await getDatabase();
    final placeholders = seIds.map((_) => '?').join(',');
    final rows = await db.query(
      tableSessionSets,
      where: '$colSessionSetSessionExerciseId IN ($placeholders)',
      whereArgs: seIds,
      orderBy: '$colSessionSetNumber ASC',
    );
    final result = <int, List<SessionSet>>{};
    for (final row in rows) {
      final seId = row[colSessionSetSessionExerciseId] as int;
      result.putIfAbsent(seId, () => []).add(SessionSet.fromMap(row));
    }
    return result;
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

  Future<List<SessionSummary>> getAllSessionSummaries() async {
    final db = await getDatabase();
    final result = await db.rawQuery('''
      SELECT
        s.$colSessionId,
        w.$colWorkoutName AS workout_name,
        s.$colSessionDateCompleted,
        COUNT(DISTINCT se.$colSessionExerciseId) AS exercise_count,
        COUNT(ss.$colSessionSetId) AS total_sets,
        COALESCE(SUM(ss.$colSessionSetWeightLifted * ss.$colSessionSetRepsCompleted), 0) AS total_volume,
        MAX(CASE WHEN TRIM(COALESCE(s.$colSessionNotes, '')) != '' THEN 1 ELSE 0 END) AS has_session_note,
        MAX(CASE WHEN TRIM(COALESCE(ss.$colSessionSetNotes, '')) != '' THEN 1 ELSE 0 END) AS has_set_note
      FROM $tableSessions s
      JOIN $tableWorkouts w ON s.$colSessionWorkoutId = w.$colWorkoutId
      LEFT JOIN $tableSessionExercises se ON se.$colSessionExerciseSessionId = s.$colSessionId
      LEFT JOIN $tableSessionSets ss ON ss.$colSessionSetSessionExerciseId = se.$colSessionExerciseId
      GROUP BY s.$colSessionId
      HAVING COUNT(ss.$colSessionSetId) > 0
      ORDER BY s.$colSessionDateCompleted DESC
    ''');
    final summaries = result.map((row) => SessionSummary.fromMap(row)).toList();
    final prMap = await _fetchNewPrs(db);
    return summaries.map((s) {
      final prs = prMap[s.sessionId];
      if (prs == null || prs.isEmpty) return s;
      return SessionSummary(
        sessionId: s.sessionId,
        workoutName: s.workoutName,
        dateCompleted: s.dateCompleted,
        exerciseCount: s.exerciseCount,
        totalSetsLogged: s.totalSetsLogged,
        totalVolume: s.totalVolume,
        newPrs: prs,
        hasSessionNote: s.hasSessionNote,
        hasSetNote: s.hasSetNote,
      );
    }).toList();
  }

  Future<Map<int, List<PrRecord>>> _fetchNewPrs(dynamic db) async {
    final prMap = <int, List<PrRecord>>{};

    // Weight PRs: session max weight > prior session max weight for same variant
    final weightRows = await db.rawQuery('''
      SELECT * FROM (
        SELECT
          se.$colSessionExerciseSessionId AS session_id,
          ev.$colVariantName AS variant_name,
          MAX(ss.$colSessionSetWeightLifted) AS session_max,
          (SELECT MAX(ss2.$colSessionSetWeightLifted)
           FROM $tableSessionSets ss2
           JOIN $tableSessionExercises se2 ON ss2.$colSessionSetSessionExerciseId = se2.$colSessionExerciseId
           JOIN $tableSessions s2 ON se2.$colSessionExerciseSessionId = s2.$colSessionId
           WHERE se2.$colSessionExerciseChosenVariantId = se.$colSessionExerciseChosenVariantId
             AND s2.$colSessionDateCompleted < s.$colSessionDateCompleted
             AND ss2.$colSessionSetIsWarmup = 0
          ) AS prior_max
        FROM $tableSessionSets ss
        JOIN $tableSessionExercises se ON ss.$colSessionSetSessionExerciseId = se.$colSessionExerciseId
        JOIN $tableSessions s ON se.$colSessionExerciseSessionId = s.$colSessionId
        JOIN $tableExerciseVariants ev ON ev.$colVariantId = se.$colSessionExerciseChosenVariantId
        WHERE ss.$colSessionSetIsWarmup = 0
          AND ss.$colSessionSetWeightLifted IS NOT NULL
        GROUP BY se.$colSessionExerciseSessionId, se.$colSessionExerciseChosenVariantId
      ) WHERE prior_max IS NOT NULL AND session_max > prior_max
    ''');

    for (final row in weightRows) {
      final sessionId = row['session_id'] as int;
      prMap
          .putIfAbsent(sessionId, () => [])
          .add(
            PrRecord(
              variantName: row['variant_name'] as String,
              prev: (row['prior_max'] as num).toDouble(),
              value: (row['session_max'] as num).toDouble(),
              is1rm: false,
            ),
          );
    }

    // 1RM PRs: session max one_rm_at_session_time > prior session max
    final oneRmRows = await db.rawQuery('''
      SELECT * FROM (
        SELECT
          se.$colSessionExerciseSessionId AS session_id,
          ev.$colVariantName AS variant_name,
          MAX(ss.$colSessionSetOneRmAtTime) AS session_max,
          (SELECT MAX(ss2.$colSessionSetOneRmAtTime)
           FROM $tableSessionSets ss2
           JOIN $tableSessionExercises se2 ON ss2.$colSessionSetSessionExerciseId = se2.$colSessionExerciseId
           JOIN $tableSessions s2 ON se2.$colSessionExerciseSessionId = s2.$colSessionId
           WHERE se2.$colSessionExerciseChosenVariantId = se.$colSessionExerciseChosenVariantId
             AND s2.$colSessionDateCompleted < s.$colSessionDateCompleted
          ) AS prior_max
        FROM $tableSessionSets ss
        JOIN $tableSessionExercises se ON ss.$colSessionSetSessionExerciseId = se.$colSessionExerciseId
        JOIN $tableSessions s ON se.$colSessionExerciseSessionId = s.$colSessionId
        JOIN $tableExerciseVariants ev ON ev.$colVariantId = se.$colSessionExerciseChosenVariantId
        WHERE ss.$colSessionSetOneRmAtTime IS NOT NULL
        GROUP BY se.$colSessionExerciseSessionId, se.$colSessionExerciseChosenVariantId
      ) WHERE prior_max IS NOT NULL AND session_max > prior_max
    ''');

    for (final row in oneRmRows) {
      final sessionId = row['session_id'] as int;
      prMap
          .putIfAbsent(sessionId, () => [])
          .add(
            PrRecord(
              variantName: row['variant_name'] as String,
              prev: (row['prior_max'] as num).toDouble(),
              value: (row['session_max'] as num).toDouble(),
              is1rm: true,
            ),
          );
    }

    return prMap;
  }

  Future<List<SessionDetailExercise>> getSessionDetail(int sessionId) async {
    final db = await getDatabase();

    final exercisesResult = await db.rawQuery(
      '''
      SELECT
        se.$colSessionExerciseId,
        se.$colSessionExerciseSlotId,
        se.$colSessionExerciseChosenVariantId,
        es.$colSlotName AS slot_name,
        ev.$colVariantName AS variant_name,
        (SELECT MAX(ss2.$colSessionSetWeightLifted)
         FROM $tableSessionSets ss2
         JOIN $tableSessionExercises se2 ON ss2.$colSessionSetSessionExerciseId = se2.$colSessionExerciseId
         WHERE se2.$colSessionExerciseChosenVariantId = se.$colSessionExerciseChosenVariantId
        ) AS all_time_pr,
        (SELECT MAX(h.$col1rmHistoryWeight)
         FROM $tableVariantOneRmHistory h
         WHERE h.$col1rmHistoryVariantId = se.$colSessionExerciseChosenVariantId
        ) AS all_time_1rm,
        (SELECT MAX(ss2.$colSessionSetWeightLifted)
         FROM $tableSessionSets ss2
         JOIN $tableSessionExercises se2 ON ss2.$colSessionSetSessionExerciseId = se2.$colSessionExerciseId
         JOIN $tableSessions s2 ON se2.$colSessionExerciseSessionId = s2.$colSessionId
         WHERE se2.$colSessionExerciseChosenVariantId = se.$colSessionExerciseChosenVariantId
           AND s2.$colSessionDateCompleted < (SELECT $colSessionDateCompleted FROM $tableSessions WHERE $colSessionId = $sessionId)
           AND ss2.$colSessionSetIsWarmup = 0
        ) AS prior_pr,
        (SELECT MAX(ss2.$colSessionSetOneRmAtTime)
         FROM $tableSessionSets ss2
         JOIN $tableSessionExercises se2 ON ss2.$colSessionSetSessionExerciseId = se2.$colSessionExerciseId
         JOIN $tableSessions s2 ON se2.$colSessionExerciseSessionId = s2.$colSessionId
         WHERE se2.$colSessionExerciseChosenVariantId = se.$colSessionExerciseChosenVariantId
           AND s2.$colSessionDateCompleted < (SELECT $colSessionDateCompleted FROM $tableSessions WHERE $colSessionId = $sessionId)
        ) AS prior_1rm
      FROM $tableSessionExercises se
      JOIN $tableExerciseSlots es ON es.$colSlotId = se.$colSessionExerciseSlotId
      JOIN $tableExerciseVariants ev ON ev.$colVariantId = se.$colSessionExerciseChosenVariantId
      WHERE se.$colSessionExerciseSessionId = ?
      ORDER BY es.$colSlotOrder
    ''',
      [sessionId],
    );

    final exercises = <SessionDetailExercise>[];

    for (final exerciseRow in exercisesResult) {
      final sessionExerciseId = exerciseRow['session_exercise_id'] as int;
      final slotId = exerciseRow['slot_id'] as int;
      final slotName = exerciseRow['slot_name'] as String;
      final variantName = exerciseRow['variant_name'] as String;
      final allTimePr = (exerciseRow['all_time_pr'] as num?)?.toDouble();
      final allTime1rm = (exerciseRow['all_time_1rm'] as num?)?.toDouble();

      final setsResult = await db.rawQuery(
        '''
        SELECT
          ss.$colSessionSetNumber,
          CASE WHEN ss.$colSessionSetIsWarmup = 1 THEN 'warm-up'
               ELSE COALESCE(st.$colSetTemplateSetType, 'working')
          END as set_type,
          st.$colSetTemplateRepsMin,
          st.$colSetTemplateRepsMax,
          st.$colSetTemplatePercentage1rm,
          st.$colSetTemplateRpeTarget,
          ss.$colSessionSetRepsCompleted,
          ss.$colSessionSetWeightLifted,
          ss.$colSessionSetOneRmAtTime,
          ss.$colSessionSetRpeActual,
          ss.$colSessionSetNotes AS notes
        FROM $tableSessionSets ss
        LEFT JOIN $tableSetTemplates st ON st.$colSetTemplateSlotId = ?
          AND st.$colSetTemplateSetNumber = ss.$colSessionSetNumber
        WHERE ss.$colSessionSetSessionExerciseId = ?
        ORDER BY ss.$colSessionSetNumber
      ''',
        [slotId, sessionExerciseId],
      );

      final sets = setsResult
          .map((row) => SessionDetailSet.fromMap(row))
          .toList();

      final workingSets = sets.where((s) => s.setType != 'warm-up');
      final sessionPr = workingSets
          .map((s) => s.actualWeight)
          .whereType<double>()
          .fold<double?>(null, (a, b) => a == null || b > a ? b : a);
      final session1rm = sets
          .map((s) => s.oneRmAtSessionTime)
          .whereType<double>()
          .fold<double?>(null, (a, b) => a == null || b > a ? b : a);
      final priorPr = (exerciseRow['prior_pr'] as num?)?.toDouble();
      final prior1rm = (exerciseRow['prior_1rm'] as num?)?.toDouble();

      final newPrs = <PrRecord>[];
      if (sessionPr != null && priorPr != null && sessionPr > priorPr) {
        newPrs.add(
          PrRecord(
            variantName: variantName,
            prev: priorPr,
            value: sessionPr,
            is1rm: false,
          ),
        );
      }
      if (session1rm != null && prior1rm != null && session1rm > prior1rm) {
        newPrs.add(
          PrRecord(
            variantName: variantName,
            prev: prior1rm,
            value: session1rm,
            is1rm: true,
          ),
        );
      }

      exercises.add(
        SessionDetailExercise(
          slotName: slotName,
          variantName: variantName,
          sets: sets,
          sessionPr: sessionPr,
          allTimePr: allTimePr,
          session1rm: session1rm,
          allTime1rm: allTime1rm,
          newPrs: newPrs,
        ),
      );
    }

    return exercises;
  }
}
