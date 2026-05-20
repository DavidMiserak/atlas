import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Atlas',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        elevation: 0,
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
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final colors = [
                colorScheme.primary,
                colorScheme.secondary,
              ];
              final accentColor = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WorkoutCard(
                  name: workout.name,
                  exerciseCount: workout.exerciseSlots
                      .where((s) => s.variants.isNotEmpty)
                      .length,
                  accentColor: accentColor,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await context
                        .read<SessionProvider>()
                        .startSession(workout.id!);
                    if (mounted) {
                      nav.push(
                        MaterialPageRoute(
                          builder: (context) => const SessionScreen(),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  final String name;
  final int exerciseCount;
  final Color accentColor;
  final VoidCallback onPressed;

  const _WorkoutCard({
    required this.name,
    required this.exerciseCount,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (_hoverController.value * 0.02),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainer.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.accentColor.withValues(
                      alpha: 0.2 + (_hoverController.value * 0.3),
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(
                        alpha: _hoverController.value * 0.2,
                      ),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.exerciseCount} exercises',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.accentColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: widget.accentColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.0,
                        minHeight: 3,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
