import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/repositories/one_rm_repository.dart';
import '../data/repositories/program_repository.dart';
import 'one_rm_history_detail_screen.dart';

typedef _VariantInfo = ({String name, double? weight, DateTime? lastUpdated});

class OneRmHistoryListScreen extends StatefulWidget {
  const OneRmHistoryListScreen({super.key});

  @override
  State<OneRmHistoryListScreen> createState() => _OneRmHistoryListScreenState();
}

class _OneRmHistoryListScreenState extends State<OneRmHistoryListScreen> {
  late Future<Map<int, _VariantInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadVariants();
  }

  Future<Map<int, _VariantInfo>> _loadVariants() async {
    final programRepo = ProgramRepository();
    final oneRmRepo = OneRmRepository();

    final programs = await programRepo.getAllPrograms();
    if (programs.isEmpty) return {};
    final program = await programRepo.getProgramById(programs.first.id!);
    if (program == null) return {};

    final variantNames = <int, String>{};
    for (final workout in program.workouts) {
      for (final slot in workout.exerciseSlots) {
        for (final variant in slot.variants) {
          if (variant.id != null) {
            variantNames[variant.id!] = variant.name;
          }
        }
      }
    }
    if (variantNames.isEmpty) return {};

    final oneRmData =
        await oneRmRepo.getCurrentOneRmDataForVariants(variantNames.keys.toList());

    return {
      for (final entry in variantNames.entries)
        entry.key: (
          name: entry.value,
          weight: oneRmData[entry.key]?.weight,
          lastUpdated: oneRmData[entry.key]?.date,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '1RM HISTORY',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
            color: const Color(0xFF555555),
          ),
        ),
      ),
      body: FutureBuilder<Map<int, _VariantInfo>>(
        future: _future,
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
                'Error loading 1RM history',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
            );
          }

          final variants = snapshot.data ?? {};
          if (variants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No exercises found',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your program data may not have loaded. Try restarting the app.',
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: const Color(0xFF888888)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final keys = variants.keys.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            separatorBuilder: (_, _) =>
                const Divider(color: Color(0xFF222222), height: 1),
            itemBuilder: (context, index) {
              final variantId = keys[index];
              final info = variants[variantId]!;
              return _VariantRow(
                variantId: variantId,
                info: info,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => OneRmHistoryDetailScreen(
                        variantId: variantId,
                        variantName: info.name,
                      ),
                    ),
                  );
                  // Refresh after returning from detail (user may have updated 1RM)
                  setState(() => _future = _loadVariants());
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  final int variantId;
  final _VariantInfo info;
  final VoidCallback onTap;

  const _VariantRow({
    required this.variantId,
    required this.info,
    required this.onTap,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'No record yet';
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return DateFormat('MMM d, yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF00D9FF).withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(info.lastUpdated),
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: const Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  info.weight != null
                      ? '${info.weight!.toStringAsFixed(0)} lbs'
                      : '—',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00D9FF),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.arrow_forward,
                    size: 16, color: Color(0xFF666666)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
