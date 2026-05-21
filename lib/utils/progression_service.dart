import '../data/models/workout.dart';
import '../data/repositories/one_rm_repository.dart';
import '../data/repositories/program_repository.dart';
import '../data/repositories/session_repository.dart';
import 'weight_calculator.dart';

const _squatDeadliftSlots = {'Squat Variant', 'Deadlift Variant'};

class ProgressionResult {
  final String slotName;
  final String variantName;
  final double previousWeight;
  final double newSuggestedWeight;
  final double incrementLbs;

  const ProgressionResult({
    required this.slotName,
    required this.variantName,
    required this.previousWeight,
    required this.newSuggestedWeight,
    required this.incrementLbs,
  });
}

class ProgressionService {
  // Called from CompletionScreen after session is finalized.
  // Returns one ProgressionResult per exercise that earned progression.
  // TODO: add a last_progression_date throttle (7-day cooldown per variant)
  //       here if double-bumping on back-to-back sessions becomes a problem.
  Future<List<ProgressionResult>> evaluateAndApplyProgression(
    int sessionId,
    SessionRepository sessionRepo,
    OneRmRepository oneRmRepo,
    ProgramRepository programRepo,
  ) async {
    final session = await sessionRepo.getSessionById(sessionId);
    if (session == null) return [];
    if (session.isDeload) return [];

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final exercises = await sessionRepo.getSessionExercises(sessionId);
    if (exercises.isEmpty) return [];

    // Batch-fetch all data needed for the loop — 4 queries regardless of N exercises.
    final seIds = exercises.map((e) => e.id).whereType<int>().toSet().toList();
    final slotIds = exercises.map((e) => e.slotId).toSet().toList();
    final variantIds = exercises.map((e) => e.chosenVariantId).toSet().toList();

    final setsMap = await sessionRepo.getSessionSetsForExercises(seIds);
    final slotsMap = await programRepo.getSlotsByIds(slotIds);
    final variantsMap = await programRepo.getVariantsByIds(variantIds);
    final templatesMap = await programRepo.getSetTemplatesForSlots(slotIds);

    final results = <ProgressionResult>[];

    for (final se in exercises) {
      final seId = se.id;
      if (seId == null) continue;

      final slot = slotsMap[se.slotId];
      if (slot == null) continue;

      final variant = variantsMap[se.chosenVariantId];
      if (variant == null) continue;

      final allTemplates = templatesMap[se.slotId] ?? [];
      final workingTemplates =
          allTemplates.where((t) => t.setType == 'working').toList();
      if (workingTemplates.isEmpty) continue;
      final firstTemplate = workingTemplates.first;

      // Can't evaluate progression without a defined minimum rep target.
      if (firstTemplate.repsTargetMin == null) continue;

      // SQL orders by set_number ASC already; filter warmups client-side.
      final allSets = setsMap[seId] ?? [];
      final workingSets = allSets.where((s) => !s.isWarmup).toList();
      if (workingSets.isEmpty) continue;

      // All working sets must hit the target. null repsCompleted = 0 (incomplete).
      final allCompleted = workingSets.every(
        (s) => (s.repsCompleted ?? 0) >= firstTemplate.repsTargetMin!,
      );
      if (!allCompleted) continue;

      final lastWeight = workingSets.last.weightLifted;
      if (lastWeight == null || lastWeight <= 0) continue;

      final increment = _determineIncrement(slot.name, firstTemplate);

      final percentage =
          firstTemplate.percentage1rm ?? rpeToPercent[firstTemplate.rpeTarget];
      if (percentage == null || percentage <= 0) continue;

      final newOneRm = (lastWeight + increment) / percentage;

      // 7-day cooldown: skip progression if we've bumped this variant recently.
      final history = await oneRmRepo.getOneRmHistory(se.chosenVariantId);
      if (history.isNotEmpty && history.first.date.isAfter(sevenDaysAgo)) {
        continue;
      }

      await oneRmRepo.recordNewOneRm(
        se.chosenVariantId,
        newOneRm,
        DateTime.now(),
        notes: 'Auto-progression',
      );

      results.add(ProgressionResult(
        slotName: slot.name,
        variantName: variant.name,
        previousWeight: lastWeight,
        newSuggestedWeight: lastWeight + increment,
        incrementLbs: increment,
      ));
    }

    return results;
  }

  double _determineIncrement(String slotName, SetTemplate firstTemplate) {
    if (firstTemplate.percentage1rm != null &&
        _squatDeadliftSlots.contains(slotName)) {
      return 10.0;
    }
    return 5.0;
  }
}
