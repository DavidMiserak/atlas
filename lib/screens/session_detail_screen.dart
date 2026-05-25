import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/session.dart';
import '../data/models/session_review.dart';
import '../data/repositories/session_repository.dart';
import '../providers/session_provider.dart';
import '../theme/responsive.dart';

bool _hasNoteText(String? notes) => notes != null && notes.trim().isNotEmpty;

class SessionDetailScreen extends StatelessWidget {
  final int sessionId;
  final String workoutName;
  final DateTime dateCompleted;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.workoutName,
    required this.dateCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              sessionId: sessionId,
              workoutName: workoutName,
              dateCompleted: dateCompleted,
            ),
            Expanded(child: _ExerciseList(sessionId: sessionId)),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int sessionId;
  final String workoutName;
  final DateTime dateCompleted;

  const _Header({
    required this.sessionId,
    required this.workoutName,
    required this.dateCompleted,
  });

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final day = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$day ${date.day.toString().padLeft(2, '0')} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatDate(dateCompleted),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: const Color(0xFF00D9FF),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            workoutName.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlowCondensed(
              fontSize: Responsive.font(context, base: 42, min: 30, max: 48),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<Session?>(
            future: SessionRepository().getSessionById(sessionId),
            builder: (context, snapshot) {
              final isDemo = snapshot.data?.isDemo ?? false;
              if (!isDemo) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFC857).withValues(alpha: 0.45),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'DEMO SESSION',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFFFFC857),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFF1A1A1A)),
        ],
      ),
    );
  }
}

// ─── Exercise list ────────────────────────────────────────────────────────────

class _ExerciseList extends StatelessWidget {
  final int sessionId;

  const _ExerciseList({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SessionProvider>(context);

    return FutureBuilder<
      ({List<SessionDetailExercise> exercises, Session? session})
    >(
      future:
          Future.wait([
            provider.getSessionDetail(sessionId),
            SessionRepository().getSessionById(sessionId),
          ]).then(
            (results) => (
              exercises: results[0] as List<SessionDetailExercise>,
              session: results[1] as Session?,
            ),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFF00D9FF),
                strokeWidth: 1.5,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: GoogleFonts.outfit(
                color: const Color(0xFF444444),
                fontSize: 13,
              ),
            ),
          );
        }

        final data = snapshot.data;
        final exercises = data?.exercises ?? [];
        final sessionNotes = data?.session?.notes;

        if (exercises.isEmpty) {
          return Center(
            child: Text(
              'No data',
              style: GoogleFonts.outfit(
                color: const Color(0xFF333333),
                fontSize: 13,
              ),
            ),
          );
        }

        final horizontalPadding = Responsive.screenPadding(context).left;
        final bottomPadding = Responsive.space(context, 48, max: 56);

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            Responsive.screenPadding(context).right,
            bottomPadding,
          ),
          children: [
            if (_hasNoteText(sessionNotes))
              _SessionNoteSection(notes: sessionNotes!.trim()),
            for (var i = 0; i < exercises.length; i++) ...[
              if (i > 0 || _hasNoteText(sessionNotes))
                Container(height: 1, color: const Color(0xFF141414)),
              _ExerciseBlock(exercise: exercises[i], index: i),
            ],
          ],
        );
      },
    );
  }
}

class _SessionNoteSection extends StatelessWidget {
  final String notes;

  const _SessionNoteSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION NOTE',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: const Color(0xFF404040),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFFB8B8B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise block ───────────────────────────────────────────────────────────

class _ExerciseBlock extends StatelessWidget {
  final SessionDetailExercise exercise;
  final int index;

  const _ExerciseBlock({required this.exercise, required this.index});

  static bool _isWarmUp(String type) {
    final t = type.toLowerCase();
    return t == 'warm-up' || t == 'warmup';
  }

