import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/data/reference/exercise_reference_urls.dart';

void main() {
  group('exrxReferenceUrl', () {
    test('T1: known exercise returns curated direct URL', () {
      expect(
        exrxReferenceUrl('Back Squat'),
        equals('https://exrx.net/WeightExercises/GluteusMaximus/BBSquat'),
      );
    });

    test('T2: unknown exercise returns ExRx search URL with correct encoding', () {
      final url = exrxReferenceUrl('Single-Leg RDL');
      expect(url, startsWith('https://exrx.net/Search?q='));
      expect(url, contains('Single-Leg+RDL'));
    });

    test('T3: empty string returns ExRx search URL', () {
      final url = exrxReferenceUrl('');
      expect(url, startsWith('https://exrx.net/Search?q='));
    });

    test('T4: all 69 exercise names from enrichedVariantDescriptions produce non-empty URLs', () {
      const exerciseNames = [
        'Back Squat', 'Barbell Bench Press', 'Barbell Calf Raise',
        'Barbell Curls', 'Barbell Row', 'Bulgarian Split Squat',
        'Calf Raise Machine', 'Cable Chest Press', 'Cable Curls',
        'Cable Deadlift', 'Cable Flys', 'Cable Overhead Extensions',
        'Cable Pull-Through', 'Cable Pulldown', 'Cable Row',
        'Cable Shoulder Press', 'Cable Tricep Pushdown', 'Chest Press Machine',
        'Chin-ups', 'Close-Grip Bench Press', 'Conventional Deadlift',
        'Dips', 'Dumbbell Bench Press', 'Dumbbell Calf Raises',
        'Dumbbell Curls', 'Dumbbell Flys', 'Dumbbell Row',
        'Dumbbell Shoulder Press', 'Front Squat', 'Goblet Squat',
        'Good Morning', 'Hack Squat', 'Hack Squat Machine',
        'Hammer Curls', 'Incline Barbell Press', 'Incline Cable Press',
        'Incline Chest Press Machine', 'Incline Dumbbell Press',
        'Lat Pulldown', 'Leg Extension Machine', 'Leg Press Machine',
        'Lying Leg Curl Machine', 'Machine Curls', 'Machine Row',
        'Machine Step-Ups', 'Overhead Dumbbell Extension', 'Overhead Press',
        'Pec Deck Machine', 'Preacher Curl Machine', 'Pull-ups',
        'Romanian Deadlift', 'Safety Bar Squat', 'Seated Calf Raise Machine',
        'Seated Leg Curl', 'Seated Press', 'Shoulder Press Machine',
        'Single-Leg Press', 'Single-Leg RDL', 'Smith Machine Deadlift',
        'Smith Machine Squat', 'Standing Leg Curl Machine', 'Step-Ups',
        'Sumo Deadlift', 'T-Bar Row', 'T-Bar Row Machine',
        'Tricep Dips', 'V-Squat Machine', 'Walking Lunges',
        'Weighted Back Extension',
      ];
      for (final name in exerciseNames) {
        final url = exrxReferenceUrl(name);
        expect(url, isNotEmpty, reason: 'URL for "$name" should not be empty');
        expect(url, startsWith('https://'), reason: 'URL for "$name" should be https');
      }
    });

    test('T5: no two exercises share the same curated URL', () {
      // Known intentional URL duplicates (same exercise, different names):
      //   Dips / Tricep Dips → same Dip page
      //   Cable Pulldown / Lat Pulldown → same CBFrontPullDown page
      const knownDuplicatePairs = [
        {'Dips', 'Tricep Dips'},
        {'Cable Pulldown', 'Lat Pulldown'},
        {'T-Bar Row', 'T-Bar Row Machine'},
      ];
      bool isKnownDuplicate(String a, String b) =>
          knownDuplicatePairs.any((pair) => pair.contains(a) && pair.contains(b));
      const knownExercises = [
        'Back Squat', 'Front Squat', 'Safety Bar Squat', 'Sumo Deadlift', 'Conventional Deadlift',
        'Romanian Deadlift', 'Good Morning', 'Bulgarian Split Squat',
        'Walking Lunges', 'Step-Ups', 'Goblet Squat', 'Barbell Bench Press',
        'Dumbbell Bench Press', 'Incline Barbell Press', 'Incline Dumbbell Press',
        'Close-Grip Bench Press', 'Overhead Press', 'Dumbbell Shoulder Press',
        'Barbell Row', 'Dumbbell Row', 'T-Bar Row', 'Pull-ups', 'Chin-ups',
        'Lat Pulldown', 'Barbell Calf Raise', 'Dumbbell Calf Raises',
        'Barbell Curls', 'Dumbbell Curls', 'Hammer Curls', 'Dips', 'Tricep Dips',
        'Dumbbell Flys', 'Overhead Dumbbell Extension', 'Cable Pulldown',
        'Cable Row', 'Cable Curls', 'Cable Flys', 'Cable Tricep Pushdown',
        'Cable Overhead Extensions', 'Cable Pull-Through', 'Cable Chest Press',
        'Cable Shoulder Press', 'Incline Cable Press',
        'Leg Press Machine', 'Leg Extension Machine', 'Lying Leg Curl Machine',
        'Seated Leg Curl', 'Standing Leg Curl Machine', 'Single-Leg Press',
        'Calf Raise Machine', 'Seated Calf Raise Machine',
        'Chest Press Machine', 'Incline Chest Press Machine', 'Pec Deck Machine',
        'Machine Row', 'Machine Curls', 'T-Bar Row Machine',
        'Shoulder Press Machine', 'Seated Press',
        'Hack Squat', 'Hack Squat Machine', 'Smith Machine Squat',
        'Smith Machine Deadlift', 'V-Squat Machine', 'Weighted Back Extension',
      ];

      final urlsSeen = <String, String>{};
      for (final name in knownExercises) {
        final url = exrxReferenceUrl(name);
        if (urlsSeen.containsKey(url)) {
          final other = urlsSeen[url]!;
          expect(
            isKnownDuplicate(name, other),
            isTrue,
            reason: '"$name" and "$other" share URL $url unexpectedly',
          );
        } else {
          urlsSeen[url] = name;
        }
      }
    });
  });
}
