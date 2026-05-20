import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';

/// Singleton database instance
Database? _database;

/// Initialize and return the database
Future<Database> getDatabase() async {
  if (_database != null) return _database!;
  _database = await _initDatabase();
  return _database!;
}

Future<Database> _initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, DATABASE_NAME);

  return await openDatabase(
    path,
    version: DATABASE_VERSION,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

/// Create all tables on first install
Future<void> _onCreate(Database db, int version) async {
  await _createTables(db);
  await _initializeSettings(db);
}

/// Handle schema upgrades
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Future: implement migrations from v1 → v2, etc.
  // For now, no upgrades (MVP is v1 only)
}

Future<void> _createTables(Database db) async {
  // PROGRAMS table
  await db.execute('''
    CREATE TABLE $TABLE_PROGRAMS (
      $COL_PROGRAM_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_PROGRAM_NAME TEXT NOT NULL,
      $COL_PROGRAM_VERSION TEXT NOT NULL,
      $COL_PROGRAM_DESCRIPTION TEXT,
      $COL_PROGRAM_CREATED_AT TEXT NOT NULL,
      $COL_PROGRAM_UPDATED_AT TEXT NOT NULL
    )
  ''');

  // WORKOUTS table
  await db.execute('''
    CREATE TABLE $TABLE_WORKOUTS (
      $COL_WORKOUT_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_WORKOUT_PROGRAM_ID INTEGER NOT NULL,
      $COL_WORKOUT_NAME TEXT NOT NULL,
      $COL_WORKOUT_DAY_NUMBER INTEGER NOT NULL,
      $COL_WORKOUT_ORDER_IN_PROGRAM INTEGER NOT NULL,
      $COL_WORKOUT_NOTES TEXT,
      FOREIGN KEY ($COL_WORKOUT_PROGRAM_ID) REFERENCES $TABLE_PROGRAMS ($COL_PROGRAM_ID)
    )
  ''');

  // EXERCISE_SLOTS table
  await db.execute('''
    CREATE TABLE $TABLE_EXERCISE_SLOTS (
      $COL_SLOT_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_SLOT_WORKOUT_ID INTEGER NOT NULL,
      $COL_SLOT_NAME TEXT NOT NULL,
      $COL_SLOT_ORDER INTEGER NOT NULL,
      $COL_SLOT_CATEGORY TEXT,
      FOREIGN KEY ($COL_SLOT_WORKOUT_ID) REFERENCES $TABLE_WORKOUTS ($COL_WORKOUT_ID)
    )
  ''');

  // EXERCISE_VARIANTS table
  await db.execute('''
    CREATE TABLE $TABLE_EXERCISE_VARIANTS (
      $COL_VARIANT_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_VARIANT_SLOT_ID INTEGER NOT NULL,
      $COL_VARIANT_NAME TEXT NOT NULL,
      $COL_VARIANT_DESCRIPTION TEXT,
      FOREIGN KEY ($COL_VARIANT_SLOT_ID) REFERENCES $TABLE_EXERCISE_SLOTS ($COL_SLOT_ID)
    )
  ''');

  // SET_TEMPLATES table
  await db.execute('''
    CREATE TABLE $TABLE_SET_TEMPLATES (
      $COL_SET_TEMPLATE_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_SET_TEMPLATE_SLOT_ID INTEGER NOT NULL,
      $COL_SET_TEMPLATE_SET_NUMBER INTEGER NOT NULL,
      $COL_SET_TEMPLATE_SET_TYPE TEXT NOT NULL,
      $COL_SET_TEMPLATE_REPS_MIN INTEGER,
      $COL_SET_TEMPLATE_REPS_MAX INTEGER,
      $COL_SET_TEMPLATE_PERCENTAGE_1RM REAL,
      $COL_SET_TEMPLATE_RPE_TARGET INTEGER,
      $COL_SET_TEMPLATE_REST_SECONDS INTEGER NOT NULL,
      FOREIGN KEY ($COL_SET_TEMPLATE_SLOT_ID) REFERENCES $TABLE_EXERCISE_SLOTS ($COL_SLOT_ID)
    )
  ''');

  // VARIANT_ONE_RM_HISTORY table
  await db.execute('''
    CREATE TABLE $TABLE_VARIANT_ONE_RM_HISTORY (
      $COL_1RM_HISTORY_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_1RM_HISTORY_VARIANT_ID INTEGER NOT NULL,
      $COL_1RM_HISTORY_WEIGHT REAL NOT NULL,
      $COL_1RM_HISTORY_DATE TEXT NOT NULL,
      $COL_1RM_HISTORY_NOTES TEXT,
      $COL_1RM_HISTORY_IS_CURRENT INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($COL_1RM_HISTORY_VARIANT_ID) REFERENCES $TABLE_EXERCISE_VARIANTS ($COL_VARIANT_ID)
    )
  ''');

  // SESSIONS table
  await db.execute('''
    CREATE TABLE $TABLE_SESSIONS (
      $COL_SESSION_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_SESSION_WORKOUT_ID INTEGER NOT NULL,
      $COL_SESSION_DATE_COMPLETED TEXT NOT NULL,
      $COL_SESSION_IS_DELOAD INTEGER NOT NULL DEFAULT 0,
      $COL_SESSION_NOTES TEXT,
      FOREIGN KEY ($COL_SESSION_WORKOUT_ID) REFERENCES $TABLE_WORKOUTS ($COL_WORKOUT_ID)
    )
  ''');

  // SESSION_EXERCISES table
  await db.execute('''
    CREATE TABLE $TABLE_SESSION_EXERCISES (
      $COL_SESSION_EXERCISE_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_SESSION_EXERCISE_SESSION_ID INTEGER NOT NULL,
      $COL_SESSION_EXERCISE_SLOT_ID INTEGER NOT NULL,
      $COL_SESSION_EXERCISE_CHOSEN_VARIANT_ID INTEGER NOT NULL,
      FOREIGN KEY ($COL_SESSION_EXERCISE_SESSION_ID) REFERENCES $TABLE_SESSIONS ($COL_SESSION_ID),
      FOREIGN KEY ($COL_SESSION_EXERCISE_SLOT_ID) REFERENCES $TABLE_EXERCISE_SLOTS ($COL_SLOT_ID),
      FOREIGN KEY ($COL_SESSION_EXERCISE_CHOSEN_VARIANT_ID) REFERENCES $TABLE_EXERCISE_VARIANTS ($COL_VARIANT_ID)
    )
  ''');

  // SESSION_SETS table
  await db.execute('''
    CREATE TABLE $TABLE_SESSION_SETS (
      $COL_SESSION_SET_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $COL_SESSION_SET_SESSION_EXERCISE_ID INTEGER NOT NULL,
      $COL_SESSION_SET_NUMBER INTEGER NOT NULL,
      $COL_SESSION_SET_REPS_COMPLETED INTEGER,
      $COL_SESSION_SET_WEIGHT_LIFTED REAL,
      $COL_SESSION_SET_ONE_RM_AT_TIME REAL,
      $COL_SESSION_SET_RPE_ACTUAL INTEGER,
      $COL_SESSION_SET_NOTES TEXT,
      $COL_SESSION_SET_TIMESTAMP TEXT,
      FOREIGN KEY ($COL_SESSION_SET_SESSION_EXERCISE_ID) REFERENCES $TABLE_SESSION_EXERCISES ($COL_SESSION_EXERCISE_ID)
    )
  ''');

  // SETTINGS table
  await db.execute('''
    CREATE TABLE $TABLE_SETTINGS (
      $COL_SETTINGS_KEY TEXT PRIMARY KEY,
      $COL_SETTINGS_VALUE TEXT NOT NULL
    )
  ''');

  // Create indexes for critical queries
  await db.execute(
    'CREATE INDEX idx_sessions_workout_id ON $TABLE_SESSIONS ($COL_SESSION_WORKOUT_ID)'
  );
  await db.execute(
    'CREATE INDEX idx_session_sets_session_exercise_id ON $TABLE_SESSION_SETS ($COL_SESSION_SET_SESSION_EXERCISE_ID)'
  );
  await db.execute(
    'CREATE INDEX idx_variant_1rm_history_variant_id_date ON $TABLE_VARIANT_ONE_RM_HISTORY ($COL_1RM_HISTORY_VARIANT_ID, $COL_1RM_HISTORY_DATE)'
  );
  await db.execute(
    'CREATE INDEX idx_sessions_date ON $TABLE_SESSIONS ($COL_SESSION_DATE_COMPLETED)'
  );
}

/// Initialize settings table with defaults
Future<void> _initializeSettings(Database db) async {
  await db.insert(
    TABLE_SETTINGS,
    {
      COL_SETTINGS_KEY: SETTING_SCHEMA_VERSION,
      COL_SETTINGS_VALUE: DATABASE_VERSION.toString(),
    },
  );

  await db.insert(
    TABLE_SETTINGS,
    {
      COL_SETTINGS_KEY: SETTING_DELOAD_FREQUENCY_WEEKS,
      COL_SETTINGS_VALUE: '4',
    },
  );
}

/// Close database (call on app shutdown)
Future<void> closeDatabase() async {
  if (_database != null) {
    await _database!.close();
    _database = null;
  }
}
