import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return FutureBuilder<(ExerciseVariant?, double?, List<SetTemplate>)>(
      future: _loadDetails(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load exercise details',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        final (variant, oneRm, templates) = snapshot.data!;

        if (variant == null || oneRm == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No 1RM Set',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set a 1RM for ${variant?.name ?? "this exercise"} to calculate warm-ups',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        // Warm-ups are always based on the working set weight.
        // For RPE-only exercises, estimate working weight from the RPE target.
        final firstTemplate = templates.isNotEmpty ? templates.first : null;
        final firstWorkingWeight = firstTemplate?.percentage1rm != null
            ? calculatePercentageWeight(oneRm, firstTemplate!.percentage1rm!)
            : estimateWorkingWeightFromRpe(oneRm, firstTemplate?.rpeTarget ?? 8);
        final warmupWeights = calculateWarmupProgression(firstWorkingWeight);
        final workingSets = templates;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VariantCard(variant: variant, oneRm: oneRm),
            const SizedBox(height: 24),
            _WarmupSetsCard(weights: warmupWeights),
            if (workingSets.isNotEmpty) ...[
              const SizedBox(height: 24),
              _WorkingSetsCard(
                sets: workingSets,
                oneRm: oneRm,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<(ExerciseVariant?, double?, List<SetTemplate>)> _loadDetails(
    BuildContext context,
  ) async {
    final provider = context.read<SessionProvider>();

    final variant = await provider.getVariantDetails(sessionExercise.chosenVariantId);
    final oneRm = await provider.getVariantOneRm(sessionExercise.chosenVariantId);
    final templates = await provider.getSlotSetTemplates(sessionExercise.slotId);

    return (variant, oneRm, templates);
  }
}

class _VariantCard extends StatelessWidget {
  final ExerciseVariant variant;
  final double oneRm;

  const _VariantCard({
    required this.variant,
    required this.oneRm,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              variant.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current 1RM',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${oneRm.toStringAsFixed(0)} lbs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                if (variant.description != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        variant.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarmupSetsCard extends StatelessWidget {
  final List<double> weights;

  const _WarmupSetsCard({required this.weights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warm-up Sets',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...weights.asMap().entries.map((entry) {
                  final index = entry.key;
                  final weight = entry.value;
                  final percentage = [50, 70, 90][index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$percentage% × 5 reps',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${weight.toStringAsFixed(0)} lbs',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkingSetsCard extends StatelessWidget {
  final List<SetTemplate> sets;
  final double oneRm;

  const _WorkingSetsCard({
    required this.sets,
    required this.oneRm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Sets',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...sets.map((template) {
          final isRpeBased = template.percentage1rm == null;
          final weight = isRpeBased
              ? estimateWorkingWeightFromRpe(oneRm, template.rpeTarget ?? 8)
              : calculatePercentageWeight(oneRm, template.percentage1rm!);
          final reps = template.repsTargetMin ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set ${template.setNumber}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${weight.toStringAsFixed(0)} lbs',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isRpeBased
                              ? '$reps reps — adjust by feel'
                              : '$reps reps @ ${(template.percentage1rm! * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (template.rpeTarget != null)
                          Text(
                            'Goal: RPE ${template.rpeTarget}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
