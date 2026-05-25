import 'package:atlas/data/models/session.dart';
import 'package:atlas/data/models/workout.dart';
import 'package:atlas/providers/session_provider.dart';
import 'package:atlas/screens/workout_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeSessionProvider extends SessionProvider {
  _FakeSessionProvider({
    required this.fakeCurrentSession,
    required this.fakeSelectedWorkoutId,
  });

  final Session? fakeCurrentSession;
  final int? fakeSelectedWorkoutId;
  int startSessionCalls = 0;
  String? fakeError;

  @override
  Session? get currentSession => fakeCurrentSession;

  @override
  int? get selectedWorkoutId => fakeSelectedWorkoutId;

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
  testWidgets('prompts to resume when matching incomplete session exists', (
    tester,
  ) async {
    final provider = _FakeSessionProvider(
      fakeCurrentSession: Session(
        id: 50,
        workoutId: 1,
        dateCompleted: DateTime.now(),
      ),
      fakeSelectedWorkoutId: 1,
    );

    await tester.pumpWidget(_buildHarness(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();

    expect(find.text('Resume Incomplete Session?'), findsOneWidget);
    expect(find.text('Continue Workout'), findsOneWidget);
    expect(find.text('Start New'), findsOneWidget);
  });

  testWidgets('start new from prompt creates a new session', (tester) async {
    final provider = _FakeSessionProvider(
      fakeCurrentSession: Session(
        id: 77,
        workoutId: 1,
        dateCompleted: DateTime.now(),
      ),
      fakeSelectedWorkoutId: 1,
    );

    await tester.pumpWidget(_buildHarness(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start New'));
    await tester.pumpAndSettle();

    expect(provider.startSessionCalls, 1);
  });
}
