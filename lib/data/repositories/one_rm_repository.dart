import '../database/app_database.dart';
import '../database/database_constants.dart';

class OneRmRepository {
  /// Get current 1RM for a variant (most recent entry marked as current)
  Future<double?> getCurrentOneRm(int variantId) async {
    final db = await getDatabase();

    final results = await db.query(
      TABLE_VARIANT_ONE_RM_HISTORY,
      where: '$COL_1RM_HISTORY_VARIANT_ID = ? AND $COL_1RM_HISTORY_IS_CURRENT = 1',
      whereArgs: [variantId],
    );

    if (results.isEmpty) return null;
    return results.first[COL_1RM_HISTORY_WEIGHT] as double?;
  }

  /// Get 1RM history for a variant (all entries, most recent first)
  Future<List<OneRmHistory>> getOneRmHistory(int variantId) async {
    final db = await getDatabase();

    final historyMaps = await db.query(
      TABLE_VARIANT_ONE_RM_HISTORY,
      where: '$COL_1RM_HISTORY_VARIANT_ID = ?',
      whereArgs: [variantId],
      orderBy: '$COL_1RM_HISTORY_DATE DESC',
    );

    return historyMaps.map((map) => OneRmHistory.fromMap(map)).toList();
  }

  /// Record a new 1RM and mark it as current
  /// (Sets all previous entries for this variant as not current)
  Future<int> recordNewOneRm(
    int variantId,
    double weight,
    DateTime date, {
    String? notes,
  }) async {
    final db = await getDatabase();

    // Start transaction to ensure consistency
    return await db.transaction<int>((txn) async {
      // Mark all previous entries as not current
      await txn.update(
        TABLE_VARIANT_ONE_RM_HISTORY,
        {COL_1RM_HISTORY_IS_CURRENT: 0},
        where: '$COL_1RM_HISTORY_VARIANT_ID = ?',
        whereArgs: [variantId],
      );

      // Insert new entry as current
      return await txn.insert(
        TABLE_VARIANT_ONE_RM_HISTORY,
        {
          COL_1RM_HISTORY_VARIANT_ID: variantId,
          COL_1RM_HISTORY_WEIGHT: weight,
          COL_1RM_HISTORY_DATE: date.toIso8601String(),
          COL_1RM_HISTORY_NOTES: notes,
          COL_1RM_HISTORY_IS_CURRENT: 1,
        },
      );
    });
  }

  /// Get 1RM entry by ID
  Future<OneRmHistory?> getOneRmHistoryById(int historyId) async {
    final db = await getDatabase();

    final results = await db.query(
      TABLE_VARIANT_ONE_RM_HISTORY,
      where: '$COL_1RM_HISTORY_ID = ?',
      whereArgs: [historyId],
    );

    if (results.isEmpty) return null;
    return OneRmHistory.fromMap(results.first);
  }

  /// Get 1RM history for multiple variants (for comparing lifts)
  Future<Map<int, double?>> getCurrentOneRmsForVariants(
      List<int> variantIds) async {
    final result = <int, double?>{};

    for (final variantId in variantIds) {
      final oneRm = await getCurrentOneRm(variantId);
      result[variantId] = oneRm;
    }

    return result;
  }

  /// Cascade: update all future sessions when 1RM changes
  /// Note: For MVP, sessions recalculate on load when querying with current 1RM.
  /// In Phase 3, consider denormalizing or marking sessions that need updates.
  Future<void> cascadeOneRmUpdate(int variantId, DateTime fromDate) async {
    // Future implementation: mark sessions that need recalculation
    // For now, app recalculates on load using current 1RM values
    // This prevents N+1 query problems when fetching all sessions
  }
}

class OneRmHistory {
  final int? id;
  final int variantId;
  final double weight;
  final DateTime date;
  final String? notes;
  final bool isCurrent;

  OneRmHistory({
    this.id,
    required this.variantId,
    required this.weight,
    required this.date,
    this.notes,
    required this.isCurrent,
  });

  Map<String, dynamic> toMap() {
    return {
      'history_id': id,
      'variant_id': variantId,
      'weight': weight,
      'date': date.toIso8601String(),
      'notes': notes,
      'is_current': isCurrent ? 1 : 0,
    };
  }

  static OneRmHistory fromMap(Map<String, dynamic> map) {
    return OneRmHistory(
      id: map['history_id'] as int?,
      variantId: map['variant_id'] as int,
      weight: map['weight'] as double,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      isCurrent: (map['is_current'] as int?) == 1,
    );
  }
}
