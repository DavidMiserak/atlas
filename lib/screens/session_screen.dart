import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../data/models/session.dart';
import 'set_logging_screen.dart';
import 'completion_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late SessionProvider _sessionProvider;
  late Future<void> _loadExercisesFuture;

  @override
  void initState() {
    super.initState();
    _sessionProvider = context.read<SessionProvider>();
    _loadExercisesFuture = _loadExercises();
  }

  Future<void> _loadExercises() async {
    final program = await _sessionProvider.getProgram();
    final workoutId = _sessionProvider.selectedWorkoutId;

    if (program == null || workoutId == null) return;

    final workout = program.workouts
        .firstWhere((w) => w.id == workoutId, orElse: () => program.workouts[0]);

    for (final slot in workout.exerciseSlots) {
      if (slot.variants.isNotEmpty) {
        // Add first variant by default
        await _sessionProvider.addSessionExercise(slot.id!, slot.variants[0].id!);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          final nav = Navigator.of(context);
          if (mounted) {
            nav.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Session'),
          elevation: 0,
        ),
        body: FutureBuilder(
          future: _loadExercisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return Consumer<SessionProvider>(
              builder: (context, provider, child) {
                if (provider.sessionExercises.isEmpty) {
                  return const Center(
                    child: Text('No exercises loaded'),
                  );
                }

                final exerciseIndex = provider.currentExerciseIndex ?? 0;
                if (exerciseIndex >= provider.sessionExercises.length) {
                  // Session complete
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const CompletionScreen(),
                      ),
                    );
                  });
                  return const SizedBox();
                }

                final sessionExercise = provider.sessionExercises[exerciseIndex];

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExerciseProgressIndicator(
                          current: exerciseIndex + 1,
                          total: provider.sessionExercises.length,
                        ),
                        const SizedBox(height: 24),
                        _ExerciseHeader(sessionExercise: sessionExercise),
                        const SizedBox(height: 24),
                        _WarmupSets(sessionExercise: sessionExercise),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SetLoggingScreen(
                                    sessionExerciseId: sessionExercise.id!,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Log Sets'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ExerciseProgressIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _ExerciseProgressIndicator({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercise $current of $total',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  final SessionExercise sessionExercise;

  const _ExerciseHeader({required this.sessionExercise});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercise',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

class _WarmupSets extends StatelessWidget {
  final SessionExercise sessionExercise;

  const _WarmupSets({required this.sessionExercise});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warm-up',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Warm-up sets will be shown after loading exercise details',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Working Sets',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Working sets will be shown after loading exercise details',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
