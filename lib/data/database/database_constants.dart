/// Database version and table names
const int DATABASE_VERSION = 1;
const String DATABASE_NAME = 'workout_logger.db';

/// Table names
const String TABLE_PROGRAMS = 'programs';
const String TABLE_WORKOUTS = 'workouts';
const String TABLE_EXERCISE_SLOTS = 'exercise_slots';
const String TABLE_EXERCISE_VARIANTS = 'exercise_variants';
const String TABLE_SET_TEMPLATES = 'set_templates';
const String TABLE_VARIANT_ONE_RM_HISTORY = 'variant_one_rm_history';
const String TABLE_SESSIONS = 'sessions';
const String TABLE_SESSION_EXERCISES = 'session_exercises';
const String TABLE_SESSION_SETS = 'session_sets';
const String TABLE_SETTINGS = 'settings';

/// Column definitions for PROGRAMS
const String COL_PROGRAM_ID = 'program_id';
const String COL_PROGRAM_NAME = 'name';
const String COL_PROGRAM_VERSION = 'version';
const String COL_PROGRAM_DESCRIPTION = 'description';
const String COL_PROGRAM_CREATED_AT = 'created_at';
const String COL_PROGRAM_UPDATED_AT = 'updated_at';

/// Column definitions for WORKOUTS
const String COL_WORKOUT_ID = 'workout_id';
const String COL_WORKOUT_PROGRAM_ID = 'program_id';
const String COL_WORKOUT_NAME = 'name';
const String COL_WORKOUT_DAY_NUMBER = 'day_number';
const String COL_WORKOUT_ORDER_IN_PROGRAM = 'order_in_program';
const String COL_WORKOUT_NOTES = 'notes';

/// Column definitions for EXERCISE_SLOTS
const String COL_SLOT_ID = 'slot_id';
const String COL_SLOT_WORKOUT_ID = 'workout_id';
const String COL_SLOT_NAME = 'name';
const String COL_SLOT_ORDER = 'slot_order';
const String COL_SLOT_CATEGORY = 'category';

/// Column definitions for EXERCISE_VARIANTS
const String COL_VARIANT_ID = 'variant_id';
const String COL_VARIANT_SLOT_ID = 'slot_id';
const String COL_VARIANT_NAME = 'name';
const String COL_VARIANT_DESCRIPTION = 'description';

/// Column definitions for SET_TEMPLATES
const String COL_SET_TEMPLATE_ID = 'set_template_id';
const String COL_SET_TEMPLATE_SLOT_ID = 'slot_id';
const String COL_SET_TEMPLATE_SET_NUMBER = 'set_number';
const String COL_SET_TEMPLATE_SET_TYPE = 'set_type';
const String COL_SET_TEMPLATE_REPS_MIN = 'reps_target_min';
const String COL_SET_TEMPLATE_REPS_MAX = 'reps_target_max';
const String COL_SET_TEMPLATE_PERCENTAGE_1RM = 'percentage_1rm';
const String COL_SET_TEMPLATE_RPE_TARGET = 'rpe_target';
const String COL_SET_TEMPLATE_REST_SECONDS = 'rest_seconds';

/// Column definitions for VARIANT_ONE_RM_HISTORY
const String COL_1RM_HISTORY_ID = 'history_id';
const String COL_1RM_HISTORY_VARIANT_ID = 'variant_id';
const String COL_1RM_HISTORY_WEIGHT = 'weight';
const String COL_1RM_HISTORY_DATE = 'date';
const String COL_1RM_HISTORY_NOTES = 'notes';
const String COL_1RM_HISTORY_IS_CURRENT = 'is_current';

/// Column definitions for SESSIONS
const String COL_SESSION_ID = 'session_id';
const String COL_SESSION_WORKOUT_ID = 'workout_id';
const String COL_SESSION_DATE_COMPLETED = 'date_completed';
const String COL_SESSION_IS_DELOAD = 'is_deload';
const String COL_SESSION_NOTES = 'notes';

/// Column definitions for SESSION_EXERCISES
const String COL_SESSION_EXERCISE_ID = 'session_exercise_id';
const String COL_SESSION_EXERCISE_SESSION_ID = 'session_id';
const String COL_SESSION_EXERCISE_SLOT_ID = 'slot_id';
const String COL_SESSION_EXERCISE_CHOSEN_VARIANT_ID = 'chosen_variant_id';

/// Column definitions for SESSION_SETS
const String COL_SESSION_SET_ID = 'session_set_id';
const String COL_SESSION_SET_SESSION_EXERCISE_ID = 'session_exercise_id';
const String COL_SESSION_SET_NUMBER = 'set_number';
const String COL_SESSION_SET_REPS_COMPLETED = 'reps_completed';
const String COL_SESSION_SET_WEIGHT_LIFTED = 'weight_lifted';
const String COL_SESSION_SET_ONE_RM_AT_TIME = 'one_rm_at_session_time';
const String COL_SESSION_SET_RPE_ACTUAL = 'rpe_actual';
const String COL_SESSION_SET_NOTES = 'notes';
const String COL_SESSION_SET_TIMESTAMP = 'timestamp';

/// Column definitions for SETTINGS
const String COL_SETTINGS_KEY = 'key';
const String COL_SETTINGS_VALUE = 'value';

/// Settings keys
const String SETTING_SCHEMA_VERSION = 'schema_version';
const String SETTING_DELOAD_FREQUENCY_WEEKS = 'deload_frequency_weeks';
