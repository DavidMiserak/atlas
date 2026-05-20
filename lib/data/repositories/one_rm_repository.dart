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
    return results.first[col1rmHistoryWeight] as double?;
  }

  Future<List<OneRmHistory>> getOneRmHistory(int variantId) async {
    final db = await getDatabase();
    final historyMaps = await db.query(
      tableVariantOneRmHistory,
      where: '$col1rmHistoryVariantId = ?',
      whereArgs: [variantId],
      orderBy: '$col1rmHistoryDate DESC',
    );
    return historyMaps.map((map) => OneRmHistory.fromMap(map)).toList();
  }

  Future<int> recordNewOneRm(
    int variantId,
    double weight,
    DateTime date, {
    String? notes,
  }) async {
    final db = await getDatabase();
    return await db.transaction<int>((txn) async {
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

  Future<Map<int, double?>> getCurrentOneRmsForVariants(
      List<int> variantIds) async {
    final result = <int, double?>{};
    for (final variantId in variantIds) {
      result[variantId] = await getCurrentOneRm(variantId);
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
