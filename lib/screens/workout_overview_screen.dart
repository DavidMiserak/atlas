import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/models/workout.dart';
import '../providers/session_provider.dart';
import '../theme/responsive.dart';
import 'session_screen.dart';

class WorkoutOverviewScreen extends StatefulWidget {
  final Workout workout;
  final Color accentColor;

  const WorkoutOverviewScreen({
    super.key,
    required this.workout,
    required this.accentColor,
  });

  @override
  State<WorkoutOverviewScreen> createState() => _WorkoutOverviewScreenState();
}

class _WorkoutOverviewScreenState extends State<WorkoutOverviewScreen> {
  bool _isStarting = false;
  String? _startError;

  int get _exerciseCount => widget.workout.exerciseSlots.length;

  int get _plannedSetCount => widget.workout.exerciseSlots.fold(
    0,
    (sum, slot) => sum + slot.setTemplates.length,
  );

  int get _estimatedMinutes {
    final totalRestSeconds = widget.workout.exerciseSlots.fold(
      0,
      (sum, slot) =>
          sum + slot.setTemplates.fold(0, (inner, s) => inner + s.restSeconds),
    );
    final transitionSeconds = (_exerciseCount * 90) + (_plannedSetCount * 35);
    final totalSeconds = totalRestSeconds + transitionSeconds;
    return (totalSeconds / 60).ceil().clamp(1, 180);
  }

  Future<void> _startWorkout() async {
    final workoutId = widget.workout.id;
    if (workoutId == null) {
      setState(() {
        _startError = 'Unable to start this workout right now.';
      });
      return;
    }

    setState(() {
      _isStarting = true;
      _startError = null;
    });

    await context.read<SessionProvider>().startSession(workoutId);
    if (!mounted) return;

    final provider = context.read<SessionProvider>();
    if (provider.error != null) {
      setState(() {
        _isStarting = false;
        _startError = provider.error;
      });
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SessionScreen()));
    setState(() {
      _isStarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(
          'Workout Overview',
          style: GoogleFonts.spaceGrotesk(
            fontSize: Responsive.font(context, base: 24, min: 20, max: 26),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _OverviewHero(
                    workout: widget.workout,
                    accentColor: widget.accentColor,
                    exerciseCount: _exerciseCount,
                    plannedSetCount: _plannedSetCount,
                    estimatedMinutes: _estimatedMinutes,
                  ),
                  const SizedBox(height: 18),
                  ...widget.workout.exerciseSlots.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ExerciseOverviewCard(
                        slot: entry.value,
                        index: entry.key + 1,
                        accentColor: widget.accentColor,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_startError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _startError!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isStarting ? null : _startWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: widget.accentColor.withValues(
                          alpha: 0.35,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isStarting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black.withValues(alpha: 0.75),
                              ),
                            )
                          : Text(
                              'Start Workout',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  final Workout workout;
  final Color accentColor;
  final int exerciseCount;
  final int plannedSetCount;
  final int estimatedMinutes;

  const _OverviewHero({
    required this.workout,
    required this.accentColor,
    required this.exerciseCount,
    required this.plannedSetCount,
    required this.estimatedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.18),
            const Color(0xFF161616),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRE-FLIGHT BRIEF',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            workout.name.toUpperCase(),
            style: GoogleFonts.barlowCondensed(
              fontSize: Responsive.font(context, base: 42, min: 30, max: 46),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: Colors.white,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaPill(label: 'Exercises', value: '$exerciseCount'),
              _MetaPill(label: 'Planned Sets', value: '$plannedSetCount'),
              _MetaPill(label: 'Est. Time', value: '$estimatedMinutes min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetaPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D2D2D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8F8F8F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOverviewCard extends StatelessWidget {
  final ExerciseSlot slot;
  final int index;
  final Color accentColor;

  const _ExerciseOverviewCard({
    required this.slot,
    required this.index,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final groupedSets = <String, List<SetTemplate>>{
      'warm-up': [],
      'working': [],
      'back-off': [],
      'other': [],
    };

    for (final template in slot.setTemplates) {
      final type = template.setType.toLowerCase();
      if (groupedSets.containsKey(type)) {
        groupedSets[type]!.add(template);
      } else {
        groupedSets['other']!.add(template);
      }
    }

    final variantName = slot.variants.isNotEmpty
        ? slot.variants.first.name
        : 'No variant assigned';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232323)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.jetBrainsMono(
                  color: accentColor.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: Responsive.font(
                          context,
                          base: 22,
                          min: 18,
                          max: 24,
                        ),
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      variantName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFFB9B9B9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (slot.category != null &&
                        slot.category!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        slot.category!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF7E7E7E),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (slot.setTemplates.isEmpty)
            Text(
              'No set plan defined for this exercise.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF8C8C8C),
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...groupedSets.entries
                .where((entry) => entry.value.isNotEmpty)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SetGroup(title: entry.key, templates: entry.value),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SetGroup extends StatelessWidget {
  final String title;
  final List<SetTemplate> templates;

  const _SetGroup({required this.title, required this.templates});

  String _prettyTitle(String value) {
    if (value == 'warm-up') return 'Warm-Up';
    if (value == 'back-off') return 'Back-Off';
    if (value == 'working') return 'Working';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _prettyTitle(title).toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: const Color(0xFF8A8A8A),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        ...templates.map(
          (template) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _SetRow(template: template),
          ),
        ),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  final SetTemplate template;

  const _SetRow({required this.template});

  String _formatPercentage(double value) {
    // Seed data stores percentages as 0.xx fractions.
    final percent = value <= 1 ? value * 100 : value;
    return '${percent.toStringAsFixed(0)}% 1RM';
  }

  String _repsText() {
    final min = template.repsTargetMin;
    final max = template.repsTargetMax;
    if (min != null && max != null && min != max) {
      return '$min-$max reps';
    }
    if (min != null) return '$min reps';
    if (max != null) return '$max reps';
    return 'reps open';
  }

  String _targetText() {
    final parts = <String>[_repsText()];
    if (template.percentage1rm != null) {
      parts.add(_formatPercentage(template.percentage1rm!));
    }
    if (template.rpeTarget != null) {
      parts.add('RPE ${template.rpeTarget}');
    }
    parts.add(_formatRest(template.restSeconds));
    return parts.join('  ·  ');
  }

  String _formatRest(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')} rest';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${template.setNumber}.',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: const Color(0xFFAAAAAA),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _targetText(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFFD6D6D6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
