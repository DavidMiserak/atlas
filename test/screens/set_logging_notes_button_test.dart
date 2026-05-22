import 'package:atlas/data/models/session.dart';
import 'package:atlas/data/models/workout.dart';
import 'package:atlas/providers/session_provider.dart';
import 'package:atlas/screens/set_logging_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeSessionProvider extends SessionProvider {
  String? loggedNotes;

  @override
  Future<ExerciseVariant?> getVariantDetails(int variantId) async {
    return ExerciseVariant(id: variantId, slotId: 1, name: 'Back Squat');
  }

  @override
  ExerciseSlot? getSlotForExercise(int slotId) {
    return ExerciseSlot(
      id: slotId,
      workoutId: 1,
      name: 'Squat',
      slotOrder: 1,
      isMainLift: false,
    );
  }

  @override
  Future<double?> getVariantOneRm(int variantId) async => 225;

  @override
  Future<double?> getHighestWeightForVariant(int variantId) async => 205;

  @override
  Future<List<SetTemplate>> getSlotSetTemplates(int slotId) async {
    return [
      SetTemplate(
        id: 1,
        slotId: slotId,
        setNumber: 1,
        setType: 'working',
        repsTargetMin: 5,
        rpeTarget: 7,
        restSeconds: 90,
        percentage1rm: 0.7,
      ),
      SetTemplate(
        id: 2,
        slotId: slotId,
        setNumber: 2,
        setType: 'working',
        repsTargetMin: 5,
        rpeTarget: 7,
        restSeconds: 90,
        percentage1rm: 0.7,
      ),
    ];
  }

  @override
  Future<void> logSet(
    int sessionExerciseId,
    int setNumber,
    int reps,
    double weight,
    int rpe, {
    String? notes,
    double? oneRmAtSessionTime,
    bool isWarmup = false,
  }) async {
    loggedNotes = notes;
  }

  @override
  int? get currentExerciseIndex => 0;

  @override
  List<SessionExercise> get sessionExercises => [
    SessionExercise(
      id: 1,
      sessionId: 1,
      slotId: 1,
      chosenVariantId: 1,
    ),
  ];

  @override
  void nextExercise() {}
}

void main() {
  Widget buildHarness(SessionProvider provider) {
    return ChangeNotifierProvider<SessionProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: SetLoggingScreen(
          sessionExerciseId: 1,
          slotId: 1,
          chosenVariantId: 1,
        ),
      ),
    );
  }

  testWidgets('shows notes button and opens notes sheet', (tester) async {
    final provider = _FakeSessionProvider();

    await tester.pumpWidget(buildHarness(provider));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add Notes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Add Notes'), findsOneWidget);

    await tester.tap(find.text('Add Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Set Notes'), findsOneWidget);
    expect(find.byTooltip('Close notes'), findsOneWidget);
  });

  testWidgets('notes entered in sheet are submitted with set log', (tester) async {
    final provider = _FakeSessionProvider();

    await tester.pumpWidget(buildHarness(provider));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add Notes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add Notes'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Felt strong');
    await tester.tap(find.byTooltip('Close notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes Added'), findsOneWidget);

    await tester.tap(find.text('Log Set'));
    await tester.pumpAndSettle();

    expect(provider.loggedNotes, 'Felt strong');
  });
}
