import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/session_provider.dart';
import '../data/models/program.dart';
import 'session_screen.dart';
import 'warmup_screen.dart';
import 'session_review_screen.dart';
import 'one_rm_history_list_screen.dart';
import 'settings_screen.dart';

class WorkoutSelectionScreen extends StatefulWidget {
  final bool reinitializing;
  const WorkoutSelectionScreen({super.key, this.reinitializing = false});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  late Future<Program?> _programFuture;
  int _selectedTab = 0;
  final List<bool> _tabVisited = [true, false, false];

  @override
  void initState() {
    super.initState();
    _programFuture = context.read<SessionProvider>().getProgram();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.reinitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Atlas',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildWorkoutsTab(colorScheme),
          _tabVisited[1] ? const SessionReviewScreen() : const SizedBox.shrink(),
          _tabVisited[2] ? const OneRmHistoryListScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
            _tabVisited[index] = true;
          });
        },
        backgroundColor: const Color(0xFF0D0D0D),
        selectedItemColor: const Color(0xFF00D9FF),
        unselectedItemColor: const Color(0xFF666666),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: '1RM',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab(ColorScheme colorScheme) {
    return FutureBuilder(
      future: _programFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('No program found - database may not be initialized'),
          );
        }

        final program = snapshot.data!;
        final workouts = program.workouts;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workouts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WarmupCard(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WarmupScreen(),
                      ),
                    );
                  },
                ),
              );
            }

            final workout = workouts[index - 1];
            final colors = [
              colorScheme.primary,
              colorScheme.secondary,
            ];
            final accentColor = colors[(index - 1) % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _WorkoutCard(
                name: workout.name,
                exerciseCount: workout.exerciseSlots
                    .where((s) => s.variants.isNotEmpty)
                    .length,
                accentColor: accentColor,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await context
                      .read<SessionProvider>()
                      .startSession(workout.id!);
                  if (mounted) {
                    nav.push(
                      MaterialPageRoute(
                        builder: (context) => const SessionScreen(),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

// Shared animated shell for both card types.
class _CardShell extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onPressed;
  final Widget child;

  const _CardShell({
    required this.accentColor,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<_CardShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (_hoverController.value * 0.02),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainer.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.accentColor.withValues(
                      alpha: 0.2 + (_hoverController.value * 0.3),
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(
                        alpha: _hoverController.value * 0.2,
                      ),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String name;
  final int exerciseCount;
  final Color accentColor;
  final VoidCallback onPressed;

  const _WorkoutCard({
    required this.name,
    required this.exerciseCount,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _CardShell(
      accentColor: accentColor,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$exerciseCount exercises',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.arrow_forward, color: accentColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.0,
              minHeight: 3,
              backgroundColor: colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmupCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _WarmupCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const accentColor = Colors.deepOrange;

    return _CardShell(
      accentColor: accentColor,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dynamic Warm-Up',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: accentColor,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '5–10 minutes',
                            style: TextStyle(
                              color: Colors.deepOrange[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: accentColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
