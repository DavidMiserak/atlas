import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'workout_selection_screen.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  String? _workoutName;
  int _exerciseCount = 0;
  int _totalSets = 0;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSession());
  }

  Future<void> _finishSession() async {
    try {
      final provider = context.read<SessionProvider>();

      // Capture stats before clearing state
      final workoutName = provider.currentWorkout?.name;
      final exerciseCount = provider.sessionExercises.length;
      final totalSets = provider.sessionSets.values
          .fold<int>(0, (sum, sets) => sum + sets.length);

      await provider.completeSession();

      if (mounted) {
        setState(() {
          _workoutName = workoutName;
          _exerciseCount = exerciseCount;
          _totalSets = totalSets;
          _done = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _workoutName = null;
          _exerciseCount = 0;
          _totalSets = 0;
          _done = true;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _done
                ? _error != null
                    ? Center(child: Text('Error: $_error'))
                    : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 88,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Session Complete',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (_workoutName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _workoutName!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 48),
                      _StatRow(
                        icon: Icons.fitness_center,
                        label: 'Exercises',
                        value: '$_exerciseCount',
                      ),
                      const SizedBox(height: 16),
                      _StatRow(
                        icon: Icons.repeat,
                        label: 'Sets Logged',
                        value: '$_totalSets',
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const WorkoutSelectionScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),

          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(width: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
