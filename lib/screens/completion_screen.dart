import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/session_provider.dart';
import 'widgets/metric_display.dart';
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
                          _AnimatedCheckmark(color: colorScheme.primary),
                          const SizedBox(height: 32),
                          Text(
                            'Session\nComplete',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_workoutName != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _workoutName!,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 56),
                          Row(
                            children: [
                              Expanded(
                                child: MetricDisplay(
                                  value: '$_exerciseCount',
                                  label: 'Exercises',
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: MetricDisplay(
                                  value: '$_totalSets',
                                  label: 'Sets',
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                minimumSize: const Size(double.infinity, 60),
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
                              child: Text(
                                'Start New Session',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
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

class _AnimatedCheckmark extends StatefulWidget {
  final Color color;

  const _AnimatedCheckmark({required this.color});

  @override
  State<_AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<_AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.15),
            border: Border.all(
              color: widget.color,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 56,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
