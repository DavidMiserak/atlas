const int databaseVersion = 4;
const String databaseName = 'workout_logger.db';

const String tablePrograms = 'programs';
const String tableWorkouts = 'workouts';
const String tableExerciseSlots = 'exercise_slots';
const String tableExerciseVariants = 'exercise_variants';
const String tableSetTemplates = 'set_templates';
const String tableVariantOneRmHistory = 'variant_one_rm_history';
const String tableSessions = 'sessions';
const String tableSessionExercises = 'session_exercises';
const String tableSessionSets = 'session_sets';
const String tableSettings = 'settings';
const String tableWarmupItems = 'warmup_items';

const String colProgramId = 'program_id';
const String colProgramName = 'name';
const String colProgramVersion = 'version';
const String colProgramDescription = 'description';
const String colProgramCreatedAt = 'created_at';
const String colProgramUpdatedAt = 'updated_at';

const String colWorkoutId = 'workout_id';
const String colWorkoutProgramId = 'program_id';
const String colWorkoutName = 'name';
const String colWorkoutDayNumber = 'day_number';
const String colWorkoutOrderInProgram = 'order_in_program';
const String colWorkoutNotes = 'notes';

const String colSlotId = 'slot_id';
const String colSlotWorkoutId = 'workout_id';
const String colSlotName = 'name';
const String colSlotOrder = 'slot_order';
const String colSlotCategory = 'category';

const String colVariantId = 'variant_id';
const String colVariantSlotId = 'slot_id';
const String colVariantName = 'name';
const String colVariantDescription = 'description';

const String colSetTemplateId = 'set_template_id';
const String colSetTemplateSlotId = 'slot_id';
const String colSetTemplateSetNumber = 'set_number';
const String colSetTemplateSetType = 'set_type';
const String colSetTemplateRepsMin = 'reps_target_min';
const String colSetTemplateRepsMax = 'reps_target_max';
const String colSetTemplatePercentage1rm = 'percentage_1rm';
const String colSetTemplateRpeTarget = 'rpe_target';
const String colSetTemplateRestSeconds = 'rest_seconds';

const String col1rmHistoryId = 'history_id';
const String col1rmHistoryVariantId = 'variant_id';
const String col1rmHistoryWeight = 'weight';
const String col1rmHistoryDate = 'date';
const String col1rmHistoryNotes = 'notes';
const String col1rmHistoryIsCurrent = 'is_current';

const String colSessionId = 'session_id';
const String colSessionWorkoutId = 'workout_id';
const String colSessionDateCompleted = 'date_completed';
const String colSessionIsDeload = 'is_deload';
const String colSessionNotes = 'notes';

const String colSessionExerciseId = 'session_exercise_id';
const String colSessionExerciseSessionId = 'session_id';
const String colSessionExerciseSlotId = 'slot_id';
const String colSessionExerciseChosenVariantId = 'chosen_variant_id';

const String colSessionSetId = 'session_set_id';
const String colSessionSetSessionExerciseId = 'session_exercise_id';
const String colSessionSetNumber = 'set_number';
const String colSessionSetRepsCompleted = 'reps_completed';
const String colSessionSetWeightLifted = 'weight_lifted';
const String colSessionSetOneRmAtTime = 'one_rm_at_session_time';
const String colSessionSetRpeActual = 'rpe_actual';
const String colSessionSetNotes = 'notes';
const String colSessionSetTimestamp = 'timestamp';
const String colSessionSetIsWarmup = 'is_warmup';

const String colSettingsKey = 'key';
const String colSettingsValue = 'value';

const String settingSchemaVersion = 'schema_version';
const String settingDeloadFrequencyWeeks = 'deload_frequency_weeks';
const String settingOneRmFormula = 'one_rm_formula';

const String colWarmupItemId = 'warmup_item_id';
const String colWarmupItemName = 'name';
const String colWarmupItemReps = 'reps';
const String colWarmupItemOrder = 'order_index';
