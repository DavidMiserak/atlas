import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/database_constants.dart';
import '../seed/seed_data.dart';
import '../../utils/weight_calculator.dart';

class SettingsRepository {
  Future<OneRmFormula> getOneRmFormula() async {
    final db = await getDatabase();
    final rows = await db.query(
      tableSettings,
      where: '$colSettingsKey = ?',
      whereArgs: [settingOneRmFormula],
    );
    if (rows.isEmpty) return OneRmFormula.rpeRts;
    return OneRmFormula.fromStorageKey(rows.first[colSettingsValue] as String);
  }

  Future<void> setOneRmFormula(OneRmFormula formula) async {
    final db = await getDatabase();
    await db.insert(tableSettings, {
      colSettingsKey: settingOneRmFormula,
      colSettingsValue: formula.toStorageKey(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> getKeepScreenAwakeDuringRest() async {
    final db = await getDatabase();
    final rows = await db.query(
      tableSettings,
      where: '$colSettingsKey = ?',
      whereArgs: [settingKeepScreenAwakeDuringRest],
    );
    if (rows.isEmpty) return false;
    return (rows.first[colSettingsValue] as String).toLowerCase() == 'true';
  }

  Future<void> setKeepScreenAwakeDuringRest(bool value) async {
    final db = await getDatabase();
    await db.insert(tableSettings, {
      colSettingsKey: settingKeepScreenAwakeDuringRest,
      colSettingsValue: value.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearOneRmHistory() async {
    final db = await getDatabase();
    await db.delete(tableVariantOneRmHistory);
  }

  Future<void> factoryReset() async {
    await resetDatabase();
    await loadSeedData();
  }
}
