import 'package:atlas/data/models/session.dart';
import 'package:atlas/data/models/workout.dart';
import 'package:atlas/providers/session_provider.dart';
import 'package:atlas/screens/session_screen.dart';
import 'package:atlas/screens/workout_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ─── shared fixture ───────────────────────────────────────────────────────────

final _slot = ExerciseSlot(
  id: 10,
  workoutId: 1,
  name: 'Squat',
  slotOrder: 1,
  variants: [ExerciseVariant(id: 100, slotId: 10, name: 'Back Squat')],
);

final _sessionExercise = SessionExercise(
  id: 1,
  sessionId: 1,
  slotId: 10,
  chosenVariantId: 100,
);

Workout _buildWorkout() => Workout(
  id: 1,
  programId: 1,
  name: 'Lower Body',
  dayNumber: 1,
  orderInProgram: 1,
  exerciseSlots: [_slot],
);

// ─── fake provider for SessionScreen ─────────────────────────────────────────

class _FakeSessionScreenProvider extends SessionProvider {
  _FakeSessionScreenProvider({required bool isDemo})
    : _fakeSession = Session(
        id: 1,
        workoutId: 1,
        dateCompleted: DateTime(2026, 5, 26),
        isDemo: isDemo,
      );

  final Session _fakeSession;

  @override
  Session? get currentSession => _fakeSession;

  @override
  List<SessionExercise> get sessionExercises => [_sessionExercise];

  @override
  int? get currentExerciseIndex => 0;

  @override
  Future<void> initializeSessionExercisesForCurrentWorkout() async {}

  @override
  Future<ExerciseVariant?> getVariantDetails(int variantId) async =>
      ExerciseVariant(id: variantId, slotId: 10, name: 'Back Squat');

  @override
  Future<double?> getVariantOneRm(int variantId) async => null;

  @override
  ExerciseSlot? getSlotForExercise(int slotId) => _slot;

  @override
  Map<int, List<SessionSet>> get sessionSets => {};
}

Widget _sessionScreenHarness(SessionProvider provider) {
  return ChangeNotifierProvider<SessionProvider>.value(
    value: provider,
    child: const MaterialApp(home: SessionScreen()),
  );
}

// ─── fake provider for WorkoutOverviewScreen ──────────────────────────────────

class _FakeOverviewProvider extends SessionProvider {
  _FakeOverviewProvider({required bool incompleteIsDemo})
    : _incompleteIsDemo = incompleteIsDemo;

  final bool _incompleteIsDemo;

  @override
  Future<Map<int, int>> getLastUsedVariantIdsForSlots(
    List<int> slotIds,
  ) async => {};

  @override
  Future<bool> hasIncompleteSessionForWorkout(int workoutId) async => true;

  @override
  Future<bool> getIncompleteSessionIsDemoForWorkout(int workoutId) async =>
      _incompleteIsDemo;

  @override
  Future<void> resumeIncompleteSessionForWorkout(int workoutId) async {}
}

Widget _overviewHarness(SessionProvider provider) {
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

// ─── tests ────────────────────────────────────────────────────────────────────

void main() {
  group('SessionScreen demo banner', () {
    testWidgets('shows DEMO MODE banner when session isDemo is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sessionScreenHarness(
          _FakeSessionScreenProvider(isDemo: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEMO MODE'), findsOneWidget);
    });

    testWidgets('hides banner when session isDemo is false', (tester) async {
      await tester.pumpWidget(
        _sessionScreenHarness(
          _FakeSessionScreenProvider(isDemo: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEMO MODE'), findsNothing);
    });
  });

  group('WorkoutOverviewScreen demo banner', () {
    testWidgets('shows banner when incomplete session is a demo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _overviewHarness(_FakeOverviewProvider(incompleteIsDemo: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEMO MODE'), findsOneWidget);
    });

    testWidgets('hides banner when incomplete session is not a demo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _overviewHarness(_FakeOverviewProvider(incompleteIsDemo: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEMO MODE'), findsNothing);
    });
  });
}