  @override
  Widget build(BuildContext context) {
    final warmUpSets = exercise.sets
        .where((s) => _isWarmUp(s.setType))
        .toList();
    final mainSets = exercise.sets.where((s) => !_isWarmUp(s.setType)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exercise header ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: const Color(0xFF282828),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.slotName.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: const Color(0xFF404040),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.variantName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: Responsive.font(
                          context,
                          base: 20,
                          min: 17,
                          max: 21,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── New PR / 1RM pills ──────────────────────────
          if (exercise.newPrs.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Wrap(
                spacing: 6,
                runSpacing: 5,
                children: exercise.newPrs.map((pr) => _PrPill(pr: pr)).toList(),
              ),
            ),
          ],

          // ── Warm-up summary ──────────────────────────────
          if (warmUpSets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'WARM-UP',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: const Color(0xFF282828),
                    ),
                  ),
                  Text(
                    warmUpSets
                        .map((s) {
                          if (s.actualReps != null && s.actualWeight != null) {
                            return '${s.actualWeight!.toStringAsFixed(0)}×${s.actualReps}';
                          }
                          return '—';
                        })
                        .join('   ·   '),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: const Color(0xFF2E2E2E),
                    ),
                  ),
                ],
              ),
            ),
            if (warmUpSets.any((s) => _hasNoteText(s.notes))) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: warmUpSets
                      .where((s) => _hasNoteText(s.notes))
                      .map(
                        (s) => _SetNoteLine(
                          setNumber: s.setNumber,
                          notes: s.notes!.trim(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],

          // ── Working / back-off sets ──────────────────────
          if (mainSets.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...mainSets.map((set) => _WorkingSetRow(set: set)),
          ],
        ],
      ),
    );
  }
}

// ─── Working set row ──────────────────────────────────────────────────────────

class _WorkingSetRow extends StatelessWidget {
  final SessionDetailSet set;

  const _WorkingSetRow({required this.set});

  bool _isBackOff() {
    final t = set.setType.toLowerCase();
    return t == 'back-off' || t == 'backoff';
  }

  bool? _isHit() {
    if (set.targetRepsMin == null || set.targetWeight == null) return null;
    if (set.actualReps == null || set.actualWeight == null) return null;
    return set.actualReps! >= set.targetRepsMin! &&
        set.actualWeight! >= set.targetWeight!;
  }

  Color _actualColor(bool? hit) {
    if (hit == null) return Colors.white;
    return hit ? const Color(0xFF00D9FF) : const Color(0xFFFF006E);
  }

  String _actualStr() {
    if (set.actualReps != null && set.actualWeight != null) {
      return '${set.actualWeight!.toStringAsFixed(0)} × ${set.actualReps}';
    }
    return '—';
  }

  String? _targetStr() {
    if (set.targetWeight != null && set.targetRepsMin != null) {
      return '${set.targetWeight!.toStringAsFixed(0)} × ${set.targetRepsMin}';
    } else if (set.targetRpe != null) {
      return 'RPE ${set.targetRpe}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hit = _isHit();
    final actualStr = _actualStr();
    final targetStr = _targetStr();
    // Only show target when there was a miss — context for the failure
    final showMissedTarget = hit == false && targetStr != null;

    return Opacity(
      opacity: _isBackOff() ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Set number
            SizedBox(
              width: 26,
              child: Text(
                set.setNumber.toString().padLeft(2, '0'),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: const Color(0xFF343434),
                ),
              ),
            ),

            // Actual + optional missed-target subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actualStr,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _actualColor(hit),
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  if (showMissedTarget)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'target  $targetStr',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: const Color(0xFF3A3A3A),
                        ),
                      ),
                    ),
                  if (_hasNoteText(set.notes))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        set.notes!.trim(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          height: 1.4,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // RPE — quiet, right-aligned
            if (set.actualRpe != null)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RPE',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: const Color(0xFF272727),
                      ),
                    ),
                    Text(
                      set.actualRpe.toString(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF363636),
                      ),
                    ),
                  ],
                ),
              ),

            // Hit / miss dot — binary, no text
            if (hit != null)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hit
                      ? const Color(0xFF00D9FF)
                      : const Color(0xFFFF006E),
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _SetNoteLine extends StatelessWidget {
  final int setNumber;
  final String notes;

  const _SetNoteLine({required this.setNumber, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setNumber.toString().padLeft(2, '0'),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: const Color(0xFF343434),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notes,
              style: GoogleFonts.outfit(
                fontSize: 12,
                height: 1.4,
                color: const Color(0xFF5A5A5A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PR pill ──────────────────────────────────────────────────────────────────

class _PrPill extends StatelessWidget {
  final PrRecord pr;
  const _PrPill({required this.pr});

  @override
  Widget build(BuildContext context) {
    final label = pr.is1rm ? '1RM' : 'PR';
    final prev = pr.prev.toStringAsFixed(0);
    final val = pr.value.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: const Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$prev → $val',
            maxLines: 1,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00D9FF),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
