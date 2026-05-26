import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

/// Enriched variant descriptions (program.json + exercises.json catalog).
const Map<String, String> enrichedVariantDescriptions = {
  'Back Squat': 'Primary: quads, glutes, hamstrings — barbell',
  'Barbell Bench Press': 'Primary: chest, triceps — barbell',
  'Barbell Calf Raise': 'Primary: calves — barbell',
  'Barbell Curls': 'Primary: biceps — barbell',
  'Barbell Row': 'Primary: lats, rhomboids, biceps — barbell',
  'Bulgarian Split Squat': 'Primary: quads, glutes — dumbbell',
  'Calf Raise Machine': 'Primary: calves — machine',
  'Cable Chest Press': 'Primary: chest, triceps — cable',
  'Cable Curls': 'Primary: biceps — cable',
  'Cable Deadlift': 'Primary: hamstrings, glutes — cable',
  'Cable Flys': 'Primary: chest — cable',
  'Cable Overhead Extensions': 'Primary: triceps — cable',
  'Cable Pull-Through': 'Primary: glutes, hamstrings — cable',
  'Cable Pulldown': 'Primary: lats, biceps — cable',
  'Cable Row': 'Primary: lats, rhomboids — cable',
  'Cable Shoulder Press': 'Primary: shoulders, triceps — cable',
  'Cable Tricep Pushdown': 'Primary: triceps — cable',
  'Chest Press Machine': 'Primary: chest, triceps — machine',
  'Chin-ups': 'Primary: lats, biceps — bodyweight',
  'Close-Grip Bench Press': 'Primary: triceps, chest — barbell',
  'Conventional Deadlift': 'Primary: hamstrings, glutes, back — barbell',
  'Dips': 'Primary: triceps, chest — bodyweight',
  'Dumbbell Bench Press': 'Primary: chest, triceps — dumbbell',
  'Dumbbell Calf Raises': 'Primary: calves — dumbbell',
  'Dumbbell Curls': 'Primary: biceps — dumbbell',
  'Dumbbell Flys': 'Primary: chest — dumbbell',
  'Dumbbell Row': 'Primary: lats, rhomboids — dumbbell',
  'Dumbbell Shoulder Press': 'Primary: shoulders, triceps — dumbbell',
  'Front Squat': 'Primary: quads, core — barbell',
  'Goblet Squat': 'Primary: quads, glutes — dumbbell',
  'Good Morning': 'Primary: hamstrings, lower back — barbell',
  'Hack Squat': 'Primary: quads, glutes — machine',
  'Hack Squat Machine': 'Primary: quads, glutes — machine',
  'Hammer Curls': 'Primary: biceps, brachialis — dumbbell',
  'Incline Barbell Press': 'Primary: upper chest, shoulders — barbell',
  'Incline Cable Press': 'Primary: upper chest — cable',
  'Incline Chest Press Machine': 'Primary: upper chest — machine',
  'Incline Dumbbell Press': 'Primary: upper chest — dumbbell',
  'Lat Pulldown': 'Primary: lats, biceps — cable',
  'Leg Extension Machine': 'Primary: quads — machine',
  'Leg Press Machine': 'Primary: quads, glutes — machine',
  'Lying Leg Curl Machine': 'Primary: hamstrings — machine',
  'Machine Curls': 'Primary: biceps — machine',
  'Machine Row': 'Primary: lats, rhomboids — machine',
  'Machine Step-Ups': 'Primary: quads, glutes — machine',
  'Overhead Dumbbell Extension': 'Primary: triceps — dumbbell',
  'Overhead Press': 'Primary: shoulders, triceps — barbell',
  'Pec Deck Machine': 'Primary: chest — machine',
  'Preacher Curl Machine': 'Primary: biceps — machine',
  'Pull-ups': 'Primary: lats, biceps — bodyweight',
  'Romanian Deadlift': 'Primary: hamstrings, glutes — barbell',
  'Safety Bar Squat': 'Primary: quads, glutes, hamstrings — barbell',
  'Seated Calf Raise Machine': 'Primary: calves — machine',
  'Seated Leg Curl': 'Primary: hamstrings — machine',
  'Seated Press': 'Primary: shoulders, triceps — dumbbell',
  'Shoulder Press Machine': 'Primary: shoulders — machine',
  'Single-Leg Press': 'Primary: quads, glutes — machine',
  'Single-Leg RDL': 'Primary: hamstrings, glutes — dumbbell',
  'Smith Machine Deadlift': 'Primary: hamstrings, glutes, back — smith machine',
  'Smith Machine Squat': 'Primary: quads, glutes — smith machine',
  'Standing Leg Curl Machine': 'Primary: hamstrings — machine',
  'Step-Ups': 'Primary: quads, glutes — dumbbell',
  'Sumo Deadlift': 'Primary: quads, glutes, adductors — barbell',
  'T-Bar Row': 'Primary: lats, rhomboids — barbell',
  'T-Bar Row Machine': 'Primary: lats, rhomboids — machine',
  'Tricep Dips': 'Primary: triceps, chest — bodyweight',
  'V-Squat Machine': 'Primary: quads, glutes — machine',
  'Walking Lunges': 'Primary: quads, glutes — dumbbell',
  'Weighted Back Extension': 'Primary: lower back, glutes — bodyweight',
};

/// Returns enriched copy for a variant name, or null if unknown.
String? descriptionForVariant(String name) {
  return enrichedVariantDescriptions[name];
}

bool shouldMigrateVariantDescription(String name, String? current) {
  if (current == null || current.trim().isEmpty) return true;
  if (current.trim().toLowerCase() == name.trim().toLowerCase()) return true;
  if (!current.trim().startsWith('Primary:')) {
    return descriptionForVariant(name) != null;
  }
  return false;
}

Future<void> migrateExerciseDescriptions(DatabaseExecutor db) async {
  final rows = await db.query(
    tableExerciseVariants,
    columns: [colVariantId, colVariantName, colVariantDescription],
  );

  for (final row in rows) {
    final name = row[colVariantName] as String;
    final current = row[colVariantDescription] as String?;
    final enriched = descriptionForVariant(name);
    if (enriched == null) continue;
    if (!shouldMigrateVariantDescription(name, current)) continue;

    await db.update(
      tableExerciseVariants,
      {colVariantDescription: enriched},
      where: '$colVariantId = ?',
      whereArgs: [row[colVariantId]],
    );
  }
}
