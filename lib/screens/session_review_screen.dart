import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/session_review.dart';
import '../providers/session_provider.dart';
import '../theme/responsive.dart';
import 'session_detail_screen.dart';

class SessionReviewScreen extends StatefulWidget {
  const SessionReviewScreen({super.key});

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  String _searchQuery = '';
  bool _hasNotesOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'TRAINING LOG',
          style: GoogleFonts.outfit(
            fontSize: Responsive.font(context, base: 11, min: 10, max: 12),
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
            color: const Color(0xFF555555),
          ),
        ),
      ),
      body: Column(
        children: [
          _SearchHeader(
            controller: _searchController,
            searchQuery: _searchQuery,
            hasNotesOnly: _hasNotesOnly,
            onQueryChanged: (q) => setState(() => _searchQuery = q),
            onToggleHasNotes: () =>
                setState(() => _hasNotesOnly = !_hasNotesOnly),
          ),
          Expanded(
            child: _SessionList(
              searchQuery: _searchQuery,
              hasNotesOnly: _hasNotesOnly,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final bool hasNotesOnly;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleHasNotes;

  const _SearchHeader({
    required this.controller,
    required this.searchQuery,
    required this.hasNotesOnly,
    required this.onQueryChanged,
    required this.onToggleHasNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.screenPadding(context).left,
        0,
        Responsive.screenPadding(context).right,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF444444)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFF555555),
                          size: 18,
                        ),
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onToggleHasNotes,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasNotesOnly
                      ? const Color(0xFF00D9FF)
                      : const Color(0xFFB8B8B8).withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Has Notes',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: hasNotesOnly
                      ? const Color(0xFF00D9FF)
                      : const Color(0xFFB8B8B8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionList extends StatefulWidget {
  final String searchQuery;
  final bool hasNotesOnly;

  const _SessionList({required this.searchQuery, required this.hasNotesOnly});

  @override
  State<_SessionList> createState() => _SessionListState();
}

class _SessionListState extends State<_SessionList> {
  late Future<List<SessionSummary>> _summariesFuture;
  Set<int> _matchingIds = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _summariesFuture = Provider.of<SessionProvider>(
      context,
      listen: false,
    ).getAllSessionSummaries();
  }

  @override
  void didUpdateWidget(covariant _SessionList old) {
    super.didUpdateWidget(old);
    if (old.searchQuery != widget.searchQuery) {
      _debounce?.cancel();
      if (widget.searchQuery.isEmpty) {
        setState(() => _matchingIds = {});
      } else {
        _debounce = Timer(const Duration(milliseconds: 300), () async {
          final provider = Provider.of<SessionProvider>(context, listen: false);
          final ids = await provider.searchSessionIds(widget.searchQuery);
          if (mounted) setState(() => _matchingIds = ids);
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = Provider.of<SessionProvider>(context, listen: false);
    setState(() {
      _summariesFuture = provider.getAllSessionSummaries();
      _matchingIds = {};
    });
  }

  Future<void> _confirmDelete(SessionSummary session) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this workout entry?'),
        content: const Text(
          'This removes the selected session from your training log and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete Entry'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    final provider = Provider.of<SessionProvider>(context, listen: false);
    await provider.deleteSessionEntry(session.sessionId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workout entry removed.')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final filterActive = widget.searchQuery.isNotEmpty || widget.hasNotesOnly;

    return FutureBuilder<List<SessionSummary>>(
      future: _summariesFuture,
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
              textAlign: TextAlign.center,
            ),
          );
        }

        final allSessions = snapshot.data ?? [];

        if (allSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NO SESSIONS YET',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete a workout to see it here.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF383838),
                  ),
                ),
              ],
            ),
          );
        }

        final filtered = widget.hasNotesOnly
            ? allSessions
                  .where((s) => s.hasSessionNote || s.hasSetNote)
                  .toList()
            : allSessions;

        final displayed = widget.searchQuery.isEmpty
            ? filtered
            : filtered
                  .where((s) => _matchingIds.contains(s.sessionId))
                  .toList();

        if (displayed.isEmpty) {
          return Center(
            child: Text(
              widget.searchQuery.isNotEmpty
                  ? "No notes matching '${widget.searchQuery}'"
                  : 'No sessions with notes yet',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF383838),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF00D9FF),
          backgroundColor: const Color(0xFF1A1A1A),
          onRefresh: _refresh,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              Responsive.screenPadding(context).left,
              8,
              Responsive.screenPadding(context).right,
              Responsive.space(context, 48, max: 56) +
                  MediaQuery.of(context).viewInsets.bottom,
            ),
            itemCount: displayed.length,
            separatorBuilder: (context, index) =>
                Container(height: 1, color: const Color(0xFF141414)),
            itemBuilder: (context, index) {
              final session = displayed[index];
              return _SessionRow(
                session: session,
                index: index,
                filterActive: filterActive,
                searchQuery: widget.searchQuery,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(
                        sessionId: session.sessionId,
                        workoutName: session.workoutName,
                        dateCompleted: session.dateCompleted,
                      ),
                    ),
                  );
                },
                onDelete: () => _confirmDelete(session),
              );
            },
          ),
        );
      },
    );
  }
}

