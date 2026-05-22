import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/repositories/one_rm_repository.dart';
import '../data/repositories/program_repository.dart';
import '../theme/responsive.dart';
import 'one_rm_history_detail_screen.dart';

typedef _VariantInfo = ({String name, double? weight, DateTime? lastUpdated});
typedef _SlotGroup = ({
  String slotName,
  List<({int variantId, _VariantInfo info})> variants,
});

class OneRmHistoryListScreen extends StatefulWidget {
  const OneRmHistoryListScreen({super.key});

  @override
  State<OneRmHistoryListScreen> createState() => _OneRmHistoryListScreenState();
}

class _OneRmHistoryListScreenState extends State<OneRmHistoryListScreen> {
  late Future<List<_SlotGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadGroups();
  }

  Future<List<_SlotGroup>> _loadGroups() async {
    final programRepo = ProgramRepository();
    final oneRmRepo = OneRmRepository();

    final programs = await programRepo.getAllPrograms();
    if (programs.isEmpty) return [];
    final program = await programRepo.getProgramById(programs.first.id!);
    if (program == null) return [];

    // Deduplicate slots by name; collect unique variant IDs per slot name.
    final slotOrder = <String>[];
    final slotVariants = <String, Map<int, String>>{};

    for (final workout in program.workouts) {
      for (final slot in workout.exerciseSlots) {
        if (!slotVariants.containsKey(slot.name)) {
          slotVariants[slot.name] = {};
          slotOrder.add(slot.name);
        }
        for (final variant in slot.variants) {
          if (variant.id != null) {
            slotVariants[slot.name]![variant.id!] = variant.name;
          }
        }
      }
    }

    if (slotVariants.isEmpty) return [];

    final allVariantIds =
        slotVariants.values.expand((m) => m.keys).toList();
    final oneRmData =
        await oneRmRepo.getCurrentOneRmDataForVariants(allVariantIds);

    return [
      for (final slotName in slotOrder)
        (
          slotName: slotName,
          variants: [
            for (final e in slotVariants[slotName]!.entries)
              (
                variantId: e.key,
                info: (
                  name: e.value,
                  weight: oneRmData[e.key]?.weight,
                  lastUpdated: oneRmData[e.key]?.date,
                ),
              ),
          ],
        ),
    ];
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
            fontSize: Responsive.font(context, base: 11, min: 10, max: 12),
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
            color: const Color(0xFF555555),
          ),
        ),
      ),
      body: FutureBuilder<List<_SlotGroup>>(
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

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
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

          // Flatten groups into a linear list of header + row widgets.
          final items = <Widget>[];
          for (final group in groups) {
            items.add(_SlotHeader(name: group.slotName));
            for (final v in group.variants) {
              items.add(_VariantRow(
                variantId: v.variantId,
                info: v.info,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => OneRmHistoryDetailScreen(
                        variantId: v.variantId,
                        variantName: v.info.name,
                      ),
                    ),
                  );
                  final next = _loadGroups();
                  setState(() => _future = next);
                },
              ));
              items.add(const Divider(color: Color(0xFF1A1A1A), height: 1));
            }
            items.add(const SizedBox(height: 8));
          }

          return ListView(
            padding: EdgeInsets.symmetric(vertical: Responsive.space(context, 8, max: 10)),
            children: items,
          );
        },
      ),
    );
  }
}

class _SlotHeader extends StatelessWidget {
  final String name;
  const _SlotHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        name.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.5,
          color: const Color(0xFF555555),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: Responsive.font(context, base: 20, min: 16, max: 21),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00D9FF),
                  ),
                ),
                const SizedBox(height: 4),
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
