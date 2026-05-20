import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/session_provider.dart';
import '../data/repositories/one_rm_repository.dart';
import '../utils/weight_calculator.dart';
import 'completion_screen.dart';
import 'widgets/rest_timer.dart';

class _SetContext {
  final bool isWarmup;
  final int displayNumber;
  final double suggestedWeight;
  final int targetReps;
  final double? percentage;
  final int? rpeTarget;
  final double? workingSetWeight;

  const _SetContext({
    required this.isWarmup,
    required this.displayNumber,
    required this.suggestedWeight,
    required this.targetReps,
    this.percentage,
    this.rpeTarget,
    this.workingSetWeight,
  });

  String get label {
    if (isWarmup && percentage != null && workingSetWeight != null && workingSetWeight! > 0) {
      final percentStr = (percentage! * 100).toStringAsFixed(0);
      final workStr = workingSetWeight!.toStringAsFixed(0);
      return 'Warm-up Set $displayNumber: $percentStr% of $workStr lbs';
    }
    return isWarmup ? 'Warm-up Set $displayNumber' : 'Working Set $displayNumber';
  }

  String get weightLabel => suggestedWeight > 0
      ? '${suggestedWeight.toStringAsFixed(0)} lbs'
      : 'Enter weight';

  String get repsLabel => '$targetReps reps';
}

class SetLoggingScreen extends StatefulWidget {
  final int sessionExerciseId;
  final int slotId;
  final int chosenVariantId;

  const SetLoggingScreen({
    super.key,
    required this.sessionExerciseId,
    required this.slotId,
    required this.chosenVariantId,
  });

  @override
  State<SetLoggingScreen> createState() => _SetLoggingScreenState();
}

class _SetLoggingScreenState extends State<SetLoggingScreen> {
  List<_SetContext> _allSets = [];
  int _currentSetIndex = 0;
  bool _loadingContext = true;
  double? _estimatedOneRm; // Temporary 1RM estimate if variant has no history
  String _exerciseName = '';
  Map<int, double> _loggedWeights = {}; // Track actual weights entered per set index

