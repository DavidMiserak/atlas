import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/session_provider.dart';
import 'workout_selection_screen.dart';
import 'session_detail_screen.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  String? _workoutName;
  int _exerciseCount = 0;
  int _totalSets = 0;
  double _totalVolume = 0;
  int? _completedSessionId;
  DateTime? _sessionDate;
  bool _done = false;
  String? _error;

  late AnimationController _controller;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _headlineFade;
  late Animation<double> _nameFade;
  late Animation<Offset> _nameSlide;
  late Animation<double> _ruleProgress;
  late Animation<double> _statsFade;
  late Animation<Offset> _statsSlide;
  late Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _headlineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );

    _nameFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.5)),
    );

    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.5, curve: Curves.easeOutCubic),
    ));

    _ruleProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _statsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.8)),
    );

    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    ));

    _ctaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.82, 1.0)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSession());
  }

  Future<void> _finishSession() async {
    try {
      final provider = context.read<SessionProvider>();

      final workoutName = provider.currentWorkout?.name;
      final exerciseCount = provider.sessionExercises.length;
      final totalSets = provider.sessionSets.values
          .fold<int>(0, (sum, sets) => sum + sets.length);
      final totalVolume = provider.sessionSets.values
          .expand((sets) => sets)
          .fold<double>(
            0.0,
            (sum, s) => sum + ((s.weightLifted ?? 0) * (s.repsCompleted ?? 0)),
          );

      final sessionId = provider.currentSession?.id;
      final sessionDate = provider.currentSession?.dateCompleted;
      await provider.completeSession();

      if (mounted) {
        setState(() {
          _workoutName = workoutName;
          _exerciseCount = exerciseCount;
          _totalSets = totalSets;
          _totalVolume = totalVolume;
          _completedSessionId = sessionId;
          _sessionDate = sessionDate;
          _done = true;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _done = true;
        });
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_done) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _headlineFade,
                  child: Row(
                    children: [
                      _PulsingDot(color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'WORKOUT COMPLETE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF555555),
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SlideTransition(
                  position: _headlineSlide,
                  child: FadeTransition(
                    opacity: _headlineFade,
                    child: Text(
                      'DONE.',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -3,
                        height: 0.88,
                      ),
                    ),
                  ),
                ),

                if (_workoutName != null) ...[
                  const SizedBox(height: 10),
                  SlideTransition(
                    position: _nameSlide,
                    child: FadeTransition(
                      opacity: _nameFade,
                      child: Text(
                        _workoutName!,
                        style: GoogleFonts.outfit(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                AnimatedBuilder(
                  animation: _ruleProgress,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              width: constraints.maxWidth,
                              height: 1,
                              color: const Color(0xFF1E1E1E),
                            ),
                            Container(
                              width: constraints.maxWidth * _ruleProgress.value,
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.2),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 40),

                SlideTransition(
                  position: _statsSlide,
                  child: FadeTransition(
                    opacity: _statsFade,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RawStat(
                          value: '$_totalSets',
                          label: 'SETS',
                          color: Colors.white,
                        ),
                        _VerticalRule(),
                        _RawStat(
                          value: '$_exerciseCount',
                          label: 'EXERCISES',
                          color: Colors.white,
                        ),
                        if (_totalVolume > 0) ...[
                          _VerticalRule(),
                          _RawStat(
                            value: _formatVolume(_totalVolume),
                            label: 'LBS MOVED',
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                FadeTransition(
                  opacity: _ctaFade,
                  child: Column(
                    children: [
                      if (_completedSessionId != null)
                        _SecondaryButton(
                          label: 'Review Session',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionDetailScreen(
                                  sessionId: _completedSessionId!,
                                  workoutName: _workoutName ?? '',
                                  dateCompleted: _sessionDate ?? DateTime.now(),
                                ),
                              ),
                            );
                          },
                        ),
                      if (_completedSessionId != null) const SizedBox(height: 12),
                      _NewSessionButton(
                        accentColor: colorScheme.primary,
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const WorkoutSelectionScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

class _VerticalRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64,
      color: const Color(0xFF252525),
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

class _RawStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _RawStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -2,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _NewSessionButton extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const _NewSessionButton({required this.accentColor, required this.onTap});

  @override
  State<_NewSessionButton> createState() => _NewSessionButtonState();
}

class _NewSessionButtonState extends State<_NewSessionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hover;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hover.forward(),
      onExit: (_) => _hover.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hover,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Color.lerp(
                  widget.accentColor,
                  Colors.white,
                  _hover.value * 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(
                      alpha: 0.2 + _hover.value * 0.2,
                    ),
                    blurRadius: 20 + _hover.value * 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start New Session',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D0D0D),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Transform.translate(
                    offset: Offset(_hover.value * 5, 0),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Color(0xFF0D0D0D),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hover;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hover.forward(),
      onExit: (_) => _hover.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hover,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.grey[800],
                  Colors.grey[700],
                  _hover.value,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey[600]!.withValues(
                    alpha: 0.5 + _hover.value * 0.3,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Transform.translate(
                    offset: Offset(_hover.value * 5, 0),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
