import 'package:atlas/data/models/program.dart';
import 'package:atlas/data/models/workout.dart';
import 'package:atlas/providers/session_provider.dart';
import 'package:atlas/screens/workout_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:atlas/data/database/app_database.dart';

// ─── helpers ─────────────────────────────────────────────────────────────────

SetTemplate _workingSet({int setNumber = 1}) => SetTemplate(
  id: setNumber,
  slotId: 1,
  setNumber: setNumber,
  setType: 'working',
  restSeconds: 120,
);

SetTemplate _warmupSet() => SetTemplate(
  id: 0,
  slotId: 1,
  setNumber: 0,
  setType: 'warm-up',
  restSeconds: 60,
);

ExerciseSlot _slot({int workoutId = 1, List<SetTemplate>? templates}) =>
    ExerciseSlot(
      id: 10,
      workoutId: workoutId,
      name: 'Squat',
      slotOrder: 1,
      variants: [ExerciseVariant(id: 100, slotId: 10, name: 'Back Squat')],
      setTemplates: templates ??
          [_workingSet(setNumber: 1), _workingSet(setNumber: 2), _workingSet(setNumber: 3)],
    );

Workout _workout({
  int id = 1,
  String name = 'Lower Body',
  List<SetTemplate>? templates,
}) => Workout(
  id: id,
  programId: 1,
  name: name,
  dayNumber: 1,
  orderInProgram: id,
  exerciseSlots: [_slot(workoutId: id, templates: templates)],
);

final _now = DateTime(2026, 5, 26);

Program _program(List<Workout> workouts) => Program(
  id: 1,
  name: 'My Program',
  version: '1',
  createdAt: _now,
  updatedAt: _now,
  workouts: workouts,
);

// ─── fake provider ────────────────────────────────────────────────────────────

class _FakeProvider extends SessionProvider {
  _FakeProvider({
    required Program program,
    Map<int, int> completionCounts = const {},
  })  : _program = program,
        _counts = completionCounts;

  final Program _program;
  final Map<int, int> _counts;

  @override
  Future<Program?> getProgram() async => _program;

  @override
  Future<Map<int, int>> getInProgressWorkoutCompletionCounts() async => _counts;
}

Widget _harness(SessionProvider provider) {
  return ChangeNotifierProvider<SessionProvider>.value(
    value: provider,
    child: const MaterialApp(home: WorkoutSelectionScreen()),
  );
}

// ─── tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    useInMemoryDatabaseForTesting();
  });

  setUp(() async {
    await closeDatabase();
    await getDatabase();
  });

  tearDown(() async {
    await closeDatabase();
  });

  testWidgets('shows IN PROGRESS badge when workout has in_progress session', (
    tester,
  ) async {
    final provider = _FakeProvider(
      program: _program([_workout()]),
      completionCounts: {1: 1},
    );
    await tester.pumpWidget(_harness(provider));
    await tester.pump(); // settle futures

    expect(find.text('IN PROGRESS'), findsOneWidget);
  });

  testWidgets('no IN PROGRESS badge when completionCounts is empty', (
    tester,
  ) async {
    final provider = _FakeProvider(
      program: _program([_workout()]),
      completionCounts: {},
    );
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    expect(find.text('IN PROGRESS'), findsNothing);
  });

  testWidgets('shows badge for in_progress workout but not idle workout', (
    tester,
  ) async {
    final provider = _FakeProvider(
      program: _program([_workout(id: 1, name: 'Lower Body'), _workout(id: 2, name: 'Upper Body')]),
      completionCounts: {1: 2},
    );
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    expect(find.text('IN PROGRESS'), findsOneWidget);
  });

  testWidgets('progress indicator has non-zero value for in_progress workout', (
    tester,
  ) async {
    // 1 set logged out of 3 working sets → completion = 1/3
    final provider = _FakeProvider(
      program: _program([_workout()]),
      completionCounts: {1: 1},
    );
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    final indicators = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    ).toList();
    // The workout card's indicator should reflect partial completion.
    expect(indicators.any((i) => (i.value ?? 0) > 0), isTrue);
  });

  testWidgets('progress indicator is zero when no in_progress session', (
    tester,
  ) async {
    final provider = _FakeProvider(
      program: _program([_workout()]),
      completionCounts: {},
    );
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.0);
  });

  testWidgets('completion is clamped to 1.0 when logged sets exceed total', (
    tester,
  ) async {
    // 99 sets logged but only 3 expected → should clamp to 1.0, no crash
    final provider = _FakeProvider(
      program: _program([_workout()]),
      completionCounts: {1: 99},
    );
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 1.0);
  });

  testWidgets('renders singular "exercise" for exerciseCount of 1', (
    tester,
  ) async {
    final singleSlotWorkout = Workout(
      id: 1,
      programId: 1,
      name: 'Solo Lift',
      dayNumber: 1,
      orderInProgram: 1,
      exerciseSlots: [_slot()],
    );
    final provider = _FakeProvider(program: _program([singleSlotWorkout]));
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('1 exercises'), findsNothing);
  });

  testWidgets('renders plural "exercises" for exerciseCount greater than 1', (
    tester,
  ) async {
    final multiSlotWorkout = Workout(
      id: 1,
      programId: 1,
      name: 'Big Day',
      dayNumber: 1,
      orderInProgram: 1,
      exerciseSlots: [
        _slot(),
        ExerciseSlot(
          id: 11,
          workoutId: 1,
          name: 'Bench',
          slotOrder: 2,
          variants: [ExerciseVariant(id: 101, slotId: 11, name: 'Flat Bench')],
        ),
      ],
    );
    final provider = _FakeProvider(program: _program([multiSlotWorkout]));
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    expect(find.text('2 exercises'), findsOneWidget);
  });

  testWidgets('warmup sets are excluded from total expected count', (
    tester,
  ) async {
    // Slot has 1 warmup + 3 working sets → totalExpected = 3
    // 3 logged sets → completion = 1.0
    final provider = _FakeProvider(
      program: _program([
        _workout(templates: [
          _warmupSet(),
          _workingSet(setNumber: 1),
          _workingSet(setNumber: 2),
          _workingSet(setNumber: 3),
        ]),
      ]),
      completionCounts: {1: 3},
    );
    await tester.pumpWidget(_harness(provider));
    await tester.pump();

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 1.0);
  });
}
