import 'package:flutter/material.dart';
import '../data/models/program.dart';
import '../data/models/session.dart';
import '../data/models/workout.dart';
import '../data/models/session_review.dart';
import '../data/repositories/program_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/one_rm_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/database/database_constants.dart';
import '../utils/weight_calculator.dart';

class SessionProvider extends ChangeNotifier {
  final sessionRepo = SessionRepository();
  final programRepo = ProgramRepository();
  final oneRmRepo = OneRmRepository();
  final settingsRepo = SettingsRepository();

  Session? _currentSession;
  int? _selectedWorkoutId;
  Program? _currentProgram;
  Workout? _currentWorkout;
  List<SessionExercise> _sessionExercises = [];
  Map<int, List<SessionSet>> _sessionSets = {};
  int? _currentExerciseIndex;
  bool _isLoading = false;
  String? _error;
  Map<int, double> _estimatedOneRms = {};
  Map<int, int> _preselectedVariantsBySlot = {};

  // Getters
  Session? get currentSession => _currentSession;
  int? get selectedWorkoutId => _selectedWorkoutId;
  Program? get currentProgram => _currentProgram;
  Workout? get currentWorkout => _currentWorkout;
  List<SessionExercise> get sessionExercises => _sessionExercises;
  Map<int, List<SessionSet>> get sessionSets => _sessionSets;
  int? get currentExerciseIndex => _currentExerciseIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<int, double> get estimatedOneRms => _estimatedOneRms;

  Future<Program?> getProgram() async {
    final programs = await programRepo.getAllPrograms();
    if (programs.isEmpty) return null;
    return await programRepo.getProgramById(programs.first.id!);
  }

