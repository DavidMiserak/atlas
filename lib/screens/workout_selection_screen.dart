import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../data/models/program.dart';
import 'session_screen.dart';

class WorkoutSelectionScreen extends StatefulWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  late Future<Program?> _programFuture;

  @override
  void initState() {
    super.initState();
    _programFuture = context.read<SessionProvider>().getProgram();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Workout'),
      ),
      body: FutureBuilder(
        future: _programFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('No program found - database may not be initialized'),
            );
          }

          final program = snapshot.data!;
          final workouts = program.workouts;

          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await context
                        .read<SessionProvider>()
                        .startSession(workout.id!);
                    if (mounted) {
                      nav.pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SessionScreen(),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        workout.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${workout.exerciseSlots.length} exercises',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
