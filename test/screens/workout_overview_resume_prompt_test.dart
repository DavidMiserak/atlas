import 'package:atlas/data/models/workout.dart';
import 'package:atlas/providers/session_provider.dart';
import 'package:atlas/screens/workout_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeSessionProvider extends SessionProvider {
  _FakeSessionProvider({required this.hasIncompleteSession});

  final bool hasIncompleteSession;
  int startSessionCalls = 0;
  int resumeSessionCalls = 0;
  String? fakeError;

  @override
  String? get error => fakeError;

  @override
  Future<Map<int, int>> getLastUsedVariantIdsForSlots(List<int> slotIds) async {
    return {};
  }

  @override
  Future<void> startSession(
    int workoutId, {
    Map<int, int>? preselectedVariantsBySlot,
  }) async {
    startSessionCalls++;
    fakeError = null;
  }

  @override
  Future<bool> hasIncompleteSessionForWorkout(int workoutId) async {
    return hasIncompleteSession;
  }

  @override
  Future<bool> getIncompleteSessionIsDemoForWorkout(int workoutId) async {
    return false;
  }

  @override
  Future<void> resumeIncompleteSessionForWorkout(int workoutId) async {
    resumeSessionCalls++;
    fakeError = null;
  }
}

Workout _buildWorkout() {
  return Workout(
    id: 1,
    programId: 1,
    name: 'Lower Body',
    dayNumber: 1,
    orderInProgram: 1,
    exerciseSlots: [
      ExerciseSlot(
        id: 10,
        workoutId: 1,
        name: 'Squat',
        slotOrder: 1,
        variants: [ExerciseVariant(id: 100, slotId: 10, name: 'Back Squat')],
      ),
    ],
  );
}

Widget _buildHarness(SessionProvider provider) {
  return ChangeNotifierProvider<SessionProvider>.value(
    value: provider,
    child: MaterialApp(
      home: WorkoutOverviewScreen(
        workout: _buildWorkout(),
        accentColor: Colors.blue,
      ),
    ),
  );
}

void main() {
  testWidgets('shows continue and start-new options in pre-flight', (
    tester,
  ) async {
    final provider = _FakeSessionProvider(hasIncompleteSession: true);

    await tester.pumpWidget(_buildHarness(provider));
    await tester.pumpAndSettle();

    expect(find.text('Continue Session'), findsOneWidget);
    expect(find.text('Start a new session instead'), findsOneWidget);
    expect(find.textContaining('Incomplete session found.'), findsOneWidget);
  });

  testWidgets('start new from pre-flight creates a new session', (
    tester,
  ) async {
    final provider = _FakeSessionProvider(hasIncompleteSession: true);

    await tester.pumpWidget(_buildHarness(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start a new session instead'));
    await tester.pumpAndSettle();

    expect(provider.startSessionCalls, 1);
  });

  testWidgets('continue session uses resume flow', (tester) async {
    final provider = _FakeSessionProvider(hasIncompleteSession: true);

    await tester.pumpWidget(_buildHarness(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue Session'));
    await tester.pumpAndSettle();

    expect(provider.resumeSessionCalls, 1);
  });
}