  Future<void> startSession(
    int workoutId, {
    Map<int, int>? preselectedVariantsBySlot,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final programs = await programRepo.getAllPrograms();
      if (programs.isEmpty) {
        throw Exception('No programs found in database');
      }
      final program = await programRepo.getProgramById(programs.first.id!);
      if (program == null) {
        throw Exception('Program not found');
      }

      final workout = program.workouts.firstWhere(
        (w) => w.id == workoutId,
        orElse: () => program.workouts[0],
      );

      final demoModeEnabled = await settingsRepo.getDemoModeEnabled();
      final now = DateTime.now();
      final session = Session(
        workoutId: workoutId,
        dateCompleted: now,
        isDemo: demoModeEnabled,
        status: sessionStatusInProgress,
      );

      await sessionRepo.abandonIncompleteSessionsForWorkout(workoutId);
      final sessionId = await sessionRepo.createSession(session);
      final createdSession = await sessionRepo.getSessionById(sessionId);

      _currentSession = createdSession;
      _selectedWorkoutId = workoutId;
      _currentProgram = program;
      _currentWorkout = workout;
      _currentExerciseIndex = 0;
      _sessionExercises = [];
      _sessionSets = {};
      _estimatedOneRms = {};
      _preselectedVariantsBySlot = preselectedVariantsBySlot ?? {};
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start session: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSessionExercise(int slotId, int chosenVariantId) async {
    if (_currentSession == null) return;

    try {
      final sessionExercise = SessionExercise(
        sessionId: _currentSession!.id!,
        slotId: slotId,
        chosenVariantId: chosenVariantId,
      );

      final exerciseId = await sessionRepo.createSessionExercise(
        sessionExercise,
      );

      final createdExercise = sessionExercise.copyWith(id: exerciseId);
      _sessionExercises = [..._sessionExercises, createdExercise];
      _sessionSets[exerciseId] = [];
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add exercise: $e';
      notifyListeners();
    }
  }

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
    if (!isValidReps(reps) || !isValidWeight(weight) || !isValidRpe(rpe)) {
      _error = 'Invalid input values';
      notifyListeners();
      return;
    }

    try {
      final sessionSet = SessionSet(
        sessionExerciseId: sessionExerciseId,
        setNumber: setNumber,
        repsCompleted: reps,
        weightLifted: weight,
        rpeActual: rpe,
        notes: notes,
        oneRmAtSessionTime: oneRmAtSessionTime,
        timestamp: DateTime.now(),
        isWarmup: isWarmup,
      );

      await sessionRepo.logSet(sessionSet);

      final updatedSets = _sessionSets[sessionExerciseId] ?? [];
      _sessionSets[sessionExerciseId] = [...updatedSets, sessionSet];
      notifyListeners();
    } catch (e) {
      _error = 'Failed to log set: $e';
      notifyListeners();
    }
  }

  void nextExercise() {
    if (_currentExerciseIndex != null) {
      _currentExerciseIndex = _currentExerciseIndex! + 1;
      notifyListeners();
    }
  }

  void storeEstimatedOneRm(int sessionExerciseId, double estimate) {
    _estimatedOneRms[sessionExerciseId] = estimate;
  }

  double? getEstimatedOneRm(int sessionExerciseId) {
    return _estimatedOneRms[sessionExerciseId];
  }

  Future<void> completeSession() async {
    if (_currentSession == null) return;

    try {
      _isLoading = true;
      notifyListeners();
      await sessionRepo.updateSessionStatus(
        _currentSession!.id!,
        sessionStatusCompleted,
      );

      _currentSession = null;
      _selectedWorkoutId = null;
      _sessionExercises = [];
      _sessionSets = {};
      _currentExerciseIndex = null;
      _estimatedOneRms = {};
      _preselectedVariantsBySlot = {};
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to complete session: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<ExerciseVariant?> getVariantDetails(int variantId) async {
    return await programRepo.getVariantById(variantId);
  }

  Future<double?> getVariantOneRm(int variantId) async {
    return await oneRmRepo.getCurrentOneRm(variantId);
  }

  Future<List<SetTemplate>> getSlotSetTemplates(int slotId) async {
    return await programRepo.getSetTemplatesForSlot(slotId);
  }

  Future<double?> getHighestWeightForVariant(int variantId) async {
    return await sessionRepo.getHighestWeightForVariant(variantId);
  }

  Future<Map<int, int>> getLastUsedVariantIdsForSlots(List<int> slotIds) async {
    return await sessionRepo.getLastUsedVariantIdsForSlots(slotIds);
  }

  Future<void> initializeSessionExercisesForCurrentWorkout() async {
    final workout = _currentWorkout;
    if (_currentSession == null || workout == null) return;
    if (_sessionExercises.isNotEmpty) return;

    for (final slot in workout.exerciseSlots) {
      if (slot.id == null || slot.variants.isEmpty) continue;

      final selectedVariant = _preselectedVariantsBySlot[slot.id!];
      if (selectedVariant != null &&
          slot.variants.any((variant) => variant.id == selectedVariant)) {
        await addSessionExercise(slot.id!, selectedVariant);
        continue;
      }

      final lastUsedId = await sessionRepo.getLastUsedVariantId(slot.id!);
      final fallbackVariantId = slot.variants.first.id;
      if (fallbackVariantId == null) continue;

      final variantId = slot.variants.any((v) => v.id == lastUsedId)
          ? lastUsedId!
          : fallbackVariantId;
      await addSessionExercise(slot.id!, variantId);
    }
  }

  ExerciseSlot? getSlotForExercise(int slotId) {
    if (_currentWorkout == null) return null;
    try {
      return _currentWorkout!.exerciseSlots.firstWhere(
        (slot) => slot.id == slotId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> swapVariant(int sessionExerciseId, int newVariantId) async {
    try {
      final index = _sessionExercises.indexWhere(
        (e) => e.id == sessionExerciseId,
      );
      if (index == -1) return;

      final updatedExercise = _sessionExercises[index].copyWith(
        chosenVariantId: newVariantId,
      );
      await sessionRepo.updateSessionExercise(updatedExercise);

      _sessionExercises = [
        for (var i = 0; i < _sessionExercises.length; i++)
          if (i == index) updatedExercise else _sessionExercises[i],
      ];
      notifyListeners();
    } catch (e) {
      _error = 'Failed to swap variant: $e';
      notifyListeners();
    }
  }

  Future<List<SessionSummary>> getAllSessionSummaries() async {
    return await sessionRepo.getAllSessionSummaries();
  }

  Future<Set<int>> searchSessionIds(String query) =>
      sessionRepo.searchSessionIds(query);

  Future<List<SessionDetailExercise>> getSessionDetail(int sessionId) async {
    return await sessionRepo.getSessionDetail(sessionId);
  }

  Future<bool> hasIncompleteSessionForWorkout(int workoutId) async {
    final activeSessionId = await sessionRepo
        .getLatestIncompleteSessionIdForWorkout(workoutId);
    return activeSessionId != null;
  }

  Future<void> resumeIncompleteSessionForWorkout(int workoutId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final activeSessionId = await sessionRepo
          .getLatestIncompleteSessionIdForWorkout(workoutId);
      if (activeSessionId == null) {
        throw Exception('No incomplete session found for this workout.');
      }

      final activeSession = await sessionRepo.getSessionById(activeSessionId);
      if (activeSession == null) {
        throw Exception('Incomplete session no longer exists.');
      }

      final programs = await programRepo.getAllPrograms();
      if (programs.isEmpty) {
        throw Exception('No programs found in database');
      }
      final program = await programRepo.getProgramById(programs.first.id!);
      if (program == null) {
        throw Exception('Program not found');
      }

      final workout = program.workouts.firstWhere(
        (w) => w.id == workoutId,
        orElse: () => program.workouts[0],
      );

      final exercises = await sessionRepo.getSessionExercises(activeSessionId);
      final exerciseIds = exercises
          .map((exercise) => exercise.id)
          .whereType<int>()
          .toList();
      final setsByExercise = await sessionRepo.getSessionSetsForExercises(
        exerciseIds,
      );

      var nextExerciseIndex = 0;
      if (exercises.isNotEmpty) {
        final firstWithoutSets = exercises.indexWhere((exercise) {
          final exerciseId = exercise.id;
          if (exerciseId == null) return true;
          return (setsByExercise[exerciseId] ?? const []).isEmpty;
        });
        nextExerciseIndex = firstWithoutSets >= 0
            ? firstWithoutSets
            : exercises.length - 1;
      }

      _currentSession = activeSession;
      _selectedWorkoutId = workoutId;
      _currentProgram = program;
      _currentWorkout = workout;
      _sessionExercises = exercises;
      _sessionSets = setsByExercise;
      _currentExerciseIndex = nextExerciseIndex;
      _estimatedOneRms = {};
      _preselectedVariantsBySlot = {};
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to resume session: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSessionEntry(int sessionId) async {
    await sessionRepo.deleteSession(sessionId);
  }
}
