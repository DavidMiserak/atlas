import 'package:atlas/data/database/app_database.dart';
import 'package:atlas/data/database/database_constants.dart';
import 'package:atlas/data/models/warmup.dart';

class WarmupRepository {
  Future<List<WarmupItem>> getWarmupItems() async {
    final db = await getDatabase();
    final rows = await db.query(
      tableWarmupItems,
      orderBy: '$colWarmupItemOrder ASC',
    );
    return rows.map((row) => WarmupItem.fromMap(row)).toList();
  }
}
