import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../providers/session_provider.dart';
import '../theme/responsive.dart';
import '../data/repositories/one_rm_repository.dart';
import '../utils/weight_calculator.dart';
import 'completion_screen.dart';
import 'widgets/pinned_action_bar.dart';
import 'widgets/rest_timer.dart';
import 'widgets/weight_stepper.dart';

class _SetContext {
  final bool isWarmup;
  final int displayNumber;
  final double suggestedWeight;
  final int targetReps;
  final int restSeconds;
  final String? restGuidanceText;
  final double? percentage;
  final int? rpeTarget;
  final double? workingSetWeight;

  const _SetContext({
    required this.isWarmup,
    required this.displayNumber,
    required this.suggestedWeight,
    required this.targetReps,
    required this.restSeconds,
    this.restGuidanceText,
    this.percentage,
    this.rpeTarget,
    this.workingSetWeight,
  });

  String get label {
    if (isWarmup &&
        percentage != null &&
        workingSetWeight != null &&
        workingSetWeight! > 0) {
      final percentStr = (percentage! * 100).toStringAsFixed(0);
      final workStr = workingSetWeight!.toStringAsFixed(0);
      return 'Warm-up $displayNumber: $percentStr% of $workStr lbs';
    }
    return isWarmup ? 'Warm-up $displayNumber' : 'Working Set $displayNumber';
  }

  String get typeLabel => isWarmup ? 'WARM-UP' : 'WORKING SET';

  String get weightLabel =>
      suggestedWeight > 0 ? suggestedWeight.toStringAsFixed(0) : '—';

  String get repsLabel => '$targetReps reps';
}

class WarmupSetConfig {
  final int reps;
  final int targetRestSeconds;
  final String rangeLabel;

  const WarmupSetConfig({
    required this.reps,
    required this.targetRestSeconds,
    required this.rangeLabel,
  });

  String get guidanceText =>
      'Recommended rest: $rangeLabel. You can skip anytime.';
}

