import 'package:flutter/material.dart';
import '../data/models/program.dart';
import '../data/models/session.dart';
import '../data/models/workout.dart';
import '../data/repositories/program_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/one_rm_repository.dart';
import '../utils/weight_calculator.dart';

class SessionProvider extends ChangeNotifier {
  final sessionRepo = SessionRepository();
  final programRepo = ProgramRepository();
  final oneRmRepo = OneRmRepository();

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

  Future<void> startSession(int workoutId) async {
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

      final workout = program.workouts
          .firstWhere((w) => w.id == workoutId, orElse: () => program.workouts[0]);

      final now = DateTime.now();
      final session = Session(
        workoutId: workoutId,
        dateCompleted: now,
      );

      final sessionId = await sessionRepo.createSession(session);
      final createdSession = await sessionRepo.getSessionById(sessionId);

      _currentSession = createdSession;
      _selectedWorkoutId = workoutId;
      _currentProgram = program;
      _currentWorkout = workout;
      _currentExerciseIndex = 0;
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

      final exerciseId = await sessionRepo.createSessionExercise(sessionExercise);

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

      _currentSession = null;
      _selectedWorkoutId = null;
      _sessionExercises = [];
      _sessionSets = {};
      _currentExerciseIndex = null;
      _estimatedOneRms = {};
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

  ExerciseSlot? getSlotForExercise(int slotId) {
    if (_currentWorkout == null) return null;
    try {
      return _currentWorkout!.exerciseSlots
          .firstWhere((slot) => slot.id == slotId);
    } catch (_) {
      return null;
    }
  }

  Future<void> swapVariant(int sessionExerciseId, int newVariantId) async {
    try {
      final index = _sessionExercises.indexWhere((e) => e.id == sessionExerciseId);
      if (index == -1) return;

      final updatedExercise =
          _sessionExercises[index].copyWith(chosenVariantId: newVariantId);
      await sessionRepo.updateSessionExercise(updatedExercise);

      _sessionExercises = [
        for (var i = 0; i < _sessionExercises.length; i++)
          if (i == index) updatedExercise else _sessionExercises[i]
      ];
      notifyListeners();
    } catch (e) {
      _error = 'Failed to swap variant: $e';
      notifyListeners();
    }
  }
}
