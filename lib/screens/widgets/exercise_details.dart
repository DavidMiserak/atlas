import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/session_provider.dart';
import '../../data/models/session.dart';
import '../../data/models/workout.dart';
import '../../theme/responsive.dart';
import '../../utils/weight_calculator.dart';

class ExerciseDetails extends StatelessWidget {
  final SessionExercise sessionExercise;

  const ExerciseDetails({super.key, required this.sessionExercise});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(double?, List<SetTemplate>, bool)>(
      future: _loadDetails(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) return const SizedBox();

        final (oneRm, templates, isMainLift) = snapshot.data!;

        if (oneRm == null || templates.isEmpty) {
          return _NoDataCard();
        }

        final firstTemplate = templates.first;
        final firstWorkingWeight = firstTemplate.percentage1rm != null
            ? calculatePercentageWeight(oneRm, firstTemplate.percentage1rm!)
            : estimateWorkingWeightFromRpe(oneRm, firstTemplate.rpeTarget ?? 8);
        final warmupWeights = calculateWarmupProgression(firstWorkingWeight);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMainLift) ...[
              _SectionHeader(label: 'Warm-up'),
              const SizedBox(height: 12),
              _WarmupRow(weights: warmupWeights),
              const SizedBox(height: 28),
            ],
            _SectionHeader(label: 'Working Sets'),
            const SizedBox(height: 12),
            ...templates.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final isRpeBased = t.percentage1rm == null;
              final weight = isRpeBased
                  ? estimateWorkingWeightFromRpe(oneRm, t.rpeTarget ?? 8)
                  : calculatePercentageWeight(oneRm, t.percentage1rm!);
              final reps = t.repsTargetMin ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WorkingSetRow(
                  setNumber: i + 1,
                  weight: weight,
                  reps: reps,
                  rpeTarget: t.rpeTarget,
                  percentageLabel: isRpeBased
                      ? 'RPE ${t.rpeTarget ?? 8}'
                      : '${(t.percentage1rm! * 100).toStringAsFixed(0)}%',
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<(double?, List<SetTemplate>, bool)> _loadDetails(
    BuildContext context,
  ) async {
    final provider = context.read<SessionProvider>();
    final oneRm = await provider.getVariantOneRm(
      sessionExercise.chosenVariantId,
    );
    final templates = await provider.getSlotSetTemplates(
      sessionExercise.slotId,
    );
    final slot = provider.getSlotForExercise(sessionExercise.slotId);
    return (oneRm, templates, slot?.isMainLift == true);
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF909090),
        letterSpacing: 1.5,
      ),
    );
  }
}

class _NoDataCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No 1RM set — you\'ll be prompted when you start logging.',
        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF909090)),
      ),
    );
  }
}

class _WarmupRow extends StatelessWidget {
  final List<double> weights;
  const _WarmupRow({required this.weights});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentages = [50, 70, 90];
    final reps = [8, 4, 2];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weights.asMap().entries.map((entry) {
          final index = entry.key;
          final pct = percentages[entry.key];
          final w = entry.value;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text(
                    '$pct%',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF909090),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    w.toStringAsFixed(0),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: Responsive.font(
                        context,
                        base: 22,
                        min: 18,
                        max: 24,
                      ),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'lbs × ${reps[index]}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF909090),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WorkingSetRow extends StatelessWidget {
  final int setNumber;
  final double weight;
  final int reps;
  final int? rpeTarget;
  final String percentageLabel;

  const _WorkingSetRow({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.percentageLabel,
    this.rpeTarget,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHigh,
            ),
            child: Center(
              child: Text(
                '$setNumber',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF909090),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '$reps reps',
                  style: GoogleFonts.outfit(
                    fontSize: Responsive.font(
                      context,
                      base: 15,
                      min: 13,
                      max: 16,
                    ),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  percentageLabel,
                  style: GoogleFonts.outfit(
                    fontSize: Responsive.font(
                      context,
                      base: 13,
                      min: 12,
                      max: 14,
                    ),
                    color: const Color(0xFF909090),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${weight.toStringAsFixed(0)} lbs',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: Responsive.font(context, base: 18, min: 15, max: 20),
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