List<WarmupSetConfig> buildWarmupSetConfigs(int workingSetRestSeconds) {
  return [
    const WarmupSetConfig(
      reps: 8,
      targetRestSeconds: 120,
      rangeLabel: '1:00-2:00',
    ),
    const WarmupSetConfig(
      reps: 4,
      targetRestSeconds: 180,
      rangeLabel: '2:00-3:00',
    ),
    WarmupSetConfig(
      reps: 2,
      targetRestSeconds: workingSetRestSeconds,
      rangeLabel: 'See Working Set',
    ),
  ];
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
  double? _estimatedOneRm;
  double? _currentOneRm;
  double? _pr;
  String _exerciseName = '';
  String _slotName = 'Variant';
  final Map<int, double> _loggedWeights = {};

  double _weight = 0.0;
  int _reps = 5;
  int _rpe = 7;
  String? _notes;

  String? _weightError;
  String? _repsError;

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
    final slot = provider.getSlotForExercise(widget.slotId);

    final variant = await provider.getVariantDetails(widget.chosenVariantId);
    final slotName = slot?.name ?? 'Variant';
    if (mounted) {
      setState(() {
        _exerciseName = variant?.name ?? 'Exercise';
        _slotName = slotName;
      });
    }

    var oneRm = await provider.getVariantOneRm(widget.chosenVariantId);
    final pr = await provider.getHighestWeightForVariant(
      widget.chosenVariantId,
    );
    final templates = await provider.getSlotSetTemplates(widget.slotId);
    final sets = <_SetContext>[];

    if ((oneRm == null || oneRm <= 0) && templates.isNotEmpty) {
      final sessionEstimate = provider.getEstimatedOneRm(
        widget.sessionExerciseId,
      );
      if (sessionEstimate != null && sessionEstimate > 0) {
        oneRm = sessionEstimate;
        _estimatedOneRm = sessionEstimate;
      } else if (mounted) {
        final estimate = await _promptFor1RmEstimate(
          variant?.name ?? 'Exercise',
        );
        if (estimate != null && estimate > 0) {
          oneRm = estimate;
          _estimatedOneRm = estimate;
          provider.storeEstimatedOneRm(widget.sessionExerciseId, estimate);
          await oneRmRepo.recordNewOneRm(
            widget.chosenVariantId,
            estimate,
            DateTime.now(),
            notes: 'Estimated during session',
          );
        }
      }
    }

    if (oneRm != null && oneRm > 0 && templates.isNotEmpty) {
      final firstTemplate = templates.first;
      final workingWeight = firstTemplate.percentage1rm != null
          ? calculatePercentageWeight(oneRm, firstTemplate.percentage1rm!)
          : estimateWorkingWeightFromRpe(oneRm, firstTemplate.rpeTarget ?? 8);
      if (slot?.isMainLift == true) {
        final warmupWeights = calculateWarmupProgression(workingWeight);
        final warmupPercentages = [0.50, 0.70, 0.90];
        final warmupConfigs = buildWarmupSetConfigs(firstTemplate.restSeconds);
        for (var i = 0; i < warmupWeights.length; i++) {
          final warmupConfig = warmupConfigs[i];
          sets.add(
            _SetContext(
              isWarmup: true,
              displayNumber: i + 1,
              suggestedWeight: warmupWeights[i],
              targetReps: warmupConfig.reps,
              restSeconds: warmupConfig.targetRestSeconds,
              restGuidanceText: warmupConfig.guidanceText,
              percentage: warmupPercentages[i],
              workingSetWeight: workingWeight,
            ),
          );
        }
      }
      for (var i = 0; i < templates.length; i++) {
        final t = templates[i];
        final weight = t.percentage1rm != null
            ? calculatePercentageWeight(oneRm, t.percentage1rm!)
            : estimateWorkingWeightFromRpe(oneRm, t.rpeTarget ?? 8);
        sets.add(
          _SetContext(
            isWarmup: false,
            displayNumber: i + 1,
            suggestedWeight: weight,
            targetReps: t.repsTargetMin ?? 5,
            restSeconds: t.restSeconds,
            percentage: t.percentage1rm,
            rpeTarget: t.rpeTarget,
          ),
        );
      }
    } else {
      for (var i = 0; i < (templates.isNotEmpty ? templates.length : 3); i++) {
        final t = templates.isNotEmpty ? templates[i] : null;
        sets.add(
          _SetContext(
            isWarmup: false,
            displayNumber: i + 1,
            suggestedWeight: 0.0,
            targetReps: t?.repsTargetMin ?? 5,
            restSeconds: t?.restSeconds ?? 90,
            rpeTarget: t?.rpeTarget,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _allSets = sets;
        _currentOneRm = oneRm;
        _pr = pr;
        _loadingContext = false;
      });
      _prefillFromContext();
    }
  }

  void _prefillFromContext() {
    if (_allSets.isEmpty || _currentSetIndex >= _allSets.length) return;
    final ctx = _allSets[_currentSetIndex];
    double suggestedWeight = ctx.suggestedWeight;
    if (!ctx.isWarmup && _currentSetIndex > 0) {
      final prevCtx = _allSets[_currentSetIndex - 1];
      if (!prevCtx.isWarmup &&
          _loggedWeights.containsKey(_currentSetIndex - 1)) {
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
        title: Text(
          'Set 1RM',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No 1RM found for $variantName. Enter your estimated max to calculate weights.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: estimateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                labelText: '1RM (lbs)',
                hintText: '225',
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
            child: const Text('Skip'),
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
                    content: Text('Enter a valid weight'),
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
    final weightErr = _weight <= 0 ? 'Enter a weight greater than 0' : null;
    final repsErr = _reps <= 0 ? 'Reps must be at least 1' : null;
    if (weightErr != null || repsErr != null) {
      setState(() {
        _weightError = weightErr;
        _repsError = repsErr;
      });
      return;
    }
    setState(() {
      _weightError = null;
      _repsError = null;
    });

    final provider = context.read<SessionProvider>();
    final oneRmRepo = OneRmRepository();
    final loggedSetIndex = _currentSetIndex;
    final dbSetNumber = loggedSetIndex + 1;

    try {
      final currentCtx = _allSets[loggedSetIndex];
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
        isWarmup: currentCtx.isWarmup,
      );

      _loggedWeights[loggedSetIndex] = _weight;

      if (_weight > 0 && (_pr == null || _weight > _pr!)) {
        if (mounted) setState(() => _pr = _weight);
      }
      if (!currentCtx.isWarmup && _weight > 0 && _rpe >= 6 && _rpe <= 10) {
        final estimatedOneRm = calculateOneRmFromLift(_weight, _rpe);
        final roundedOneRm = (estimatedOneRm / 5).floor() * 5.0;
        if (currentOneRm == null || roundedOneRm > currentOneRm) {
          await oneRmRepo.recordNewOneRm(
            widget.chosenVariantId,
            roundedOneRm,
            DateTime.now(),
            notes: 'Calculated from $_reps reps @ $_rpe RPE × $_weight lbs',
          );
          if (mounted) setState(() => _currentOneRm = roundedOneRm);
        }
      }

      if (!mounted) return;

      final isLastSet = _currentSetIndex >= _allSets.length - 1;

      if (isLastSet) {
        provider.nextExercise();
        final sessionDone =
            provider.currentExerciseIndex! >= provider.sessionExercises.length;
        if (sessionDone) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CompletionScreen()),
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

      final completedSet = _allSets[loggedSetIndex];
      final restSeconds = completedSet.restSeconds;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RestTimer(
            restSeconds: restSeconds,
            guidanceText: completedSet.restGuidanceText,
            onComplete: () {
              if (mounted) Navigator.of(context).pop();
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  void _adjustWeight(double delta) {
    final newWeight = (_weight + delta).clamp(0.0, 999.9);
    setState(() {
      _weight = newWeight;
      if (newWeight > 0) _weightError = null;
    });
    _weightController.text = newWeight.toStringAsFixed(0);
  }

  void _adjustReps(int delta) {
    final newReps = (_reps + delta).clamp(1, 50);
    setState(() {
      _reps = newReps;
      _repsError = null;
    });
    _repsController.text = newReps.toString();
  }

  Future<void> _openNotesSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.screenPadding(context).left,
            16,
            Responsive.screenPadding(context).right,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Set Notes',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close notes',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                onChanged: (v) =>
                    setState(() => _notes = v.trim().isEmpty ? null : v),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Felt strong, good depth...',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF616161)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _notes = null;
                      _notesController.clear();
                    });
                  },
                  child: Text(
                    'Clear',
                    style: GoogleFonts.outfit(color: const Color(0xFFB0B0B0)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingContext) {
      return Scaffold(
        appBar: AppBar(title: const Text('Log Sets')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final currentCtx = _currentSetIndex < _allSets.length
        ? _allSets[_currentSetIndex]
        : null;
    final accentColor = currentCtx?.isWarmup == true
        ? colorScheme.secondary
        : colorScheme.primary;
    final showOneRmChip = _currentOneRm != null && _currentOneRm! > 0;
    final showPrChip = _pr != null && _pr! > 0;
    final hasHeaderChips = showOneRmChip || showPrChip;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final logged = _currentSetIndex;
        final total = _allSets.length;
        if (logged > 0 && logged < total) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$logged of $total sets logged'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: context.isCompact ? 74 : 80,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _slotName.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF909090),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _exerciseName,
                maxLines: context.isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: Responsive.font(
                    context,
                    base: 22,
                    min: 18,
                    max: 24,
                  ),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          bottom: hasHeaderChips
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(36),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        Responsive.screenPadding(context).left,
                        0,
                        Responsive.screenPadding(context).right,
                        8,
                      ),
                      child: Row(
                        children: [
                          if (showOneRmChip)
                            _StatChip(
                              label: '1RM',
                              value: '${_currentOneRm!.toStringAsFixed(0)} lbs',
                            ),
                          if (showOneRmChip && showPrChip)
                            const SizedBox(width: 8),
                          if (showPrChip)
                            _StatChip(
                              label: 'PR',
                              value: '${_pr!.toStringAsFixed(0)} lbs',
                              color: colorScheme.secondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.screenPadding(context).left,
                    Responsive.space(context, 8, max: 12),
                    Responsive.screenPadding(context).right,
                    24,
                  ),
                  children: [
                    _SetTrack(
                      sets: _allSets,
                      currentIndex: _currentSetIndex,
                      accentColor: accentColor,
                    ),
                    SizedBox(height: Responsive.space(context, 20, max: 28)),
                    if (currentCtx != null)
                      _CurrentSetBadge(
                        ctx: currentCtx,
                        accentColor: accentColor,
                      ),
                    SizedBox(height: Responsive.space(context, 20, max: 32)),
                    WeightStepper(
                      weight: _weight,
                      controller: _weightController,
                      onChanged: (v) {
                        final parsed = double.tryParse(v) ?? 0.0;
                        setState(() {
                          _weight = parsed;
                          if (parsed > 0) _weightError = null;
                        });
                      },
                      onAdjust: _adjustWeight,
                      accentColor: accentColor,
                      errorText: _weightError,
                    ),
                    SizedBox(height: Responsive.space(context, 14, max: 20)),
                    _RepsStepper(
                      reps: _reps,
                      controller: _repsController,
                      onChanged: (v) {
                        final parsed = int.tryParse(v) ?? 0;
                        setState(() {
                          _reps = parsed;
                          if (parsed > 0) _repsError = null;
                        });
                      },
                      onAdjust: _adjustReps,
                      errorText: _repsError,
                    ),
                    if (currentCtx?.isWarmup == false) ...[
                      const SizedBox(height: 20),
                      _RpeSelector(
                        value: _rpe,
                        onChanged: (v) => setState(() => _rpe = v),
                        accentColor: accentColor,
                      ),
                    ],
                    SizedBox(height: Responsive.space(context, 14, max: 20)),
                    _NotesButton(
                      hasNotes: _notes != null && _notes!.trim().isNotEmpty,
                      onTap: _openNotesSheet,
                      accentColor: accentColor,
                    ),
                  ],
                ),
              ),
              PinnedActionBar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentCtx?.isWarmup == true)
                      Center(
                        child: TextButton(
                          onPressed: _skipToWorking,
                          child: Text(
                            'Skip Warm-ups',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    _SubmitButton(
                      label: _currentSetIndex >= _allSets.length - 1
                          ? 'Finish Exercise'
                          : 'Log Set',
                      onTap: _submitSet,
                      accentColor: accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF909090),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetTrack extends StatelessWidget {
  final List<_SetContext> sets;
  final int currentIndex;
  final Color accentColor;

  const _SetTrack({
    required this.sets,
    required this.currentIndex,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: sets.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final isDone = i < currentIndex;
        final isCurrent = i == currentIndex;

        Color color;
        double height;
        if (isDone) {
          color = accentColor.withValues(alpha: 0.5);
          height = 4;
        } else if (isCurrent) {
          color = accentColor;
          height = 6;
        } else {
          color = colorScheme.surfaceContainerHigh;
          height = 4;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.isWarmup ? 'W${s.displayNumber}' : 'S${s.displayNumber}',
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.font(
                        context,
                        base: 10,
                        min: 9,
                        max: 11,
                      ),
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrentSetBadge extends StatelessWidget {
  final _SetContext ctx;
  final Color accentColor;

  const _CurrentSetBadge({required this.ctx, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final leading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.typeLabel,
                style: GoogleFonts.outfit(
                  fontSize: Responsive.font(
                    context,
                    base: 11,
                    min: 10,
                    max: 12,
                  ),
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ctx.label,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: Responsive.font(
                    context,
                    base: 18,
                    min: 15,
                    max: 20,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          );
          final target = ctx.suggestedWeight > 0
              ? Column(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TARGET',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: const Color(0xFF909090),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ctx.suggestedWeight.toStringAsFixed(0)} lbs × ${ctx.targetReps}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: Responsive.font(
                          context,
                          base: 16,
                          min: 14,
                          max: 17,
                        ),
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink();
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                if (ctx.suggestedWeight > 0) ...[
                  const SizedBox(height: 10),
                  target,
                ],
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: leading),
              if (ctx.suggestedWeight > 0) target,
            ],
          );
        },
      ),
    );
  }
}

class _RepsStepper extends StatelessWidget {
  final int reps;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final void Function(int) onAdjust;
  final String? errorText;

  const _RepsStepper({
    required this.reps,
    required this.controller,
    required this.onChanged,
    required this.onAdjust,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPS',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF909090),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;
            final input = Center(
              child: IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: Responsive.font(
                      context,
                      base: 40,
                      min: 30,
                      max: 42,
                    ),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: '5',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: Responsive.font(
                        context,
                        base: 40,
                        min: 30,
                        max: 42,
                      ),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ),
              ),
            );
            if (compact) {
              return Column(
                children: [
                  input,
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepButton(label: '−1', onTap: () => onAdjust(-1)),
                      const SizedBox(width: 12),
                      _StepButton(label: '+1', onTap: () => onAdjust(1)),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                _StepButton(label: '−1', onTap: () => onAdjust(-1)),
                const SizedBox(width: 12),
                Expanded(child: input),
                const SizedBox(width: 12),
                _StepButton(label: '+1', onTap: () => onAdjust(1)),
              ],
            );
          },
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.redAccent),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB0B0B0),
          ),
        ),
      ),
    );
  }
}

class _RpeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final Color accentColor;

  const _RpeSelector({
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RPE',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF909090),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [6, 7, 8, 9, 10].map((rpe) {
            final isSelected = value == rpe;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => onChanged(rpe),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$rpe',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NotesButton extends StatelessWidget {
  final bool hasNotes;
  final VoidCallback onTap;
  final Color accentColor;

  const _NotesButton({
    required this.hasNotes,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = hasNotes ? Colors.white : const Color(0xFFB8B8B8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasNotes
              ? accentColor.withValues(alpha: 0.16)
              : const Color(0xFF171717),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasNotes
                ? accentColor.withValues(alpha: 0.55)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              hasNotes ? 'Notes Added' : 'Add Notes',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (hasNotes)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8F8F8F)),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  const _SubmitButton({
    required this.label,
    required this.onTap,
    required this.accentColor,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
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
                    alpha: 0.3 + _controller.value * 0.2,
                  ),
                  blurRadius: 20 + _controller.value * 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded, color: Colors.black, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
