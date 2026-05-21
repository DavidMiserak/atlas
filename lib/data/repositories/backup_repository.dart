import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/database_constants.dart';

class BackupRepository {
  /// Copies the current database to the app cache directory with a dated name
  /// and returns the path of the backup file.
  Future<String> createBackup() async {
    final dbPath = join(await getDatabasesPath(), databaseName);
    final cacheDir = await getApplicationCacheDirectory();
    final dateStr = _dateStamp();
    final destPath = join(cacheDir.path, 'atlas-backup-$dateStr.db');

    developer.log('BackupRepository: creating backup to $destPath');
    await File(dbPath).copy(destPath);
    developer.log('BackupRepository: backup created (${await File(destPath).length()} bytes)');
    return destPath;
  }

  /// Shares the backup file at [path] via the system share sheet.
  Future<void> shareBackup(String path) async {
    developer.log('BackupRepository: sharing backup at $path');
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/octet-stream')],
      subject: 'Atlas workout backup',
    );
  }

  /// Opens a file picker and returns the selected file path, or null if cancelled.
  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  /// Validates [path] as a valid Atlas backup file.
  /// Throws [FormatException] or [StateError] with a user-readable message on failure.
  Future<void> validateBackupFile(String path) async {
    // 1. SQLite magic bytes: first 16 bytes = "SQLite format 3\000"
    final file = File(path);
    if (!await file.exists()) throw FormatException('File not found');

    final bytes = await file.openRead(0, 16).expand((b) => b).toList();
    const magic = [83, 81, 76, 105, 116, 101, 32, 102, 111, 114, 109, 97, 116, 32, 51, 0];
    if (bytes.length < 16 || !_listEquals(bytes, magic)) {
      throw FormatException('Not a valid SQLite database file');
    }

    // 2. Open a read-only connection to inspect schema and version
    final db = await openDatabase(path, readOnly: true);
    try {
      // 3. Schema version check
      final versionRows = await db.query(
        tableSettings,
        where: '$colSettingsKey = ?',
        whereArgs: [settingSchemaVersion],
      );
      if (versionRows.isEmpty) {
        throw FormatException('Not an Atlas backup file');
      }
      final version = int.tryParse(versionRows.first[colSettingsValue] as String? ?? '') ?? 0;
      if (version > databaseVersion) {
        throw StateError('This backup requires a newer version of Atlas');
      }

      // 4. All expected Atlas tables must be present
      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tableNames = tableRows.map((r) => r['name'] as String).toSet();
      const required = {
        tablePrograms, tableWorkouts, tableExerciseSlots, tableExerciseVariants,
        tableSetTemplates, tableVariantOneRmHistory, tableSessions,
        tableSessionExercises, tableSessionSets, tableSettings, tableWarmupItems,
      };
      if (!required.every(tableNames.contains)) {
        throw FormatException('Not an Atlas backup file (missing tables)');
      }

      // 5. Integrity check
      final integrity = await db.rawQuery('PRAGMA integrity_check');
      if (integrity.isNotEmpty &&
          integrity.first.values.first.toString() != 'ok') {
        throw FormatException('Backup file is corrupted');
      }
    } finally {
      await db.close();
    }
  }

  /// Atomically restores the database from [sourcePath].
  /// Copies to a staging path first, then renames to the live DB path.
  /// Throws on validation failure. If rename fails, attempts recovery.
  Future<void> restoreBackup(String sourcePath) async {
    await validateBackupFile(sourcePath);

    final dbDir = await getDatabasesPath();
    final dbPath = join(dbDir, databaseName);
    final stagingPath = join(dbDir, '$databaseName.restore_staging');

    developer.log('BackupRepository: copying backup to staging path');
    await File(sourcePath).copy(stagingPath);

    developer.log('BackupRepository: closing current database');
    await closeDatabase();

    try {
      developer.log('BackupRepository: renaming staging to live DB');
      await File(stagingPath).rename(dbPath);
    } catch (e) {
      developer.log('BackupRepository: rename failed, attempting recovery: $e');
      // Try to restore from staging since the original may be partially gone
      try {
        await File(stagingPath).copy(dbPath);
        await File(stagingPath).delete();
      } catch (_) {}
      await getDatabase(); // re-open whatever we have
      rethrow;
    }

    developer.log('BackupRepository: reopening restored database');
    await getDatabase();
    developer.log('BackupRepository: restore complete');
  }

  String _dateStamp() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
