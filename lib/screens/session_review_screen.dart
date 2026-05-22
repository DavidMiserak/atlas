import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/session_review.dart';
import '../providers/session_provider.dart';
import '../theme/responsive.dart';
import 'session_detail_screen.dart';

class SessionReviewScreen extends StatelessWidget {
  const SessionReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
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
      body: _SessionList(),
    );
  }
}

class _SessionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SessionProvider>(context);

    return FutureBuilder<List<SessionSummary>>(
      future: provider.getAllSessionSummaries(),
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

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
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

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            Responsive.screenPadding(context).left,
            8,
            Responsive.screenPadding(context).right,
            Responsive.space(context, 48, max: 56),
          ),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: const Color(0xFF141414),
          ),
          itemBuilder: (context, index) {
            return _SessionRow(
              session: sessions[index],
              index: index,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionDetailScreen(
                    sessionId: sessions[index].sessionId,
                    workoutName: sessions[index].workoutName,
                    dateCompleted: sessions[index].dateCompleted,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SessionRow extends StatefulWidget {
  final SessionSummary session;
  final int index;
  final VoidCallback onTap;

  const _SessionRow({
    required this.session,
    required this.index,
    required this.onTap,
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
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final day = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$day ${date.day.toString().padLeft(2, '0')} $month';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hover.forward(),
      onExit: (_) => _hover.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
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
                    child: Text(
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
                                value: _formatVolume(widget.session.totalVolume),
                                label: 'LBS',
                                accent: true,
                              ),
                          ],
                        ),
                        if (widget.session.newPrs.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (widget.session.newPrs.where((p) => !p.is1rm).isNotEmpty)
                                _PrCountPill(
                                  label: 'New PRs',
                                  count: widget.session.newPrs.where((p) => !p.is1rm).length,
                                ),
                              if (widget.session.newPrs.where((p) => !p.is1rm).isNotEmpty &&
                                  widget.session.newPrs.where((p) => p.is1rm).isNotEmpty)
                                const SizedBox(width: 6),
                              if (widget.session.newPrs.where((p) => p.is1rm).isNotEmpty)
                                _PrCountPill(
                                  label: 'New 1RMs',
                                  count: widget.session.newPrs.where((p) => p.is1rm).length,
                                ),
                            ],
                          ),
                        ],
                      ],
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

  const _MiniStat({required this.value, required this.label, this.accent = false});

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
        border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.2)),
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
