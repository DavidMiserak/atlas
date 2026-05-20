import 'package:flutter/material.dart';
import '../data/models/program.dart';
import '../data/models/session.dart';
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
  List<SessionExercise> _sessionExercises = [];
  Map<int, List<SessionSet>> _sessionSets = {};
  int? _currentExerciseIndex;
  bool _isLoading = false;
  String? _error;

  // Getters
  Session? get currentSession => _currentSession;
  int? get selectedWorkoutId => _selectedWorkoutId;
  List<SessionExercise> get sessionExercises => _sessionExercises;
  Map<int, List<SessionSet>> get sessionSets => _sessionSets;
  int? get currentExerciseIndex => _currentExerciseIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Program?> getProgram() async {
    return await programRepo.getProgramById(1);
  }

  Future<void> startSession(int workoutId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final session = Session(
        workoutId: workoutId,
        dateCompleted: now,
      );

      final sessionId = await sessionRepo.createSession(session);
      final createdSession = await sessionRepo.getSessionById(sessionId);

      _currentSession = createdSession;
      _selectedWorkoutId = workoutId;
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

      _sessionExercises = [..._sessionExercises];
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
    if (_currentExerciseIndex != null &&
        _currentExerciseIndex! < _sessionExercises.length - 1) {
      _currentExerciseIndex = _currentExerciseIndex! + 1;
      notifyListeners();
    }
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
}
