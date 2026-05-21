import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/one_rm_repository.dart';
import '../data/repositories/program_repository.dart';
import 'one_rm_history_detail_screen.dart';

class OneRmHistoryListScreen extends StatelessWidget {
  const OneRmHistoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: FutureBuilder<Map<int, double?>>(
        future: _loadVariantOneRms(),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No 1RM recorded yet',
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Complete a session to auto-track, or tap ＋ to add manually',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF888888)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const OneRmHistoryDetailScreen(variantId: null),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add 1RM'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: variants.length,
            separatorBuilder: (_, _) => const Divider(color: Color(0xFF222222), height: 1),
            itemBuilder: (context, index) {
              final variantId = variants.keys.toList()[index];
              final weight = variants[variantId];
              return _VariantRow(
                variantId: variantId,
                weight: weight,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => OneRmHistoryDetailScreen(variantId: variantId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<int, double?>> _loadVariantOneRms() async {
    final programRepo = ProgramRepository();
    final oneRmRepo = OneRmRepository();

    // Get all variants in the program
    final programs = await programRepo.getAllPrograms();
    if (programs.isEmpty) return {};

    final program = await programRepo.getProgramById(programs.first.id!);
    if (program == null) return {};

    final allVariants = <int>{};
    for (final workout in program.workouts) {
      for (final slot in workout.exerciseSlots) {
        for (final variant in slot.variants) {
          if (variant.id != null) {
            allVariants.add(variant.id!);
          }
        }
      }
    }

    return oneRmRepo.getCurrentOneRmsForVariants(allVariants.toList());
  }
}

class _VariantRow extends StatelessWidget {
  final int variantId;
  final double? weight;
  final VoidCallback onTap;

  const _VariantRow({
    required this.variantId,
    required this.weight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getVariantName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Exercise';
        return GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last updated',
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      weight != null ? '${weight!.toStringAsFixed(0)} lbs' : '—',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00D9FF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF666666)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getVariantName() async {
    final repo = ProgramRepository();
    final variant = await repo.getVariantById(variantId);
    return variant?.name ?? 'Exercise';
  }
}
