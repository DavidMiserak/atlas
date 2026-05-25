import '../database/app_database.dart';
import '../database/database_constants.dart';

class OneRmRepository {
  Future<double?> getCurrentOneRm(int variantId) async {
    final db = await getDatabase();
    final results = await db.query(
      tableVariantOneRmHistory,
      where: '$col1rmHistoryVariantId = ? AND $col1rmHistoryIsCurrent = 1',
      whereArgs: [variantId],
    );
    if (results.isEmpty) return null;
    final raw = results.first[col1rmHistoryWeight];
    return raw == null ? null : (raw as num).toDouble();
  }

  Future<List<OneRmHistory>> getOneRmHistory(int variantId) async {
    final db = await getDatabase();
    final historyMaps = await db.query(
      tableVariantOneRmHistory,
      where: '$col1rmHistoryVariantId = ?',
      whereArgs: [variantId],
      orderBy: '$col1rmHistoryDate DESC',
    );
    final history = historyMaps.map((map) => OneRmHistory.fromMap(map)).toList();
    if (history.isEmpty) return history;

    // Filter accidental duplicate saves (same weight repeated within a minute).
    final deduped = <OneRmHistory>[];
    for (final record in history) {
      if (deduped.isEmpty) {
        deduped.add(record);
        continue;
      }

      final previous = deduped.last;
      final sameWeight = (previous.weight - record.weight).abs() < 0.0001;
      final nearInTime =
          previous.date.difference(record.date).abs() < const Duration(minutes: 1);
      if (sameWeight && nearInTime) {
        continue;
      }

      deduped.add(record);
    }

    return deduped;
  }

  Future<int> recordNewOneRm(
    int variantId,
    double weight,
    DateTime date, {
    String? notes,
  }) async {
    final db = await getDatabase();
    return await db.transaction<int>((txn) async {
      final existingCurrent = await txn.query(
        tableVariantOneRmHistory,
        columns: [
          col1rmHistoryId,
          col1rmHistoryWeight,
        ],
        where: '$col1rmHistoryVariantId = ? AND $col1rmHistoryIsCurrent = 1',
        whereArgs: [variantId],
        limit: 1,
      );

      if (existingCurrent.isNotEmpty) {
        final currentRow = existingCurrent.first;
        final currentWeight = (currentRow[col1rmHistoryWeight] as num).toDouble();
        final currentId = currentRow[col1rmHistoryId] as int?;

        // Avoid duplicate history rows when the 1RM didn't actually change.
        if (currentId != null && (currentWeight - weight).abs() < 0.0001) {
          await txn.update(
            tableVariantOneRmHistory,
            {
              col1rmHistoryDate: date.toIso8601String(),
              col1rmHistoryNotes: notes,
            },
            where: '$col1rmHistoryId = ?',
            whereArgs: [currentId],
          );
          return currentId;
        }
      }

      await txn.update(
        tableVariantOneRmHistory,
        {col1rmHistoryIsCurrent: 0},
        where: '$col1rmHistoryVariantId = ?',
        whereArgs: [variantId],
      );
      return await txn.insert(tableVariantOneRmHistory, {
        col1rmHistoryVariantId: variantId,
        col1rmHistoryWeight: weight,
        col1rmHistoryDate: date.toIso8601String(),
        col1rmHistoryNotes: notes,
        col1rmHistoryIsCurrent: 1,
      });
    });
  }

  Future<OneRmHistory?> getOneRmHistoryById(int historyId) async {
    final db = await getDatabase();
    final results = await db.query(
      tableVariantOneRmHistory,
      where: '$col1rmHistoryId = ?',
      whereArgs: [historyId],
    );
    if (results.isEmpty) return null;
    return OneRmHistory.fromMap(results.first);
  }

  /// Returns weight AND most-recent date for each variant in one query.
  Future<Map<int, ({double? weight, DateTime? date})>> getCurrentOneRmDataForVariants(
      List<int> variantIds) async {
    if (variantIds.isEmpty) return {};
    final db = await getDatabase();
    final placeholders = variantIds.map((_) => '?').join(',');
    final rows = await db.rawQuery(
      'SELECT $col1rmHistoryVariantId, $col1rmHistoryWeight, $col1rmHistoryDate '
      'FROM $tableVariantOneRmHistory '
      'WHERE $col1rmHistoryVariantId IN ($placeholders) AND $col1rmHistoryIsCurrent = 1',
      variantIds,
    );
    final result = <int, ({double? weight, DateTime? date})>{};
    for (final variantId in variantIds) {
      result[variantId] = (weight: null, date: null);
    }
    for (final row in rows) {
      final variantId = row[col1rmHistoryVariantId] as int;
      final w = row[col1rmHistoryWeight];
      final d = row[col1rmHistoryDate] as String?;
      result[variantId] = (
        weight: w == null ? null : (w as num).toDouble(),
        date: d == null ? null : DateTime.tryParse(d),
      );
    }
    return result;
  }

  Future<Map<int, double?>> getCurrentOneRmsForVariants(
      List<int> variantIds) async {
    if (variantIds.isEmpty) return {};
    final db = await getDatabase();
    final placeholders = variantIds.map((_) => '?').join(',');
    final rows = await db.rawQuery(
      'SELECT $col1rmHistoryVariantId, $col1rmHistoryWeight FROM $tableVariantOneRmHistory WHERE $col1rmHistoryVariantId IN ($placeholders) AND $col1rmHistoryIsCurrent = 1',
      variantIds,
    );
    final result = <int, double?>{};
    for (final variantId in variantIds) {
      result[variantId] = null;
    }
    for (final row in rows) {
      final variantId = row[col1rmHistoryVariantId] as int;
      final w = row[col1rmHistoryWeight];
      result[variantId] = w == null ? null : (w as num).toDouble();
    }
    return result;
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
      col1rmHistoryId: id,
      col1rmHistoryVariantId: variantId,
      col1rmHistoryWeight: weight,
      col1rmHistoryDate: date.toIso8601String(),
      col1rmHistoryNotes: notes,
      col1rmHistoryIsCurrent: isCurrent ? 1 : 0,
    };
  }

  static OneRmHistory fromMap(Map<String, dynamic> map) {
    return OneRmHistory(
      id: map[col1rmHistoryId] as int?,
      variantId: map[col1rmHistoryVariantId] as int,
      weight: (map[col1rmHistoryWeight] as num).toDouble(),
      date: DateTime.parse(map[col1rmHistoryDate] as String),
      notes: map[col1rmHistoryNotes] as String?,
      isCurrent: (map[col1rmHistoryIsCurrent] as int?) == 1,
    );
  }
}
