import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/session_provider.dart';
import '../../data/models/session.dart';
import '../../data/models/workout.dart';
import '../../utils/weight_calculator.dart';

class ExerciseDetails extends StatelessWidget {
  final SessionExercise sessionExercise;

  const ExerciseDetails({
    super.key,
    required this.sessionExercise,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(double?, List<SetTemplate>)>(
      future: _loadDetails(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) return const SizedBox();

        final (oneRm, templates) = snapshot.data!;

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
            _SectionHeader(label: 'Warm-up'),
            const SizedBox(height: 12),
            _WarmupRow(weights: warmupWeights),
            const SizedBox(height: 28),
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

  Future<(double?, List<SetTemplate>)> _loadDetails(BuildContext context) async {
    final provider = context.read<SessionProvider>();
    final oneRm = await provider.getVariantOneRm(sessionExercise.chosenVariantId);
    final templates = await provider.getSlotSetTemplates(sessionExercise.slotId);
    return (oneRm, templates);
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
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: const Color(0xFF909090),
        ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weights.asMap().entries.map((entry) {
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
                    '${w.toStringAsFixed(0)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'lbs × 5',
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
            child: Row(
              children: [
                Text(
                  '$reps reps',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  percentageLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF909090),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${weight.toStringAsFixed(0)} lbs',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
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