class _SessionRow extends StatefulWidget {
  final SessionSummary session;
  final int index;
  final bool filterActive;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionRow({
    required this.session,
    required this.index,
    required this.filterActive,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _hover;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

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
    return '$day ${date.day.toString().padLeft(2, '0')} $month';
  }

  List<TextSpan> _highlightSnippet(String snippet, String query) {
    final lower = snippet.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: snippet.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: snippet.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: snippet.substring(idx, idx + query.length),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF00D9FF),
          ),
        ),
      );
      start = idx + query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hover.forward(),
      onExit: (_) => _hover.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onDelete,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _hover,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    child: widget.filterActive
                        ? const SizedBox(width: 28)
                        : Text(
                            (widget.index + 1).toString().padLeft(2, '0'),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: Color.lerp(
                                const Color(0xFF2A2A2A),
                                const Color(0xFF00D9FF),
                                _hover.value,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.session.workoutName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatDate(widget.session.dateCompleted),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: const Color(0xFF00D9FF),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.searchQuery.isNotEmpty &&
                            widget.session.noteSnippet != null) ...[
                          const SizedBox(height: 5),
                          RichText(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF777777),
                              ),
                              children: _highlightSnippet(
                                widget.session.noteSnippet!,
                                widget.searchQuery,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MiniStat(
                              value: '${widget.session.totalSetsLogged}',
                              label: 'SETS',
                            ),
                            _MiniStat(
                              value: '${widget.session.exerciseCount}',
                              label: 'EXERCISES',
                            ),
                            if (widget.session.totalVolume > 0)
                              _MiniStat(
                                value: _formatVolume(
                                  widget.session.totalVolume,
                                ),
                                label: 'LBS',
                                accent: true,
                              ),
                          ],
                        ),
                        if (widget.session.isDemo ||
                            widget.session.newPrs.isNotEmpty ||
                            widget.session.hasSessionNote ||
                            widget.session.hasSetNote) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (widget.session.isDemo)
                                const _LabelPill(label: 'Demo'),
                              if (widget.session.newPrs
                                  .where((p) => !p.is1rm)
                                  .isNotEmpty)
                                _PrCountPill(
                                  label: 'New PRs',
                                  count: widget.session.newPrs
                                      .where((p) => !p.is1rm)
                                      .length,
                                ),
                              if (widget.session.newPrs
                                  .where((p) => p.is1rm)
                                  .isNotEmpty)
                                _PrCountPill(
                                  label: 'New 1RMs',
                                  count: widget.session.newPrs
                                      .where((p) => p.is1rm)
                                      .length,
                                ),
                              if (widget.session.hasSessionNote)
                                const _LabelPill(label: 'Session Note'),
                              if (widget.session.hasSetNote)
                                const _LabelPill(label: 'Set Note'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Delete entry',
                        onPressed: widget.onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFF777777),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _hover.value,
                        duration: const Duration(milliseconds: 150),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                    ],
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

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const _MiniStat({
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: accent ? const Color(0xFF00D9FF) : Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF444444),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PrCountPill extends StatelessWidget {
  final String label;
  final int count;
  const _PrCountPill({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$label: $count',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: const Color(0xFF00D9FF),
        ),
      ),
    );
  }
}

class _LabelPill extends StatelessWidget {
  final String label;
  const _LabelPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFB8B8B8).withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: const Color(0xFFB8B8B8),
        ),
      ),
    );
  }
}