  double _weight = 0.0;
  int _reps = 5;
  int _rpe = 7;
  String? _notes;

  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSetContext();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSetContext() async {
    final provider = context.read<SessionProvider>();
    final oneRmRepo = OneRmRepository();

    final variant = await provider.getVariantDetails(widget.chosenVariantId);
    if (mounted) {
      setState(() => _exerciseName = variant?.name ?? 'Exercise');
    }

    var oneRm = await provider.getVariantOneRm(widget.chosenVariantId);
    final templates = await provider.getSlotSetTemplates(widget.slotId);

    final sets = <_SetContext>[];

    // If no 1RM exists, check if we already estimated it in this session
    if ((oneRm == null || oneRm <= 0) && templates.isNotEmpty) {
      final sessionEstimate = provider.getEstimatedOneRm(widget.sessionExerciseId);
      if (sessionEstimate != null && sessionEstimate > 0) {
        oneRm = sessionEstimate;
        _estimatedOneRm = sessionEstimate;
      } else if (mounted) {
        // First time seeing this exercise, prompt for estimate
        final estimate = await _promptFor1RmEstimate(variant?.name ?? 'Exercise');
        if (estimate != null && estimate > 0) {
          oneRm = estimate;
          _estimatedOneRm = estimate;
          provider.storeEstimatedOneRm(widget.sessionExerciseId, estimate);
          // Save to database so it persists for future sessions
          await oneRmRepo.recordNewOneRm(
            widget.chosenVariantId,
            estimate,
            DateTime.now(),
            notes: 'Estimated during session',
          );
        }
        // If user cancels or enters invalid value, proceed with blank weights (oneRm stays null)
      }
    }

    if (oneRm != null && oneRm > 0 && templates.isNotEmpty) {
      final firstTemplate = templates.first;
      // Warm-ups are always based on the working set weight, not the 1RM.
      // For percentage-based: working weight = 1RM × percentage.
      // For RPE-based: estimate working weight from the RPE target.
      final workingWeight = firstTemplate.percentage1rm != null
          ? calculatePercentageWeight(oneRm, firstTemplate.percentage1rm!)
          : estimateWorkingWeightFromRpe(oneRm, firstTemplate.rpeTarget ?? 8);

      final warmupWeights = calculateWarmupProgression(workingWeight);
      final warmupPercentages = [0.50, 0.70, 0.90];
      for (var i = 0; i < warmupWeights.length; i++) {
        sets.add(_SetContext(
          isWarmup: true,
          displayNumber: i + 1,
          suggestedWeight: warmupWeights[i],
          targetReps: 5,
          percentage: warmupPercentages[i],
          workingSetWeight: workingWeight,
        ));
      }

      for (var i = 0; i < templates.length; i++) {
        final t = templates[i];
        // Percentage-based: exact weight. RPE-based: estimated working weight as starting point.
        final weight = t.percentage1rm != null
            ? calculatePercentageWeight(oneRm, t.percentage1rm!)
            : estimateWorkingWeightFromRpe(oneRm, t.rpeTarget ?? 8);
        sets.add(_SetContext(
          isWarmup: false,
          displayNumber: i + 1,
          suggestedWeight: weight,
          targetReps: t.repsTargetMin ?? 5,
          percentage: t.percentage1rm,
          rpeTarget: t.rpeTarget,
        ));
      }
    } else {
      // No 1RM — show blank working sets from templates
      for (var i = 0; i < (templates.isNotEmpty ? templates.length : 3); i++) {
        final t = templates.isNotEmpty ? templates[i] : null;
        sets.add(_SetContext(
          isWarmup: false,
          displayNumber: i + 1,
          suggestedWeight: 0.0,
          targetReps: t?.repsTargetMin ?? 5,
          rpeTarget: t?.rpeTarget,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _allSets = sets;
        _loadingContext = false;
      });
      _prefillFromContext();
    }
  }

  void _prefillFromContext() {
    if (_allSets.isEmpty || _currentSetIndex >= _allSets.length) return;
    final ctx = _allSets[_currentSetIndex];

    // For working sets, cascade weight from previous working set if available
    double suggestedWeight = ctx.suggestedWeight;
    if (!ctx.isWarmup && _currentSetIndex > 0) {
      final prevCtx = _allSets[_currentSetIndex - 1];
      if (!prevCtx.isWarmup && _loggedWeights.containsKey(_currentSetIndex - 1)) {
        suggestedWeight = _loggedWeights[_currentSetIndex - 1]!;
      }
    }

    setState(() {
      _weight = suggestedWeight;
      _reps = ctx.targetReps;
      _rpe = ctx.rpeTarget ?? 7;
    });
    _weightController.text = suggestedWeight > 0
        ? suggestedWeight.toStringAsFixed(0)
        : '';
    _repsController.text = ctx.targetReps.toString();
  }

  Future<double?> _promptFor1RmEstimate(String variantName) async {
    final estimateController = TextEditingController();
    final completer = Completer<double?>();

    if (!mounted) return null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Estimate 1RM'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No 1RM history for $variantName.\n\nEstimate your 1RM for this exercise to calculate warm-ups and working set weights.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: estimateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '1RM (lbs)',
                hintText: 'e.g., 225',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final estimate = double.tryParse(estimateController.text);
              if (estimate != null && estimate > 0) {
                Navigator.of(context).pop();
                setState(() => _estimatedOneRm = estimate);
                completer.complete(estimate);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid weight'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return completer.future;
  }

  Future<void> _submitSet() async {
    final provider = context.read<SessionProvider>();
    final loggedSetIndex = _currentSetIndex;
    // Use actual set number (overall sequence) for the database record
    final dbSetNumber = loggedSetIndex + 1;

    try {
      // Get current 1RM (from database or estimate)
      var currentOneRm = await provider.getVariantOneRm(widget.chosenVariantId);
      currentOneRm = currentOneRm ?? _estimatedOneRm;

      await provider.logSet(
        widget.sessionExerciseId,
        dbSetNumber,
        _reps,
        _weight,
        _rpe,
        notes: _notes,
        oneRmAtSessionTime: currentOneRm,
      );

      // Track the logged weight for cascading to next sets
      _loggedWeights[loggedSetIndex] = _weight;

      if (!mounted) return;

      final isLastSet = _currentSetIndex >= _allSets.length - 1;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLastSet
                ? 'Last set logged!'
                : '${_allSets[_currentSetIndex].label} logged',
          ),
          duration: const Duration(seconds: 1),
        ),
      );

      if (isLastSet) {
        provider.nextExercise();
        final sessionDone = provider.currentExerciseIndex! >=
            provider.sessionExercises.length;
        if (sessionDone) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CompletionScreen(),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _currentSetIndex++;
        _notes = null;
        _notesController.clear();
      });
      _prefillFromContext();

