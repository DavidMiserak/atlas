import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';

Database? _database;
String? _testDatabasePath;

void useInMemoryDatabaseForTesting() {
  _testDatabasePath = inMemoryDatabasePath;
  _database = null;
}

Future<Database> getDatabase() async {
  if (_database != null) return _database!;
  _database = await _initDatabase();
  return _database!;
}

Future<Database> _initDatabase() async {
  final path = _testDatabasePath ?? join(await getDatabasesPath(), databaseName);

  return await openDatabase(
    path,
    version: databaseVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _onCreate(Database db, int version) async {
  await _createTables(db);
  await _initializeSettings(db);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

Future<void> _createTables(Database db) async {
  await db.execute('''
    CREATE TABLE $tablePrograms (
      $colProgramId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colProgramName TEXT NOT NULL,
      $colProgramVersion TEXT NOT NULL,
      $colProgramDescription TEXT,
      $colProgramCreatedAt TEXT NOT NULL,
      $colProgramUpdatedAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableWorkouts (
      $colWorkoutId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colWorkoutProgramId INTEGER NOT NULL,
      $colWorkoutName TEXT NOT NULL,
      $colWorkoutDayNumber INTEGER NOT NULL,
      $colWorkoutOrderInProgram INTEGER NOT NULL,
      $colWorkoutNotes TEXT,
      FOREIGN KEY ($colWorkoutProgramId) REFERENCES $tablePrograms ($colProgramId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableExerciseSlots (
      $colSlotId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colSlotWorkoutId INTEGER NOT NULL,
      $colSlotName TEXT NOT NULL,
      $colSlotOrder INTEGER NOT NULL,
      $colSlotCategory TEXT,
      FOREIGN KEY ($colSlotWorkoutId) REFERENCES $tableWorkouts ($colWorkoutId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableExerciseVariants (
      $colVariantId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colVariantSlotId INTEGER NOT NULL,
      $colVariantName TEXT NOT NULL,
      $colVariantDescription TEXT,
      FOREIGN KEY ($colVariantSlotId) REFERENCES $tableExerciseSlots ($colSlotId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableSetTemplates (
      $colSetTemplateId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colSetTemplateSlotId INTEGER NOT NULL,
      $colSetTemplateSetNumber INTEGER NOT NULL,
      $colSetTemplateSetType TEXT NOT NULL,
      $colSetTemplateRepsMin INTEGER,
      $colSetTemplateRepsMax INTEGER,
      $colSetTemplatePercentage1rm REAL,
      $colSetTemplateRpeTarget INTEGER,
      $colSetTemplateRestSeconds INTEGER NOT NULL,
      FOREIGN KEY ($colSetTemplateSlotId) REFERENCES $tableExerciseSlots ($colSlotId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableVariantOneRmHistory (
      $col1rmHistoryId INTEGER PRIMARY KEY AUTOINCREMENT,
      $col1rmHistoryVariantId INTEGER NOT NULL,
      $col1rmHistoryWeight REAL NOT NULL,
      $col1rmHistoryDate TEXT NOT NULL,
      $col1rmHistoryNotes TEXT,
      $col1rmHistoryIsCurrent INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($col1rmHistoryVariantId) REFERENCES $tableExerciseVariants ($colVariantId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableSessions (
      $colSessionId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colSessionWorkoutId INTEGER NOT NULL,
      $colSessionDateCompleted TEXT NOT NULL,
      $colSessionIsDeload INTEGER NOT NULL DEFAULT 0,
      $colSessionNotes TEXT,
      FOREIGN KEY ($colSessionWorkoutId) REFERENCES $tableWorkouts ($colWorkoutId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableSessionExercises (
      $colSessionExerciseId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colSessionExerciseSessionId INTEGER NOT NULL,
      $colSessionExerciseSlotId INTEGER NOT NULL,
      $colSessionExerciseChosenVariantId INTEGER NOT NULL,
      FOREIGN KEY ($colSessionExerciseSessionId) REFERENCES $tableSessions ($colSessionId),
      FOREIGN KEY ($colSessionExerciseSlotId) REFERENCES $tableExerciseSlots ($colSlotId),
      FOREIGN KEY ($colSessionExerciseChosenVariantId) REFERENCES $tableExerciseVariants ($colVariantId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableSessionSets (
      $colSessionSetId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colSessionSetSessionExerciseId INTEGER NOT NULL,
      $colSessionSetNumber INTEGER NOT NULL,
      $colSessionSetRepsCompleted INTEGER,
      $colSessionSetWeightLifted REAL,
      $colSessionSetOneRmAtTime REAL,
      $colSessionSetRpeActual INTEGER,
      $colSessionSetNotes TEXT,
      $colSessionSetTimestamp TEXT,
      FOREIGN KEY ($colSessionSetSessionExerciseId) REFERENCES $tableSessionExercises ($colSessionExerciseId)
    )
  ''');

  await db.execute('''
    CREATE TABLE $tableSettings (
      $colSettingsKey TEXT PRIMARY KEY,
      $colSettingsValue TEXT NOT NULL
    )
  ''');

  await db.execute('CREATE INDEX idx_sessions_workout_id ON $tableSessions ($colSessionWorkoutId)');
  await db.execute('CREATE INDEX idx_session_sets_session_exercise_id ON $tableSessionSets ($colSessionSetSessionExerciseId)');
  await db.execute('CREATE INDEX idx_variant_1rm_history_variant_id_date ON $tableVariantOneRmHistory ($col1rmHistoryVariantId, $col1rmHistoryDate)');
  await db.execute('CREATE INDEX idx_sessions_date ON $tableSessions ($colSessionDateCompleted)');
}

Future<void> _initializeSettings(Database db) async {
  await db.insert(tableSettings, {
    colSettingsKey: settingSchemaVersion,
    colSettingsValue: databaseVersion.toString(),
  });
  await db.insert(tableSettings, {
    colSettingsKey: settingDeloadFrequencyWeeks,
    colSettingsValue: '4',
  });
}

Future<void> closeDatabase() async {
  if (_database != null) {
    await _database!.close();
    _database = null;
  }
}

Future<void> resetDatabase() async {
  await closeDatabase();
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, databaseName);
  await deleteDatabase(path);
}
