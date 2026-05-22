import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/session_provider.dart';
import '../theme/responsive.dart';
import 'set_logging_screen.dart';
import 'widgets/exercise_details.dart';
import 'widgets/pinned_action_bar.dart';
import 'widgets/variant_selector.dart';

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
    await _sessionProvider.initializeSessionExercisesForCurrentWorkout();
  }

  Future<bool> _onWillPop() async {
    final hasSets = _sessionProvider.sessionSets.values.any(
      (sets) => sets.isNotEmpty,
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Back?'),
        content: Text(
          hasSets
              ? 'Any logged sets will be saved, but you\'ll need to restart to continue this session.'
              : 'Select a different workout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Go Back'),
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
        final nav = Navigator.of(context);
        if (await _onWillPop()) {
          if (mounted) {
            nav.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Session',
            style: GoogleFonts.spaceGrotesk(
              fontSize: Responsive.font(context, base: 28, min: 22, max: 30),
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: FutureBuilder(
            future: _loadExercisesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return Consumer<SessionProvider>(
                builder: (context, provider, child) {
                  if (provider.sessionExercises.isEmpty) {
                    return const Center(child: Text('No exercises loaded'));
                  }

                  final exerciseIndex = provider.currentExerciseIndex ?? 0;
                  if (exerciseIndex >= provider.sessionExercises.length) {
                    return const SizedBox();
                  }

                  final sessionExercise =
                      provider.sessionExercises[exerciseIndex];
                  final colorScheme = Theme.of(context).colorScheme;
                  final colors = [colorScheme.primary, colorScheme.secondary];
                  final accentColor = colors[exerciseIndex % colors.length];

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            _PremiumProgressBar(
                              current: exerciseIndex + 1,
                              total: provider.sessionExercises.length,
                              accentColor: accentColor,
                            ),
                            SizedBox(
                              height: Responsive.space(context, 28, max: 40),
                            ),
                            _ExerciseHero(
                              sessionExercise: sessionExercise,
                              accentColor: accentColor,
                            ),
                            SizedBox(
                              height: Responsive.space(context, 16, max: 24),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: VariantSelector(
                                    sessionExercise: sessionExercise,
                                    onVariantSwapped: () {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Responsive.space(context, 20, max: 32),
                            ),
                            ExerciseDetails(
                              sessionExercise: sessionExercise,
                            ),
                          ],
                        ),
                      ),
                      PinnedActionBar(
                        child: _LogSetsCTA(
                          sessionExerciseId: sessionExercise.id!,
                          slotId: sessionExercise.slotId,
                          chosenVariantId: sessionExercise.chosenVariantId,
                          accentColor: accentColor,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PremiumProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color accentColor;

  const _PremiumProgressBar({
    required this.current,
    required this.total,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Workout Progress',
              style: GoogleFonts.outfit(
                fontSize: Responsive.font(context, base: 12, min: 10, max: 13),
                fontWeight: FontWeight.w500,
                color: Color(0xFF909090),
                letterSpacing: 1,
              ),
            ),
            Text(
              '$current of $total',
              style: GoogleFonts.spaceGrotesk(
                fontSize: Responsive.font(context, base: 12, min: 10, max: 13),
                fontWeight: FontWeight.w600,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0, 1),
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseHero extends StatelessWidget {
  final dynamic sessionExercise;
  final Color accentColor;

  const _ExerciseHero({
    required this.sessionExercise,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SessionProvider>();
    return FutureBuilder(
      future: Future.wait([
        provider.getVariantDetails(sessionExercise.chosenVariantId),
        provider.getVariantOneRm(sessionExercise.chosenVariantId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final variant = snapshot.data![0];
        final oneRm = snapshot.data![1] as double?;
        if (variant == null) return const SizedBox();
        final slotName =
            provider.getSlotForExercise(sessionExercise.slotId)?.name ??
            'Variant';

        final compact = context.isCompact;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.07),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                _HeroPrimary(
                  slotName: slotName,
                  variantName: (variant as dynamic).name as String,
                  accentColor: accentColor,
                ),
                if (oneRm != null) ...[
                  const SizedBox(height: 14),
                  _HeroOneRm(oneRm: oneRm, accentColor: accentColor),
                ],
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _HeroPrimary(
                        slotName: slotName,
                        variantName: (variant as dynamic).name as String,
                        accentColor: accentColor,
                      ),
                    ),
                    if (oneRm != null) ...[
                      const SizedBox(width: 16),
                      _HeroOneRm(oneRm: oneRm, accentColor: accentColor),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPrimary extends StatelessWidget {
  final String slotName;
  final String variantName;
  final Color accentColor;

  const _HeroPrimary({
    required this.slotName,
    required this.variantName,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOW',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: accentColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          slotName.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8B8B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          variantName,
          maxLines: context.isCompact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: Responsive.font(context, base: 30, min: 22, max: 34),
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _HeroOneRm extends StatelessWidget {
  final double oneRm;
  final Color accentColor;

  const _HeroOneRm({required this.oneRm, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: context.isCompact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          '1RM',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF909090),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${oneRm.toStringAsFixed(0)} lbs',
          style: GoogleFonts.spaceGrotesk(
            fontSize: Responsive.font(context, base: 24, min: 18, max: 28),
            fontWeight: FontWeight.w700,
            color: accentColor,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _LogSetsCTA extends StatefulWidget {
  final int sessionExerciseId;
  final int slotId;
  final int chosenVariantId;
  final Color accentColor;

  const _LogSetsCTA({
    required this.sessionExerciseId,
    required this.slotId,
    required this.chosenVariantId,
    required this.accentColor,
  });

  @override
  State<_LogSetsCTA> createState() => _LogSetsCTAState();
}

class _LogSetsCTAState extends State<_LogSetsCTA>
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
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + (_hoverController.value * 0.03),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SetLoggingScreen(
                      sessionExerciseId: widget.sessionExerciseId,
                      slotId: widget.slotId,
                      chosenVariantId: widget.chosenVariantId,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor,
                      widget.accentColor.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(
                        alpha: 0.3 + (_hoverController.value * 0.2),
                      ),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Log Sets',
                      style: GoogleFonts.outfit(
                        fontSize: Responsive.font(
                          context,
                          base: 18,
                          min: 16,
                          max: 19,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