      final restSeconds = _allSets[loggedSetIndex].isWarmup ? 60 : 90;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RestTimer(
            restSeconds: restSeconds,
            onComplete: () {
              if (mounted) Navigator.of(context).pop();
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _skipToWorking() {
    final firstWorkingIndex = _allSets.indexWhere((s) => !s.isWarmup);
    if (firstWorkingIndex != -1 && firstWorkingIndex > _currentSetIndex) {
      setState(() => _currentSetIndex = firstWorkingIndex);
      _prefillFromContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingContext) {
      return Scaffold(
        appBar: AppBar(title: const Text('Log Sets')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentCtx =
        _currentSetIndex < _allSets.length ? _allSets[_currentSetIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_exerciseName),
            if (currentCtx != null)
              Text(
                currentCtx.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SetProgressRow(
                sets: _allSets,
                currentIndex: _currentSetIndex,
              ),
              const SizedBox(height: 16),
              if (currentCtx != null) _SetContextCard(ctx: currentCtx),
              const SizedBox(height: 24),
              _buildWeightField(),
              const SizedBox(height: 16),
              _buildRepsField(),
              const SizedBox(height: 16),
              if (currentCtx?.isWarmup == false) _buildRPESelector(),
              if (currentCtx?.isWarmup == false) const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: _submitSet,
                  child: Text(
                    _currentSetIndex >= _allSets.length - 1
                        ? 'Log & Finish Exercise'
                        : 'Log Set',
                  ),
                ),
              ),
              if (currentCtx?.isWarmup == true) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _skipToWorking,
                    child: const Text('Skip Warm-ups'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weight (lbs)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => setState(() => _weight = double.tryParse(v) ?? 0.0),
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRepsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reps', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _repsController,
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _reps = int.tryParse(v) ?? 5),
          decoration: InputDecoration(
            hintText: '5',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRPESelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RPE (Rate of Perceived Exertion)',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Slider(
                  value: _rpe.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) => setState(() => _rpe = v.toInt()),
                ),
                Text('RPE $_rpe / 10',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes (optional)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          onChanged: (v) => setState(() => _notes = v.isEmpty ? null : v),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Felt strong, form good...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _SetContextCard extends StatelessWidget {
  final _SetContext ctx;

  const _SetContextCard({required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = ctx.isWarmup
        ? colorScheme.surfaceContainerHighest
        : colorScheme.primaryContainer;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              ctx.isWarmup ? Icons.whatshot_outlined : Icons.fitness_center,
              size: 28,
              color: ctx.isWarmup
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctx.isWarmup ? 'Warm-up' : 'Working Set',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ctx.isWarmup
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        ctx.weightLabel,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: ctx.isWarmup
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '× ${ctx.repsLabel}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ctx.isWarmup
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ctx.percentage != null) ...[
                  Text(
                    '${(ctx.percentage! * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ctx.isWarmup
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                        ),
                  ),
                  Text(
                    ctx.isWarmup ? 'of work wt' : 'of 1RM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ctx.isWarmup
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
                if (ctx.rpeTarget != null)
                  Text(
                    'Goal: RPE ${ctx.rpeTarget}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ctx.isWarmup
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                          fontWeight: ctx.percentage == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                if (!ctx.isWarmup && ctx.percentage == null && ctx.rpeTarget != null)
                  Text(
                    'adjust by feel',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
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

class _SetProgressRow extends StatelessWidget {
  final List<_SetContext> sets;
  final int currentIndex;

  const _SetProgressRow({required this.sets, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: sets.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final isDone = i < currentIndex;
        final isCurrent = i == currentIndex;
        final colorScheme = Theme.of(context).colorScheme;

        Color bgColor;
        if (isDone) {
          bgColor = colorScheme.primary;
        } else if (isCurrent) {
          bgColor = s.isWarmup
              ? colorScheme.onSurfaceVariant
              : colorScheme.primaryContainer;
        } else {
          bgColor = colorScheme.surfaceContainerHighest;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
