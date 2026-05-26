import 'package:url_launcher/url_launcher.dart';

const Map<String, String> _exerciseReferenceUrls = {
  // Squat / hip-dominant
  'Back Squat':                  'https://exrx.net/WeightExercises/GluteusMaximus/BBSquat',
  'Front Squat':                 'https://exrx.net/WeightExercises/GluteusMaximus/BBFrontSquat',
  'Safety Bar Squat':            'https://exrx.net/WeightExercises/GluteusMaximus/SBSquat',
  'Hack Squat':                  'https://exrx.net/WeightExercises/Quadriceps/BBHackSquat',
  'Hack Squat Machine':          'https://exrx.net/WeightExercises/GluteusMaximus/LVHackSquat',
  'Smith Machine Squat':         'https://exrx.net/WeightExercises/GluteusMaximus/SMSquat',
  'V-Squat Machine':             'https://exrx.net/WeightExercises/GluteusMaximus/LVVSquat',
  'Goblet Squat':                'https://exrx.net/WeightExercises/Kettlebell/KBGobletSquat',

  // Hip hinge / deadlift
  'Sumo Deadlift':               'https://exrx.net/WeightExercises/Power/BBSumoDeadliftHighPull',
  'Conventional Deadlift':       'https://exrx.net/WeightExercises/GluteusMaximus/BBDeadlift',
  'Romanian Deadlift':           'https://exrx.net/WeightExercises/OlympicLifts/RomanianDeadlift',
  'Smith Machine Deadlift':      'https://exrx.net/WeightExercises/GluteusMaximus/SMDeadlift',
  'Good Morning':                'https://exrx.net/WeightExercises/Hamstrings/BBGoodMorning',
  'Weighted Back Extension':     'https://exrx.net/WeightExercises/ErectorSpinae/WtBackExtension',

  // Unilateral legs
  'Bulgarian Split Squat':       'https://exrx.net/WeightExercises/GluteusMaximus/DBSingleLegSplitSquat',
  'Walking Lunges':              'https://exrx.net/WeightExercises/GluteusMaximus/DBLunge',
  'Step-Ups':                    'https://exrx.net/WeightExercises/GluteusMaximus/DBStepUp',
  'Single-Leg Press':            'https://exrx.net/WeightExercises/GluteusMaximus/LVSingleLegLegPress',

  // Leg press / extension / curl machines
  'Leg Press Machine':           'https://exrx.net/WeightExercises/GluteusMaximus/LVSeatedLegPress',
  'Leg Extension Machine':       'https://exrx.net/WeightExercises/Quadriceps/LVLegExtension',
  'Lying Leg Curl Machine':      'https://exrx.net/WeightExercises/Hamstrings/LVLyingLegCurl',
  'Seated Leg Curl':             'https://exrx.net/WeightExercises/Hamstrings/LVSeatedLegCurl',
  'Standing Leg Curl Machine':   'https://exrx.net/WeightExercises/Hamstrings/LVStandingLegCurl',

  // Calf
  'Barbell Calf Raise':          'https://exrx.net/WeightExercises/Gastrocnemius/BBStandingCalfRaise',
  'Dumbbell Calf Raises':        'https://exrx.net/WeightExercises/Gastrocnemius/DBStandingCalfRaise',
  'Calf Raise Machine':          'https://exrx.net/WeightExercises/Gastrocnemius/LVStandingCalfRaise',
  'Seated Calf Raise Machine':   'https://exrx.net/WeightExercises/Soleus/LVSeatedCalfRaise',

  // Chest — barbell / dumbbell
  'Barbell Bench Press':         'https://exrx.net/WeightExercises/PectoralSternal/BBBenchPress',
  'Dumbbell Bench Press':        'https://exrx.net/WeightExercises/PectoralSternal/DBBenchPress',
  'Incline Barbell Press':       'https://exrx.net/WeightExercises/PectoralClavicular/BBInclineBenchPress',
  'Incline Dumbbell Press':      'https://exrx.net/WeightExercises/PectoralClavicular/DBInclineBenchPress',
  'Close-Grip Bench Press':      'https://exrx.net/WeightExercises/Triceps/BBCloseGripBenchPress',
  'Dumbbell Flys':               'https://exrx.net/WeightExercises/PectoralSternal/DBFly',

  // Chest — cable / machine
  'Cable Chest Press':           'https://exrx.net/WeightExercises/PectoralSternal/CBChestPress',
  'Cable Flys':                  'https://exrx.net/WeightExercises/PectoralSternal/CBStandingFly',
  'Incline Cable Press':         'https://exrx.net/WeightExercises/PectoralClavicular/CBInclineChestPress',
  'Chest Press Machine':         'https://exrx.net/WeightExercises/PectoralSternal/LVChestPress',
  'Incline Chest Press Machine': 'https://exrx.net/WeightExercises/PectoralClavicular/LVInclineChestPress',
  'Pec Deck Machine':            'https://exrx.net/WeightExercises/PectoralSternal/LVPecDeckFly',

  // Shoulder
  'Overhead Press':              'https://exrx.net/WeightExercises/DeltoidAnterior/BBMilitaryPress',
  'Dumbbell Shoulder Press':     'https://exrx.net/WeightExercises/DeltoidAnterior/DBShoulderPress',
  'Seated Press':                'https://exrx.net/WeightExercises/DeltoidAnterior/BBSeatedMilitaryPress',
  'Cable Shoulder Press':        'https://exrx.net/WeightExercises/DeltoidAnterior/CBShoulderPress',
  'Shoulder Press Machine':      'https://exrx.net/WeightExercises/DeltoidAnterior/LVShoulderPress',

  // Back — rows
  'Barbell Row':                 'https://exrx.net/WeightExercises/BackGeneral/BBBentOverRow',
  'Dumbbell Row':                'https://exrx.net/WeightExercises/BackGeneral/DBBentOverRow',
  'T-Bar Row':                   'https://exrx.net/WeightExercises/BackGeneral/LVTBarRow',
  'T-Bar Row Machine':           'https://exrx.net/WeightExercises/BackGeneral/LVTBarRow',
  'Cable Row':                   'https://exrx.net/WeightExercises/BackGeneral/CBSeatedRow',
  'Machine Row':                 'https://exrx.net/WeightExercises/BackGeneral/LVSeatedRow',

  // Back — pulldowns / pull-ups
  'Pull-ups':                    'https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup',
  'Chin-ups':                    'https://exrx.net/WeightExercises/LatissimusDorsi/BWUnderhandChinup',
  'Lat Pulldown':                'https://exrx.net/WeightExercises/LatissimusDorsi/CBFrontPulldown',
  'Cable Pulldown':              'https://exrx.net/WeightExercises/LatissimusDorsi/CBFrontPulldown',

  // Biceps
  'Barbell Curls':               'https://exrx.net/WeightExercises/Biceps/BBCurl',
  'Dumbbell Curls':              'https://exrx.net/WeightExercises/Biceps/DBCurl',
  'Hammer Curls':                'https://exrx.net/WeightExercises/Brachioradialis/DBHammerCurl',
  'Cable Curls':                 'https://exrx.net/WeightExercises/Biceps/CBCurl',
  'Machine Curls':               'https://exrx.net/WeightExercises/Biceps/LVCurl',

  // Triceps
  'Dips':                        'https://exrx.net/WeightExercises/Triceps/WtTriDip',
  'Tricep Dips':                 'https://exrx.net/WeightExercises/Triceps/WtTriDip',
  'Overhead Dumbbell Extension': 'https://exrx.net/WeightExercises/Triceps/DBTriExt',
  'Cable Tricep Pushdown':       'https://exrx.net/WeightExercises/Triceps/CBPushdown',
  'Cable Overhead Extensions':   'https://exrx.net/WeightExercises/Triceps/CBTriExt',
  'Cable Pull-Through':          'https://exrx.net/WeightExercises/RectusAbdominis/STPullThrough',

  // Biceps — machine
  'Preacher Curl Machine':       'https://exrx.net/WeightExercises/Brachioradialis/LVHammerPreacherCurlPL',
};

String exrxReferenceUrl(String variantName) {
  final direct = _exerciseReferenceUrls[variantName];
  if (direct != null) return direct;
  return 'https://exrx.net/Search?q=${Uri.encodeQueryComponent(variantName)}';
}

Future<bool> launchExrxReference(String variantName) async {
  try {
    return await launchUrl(
      Uri.parse(exrxReferenceUrl(variantName)),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
