import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/repositories/one_rm_repository.dart';
import '../data/repositories/program_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../theme/responsive.dart';
import '../utils/variant_description_display.dart';
import 'one_rm_history_detail_screen.dart';
import 'widgets/one_rm_info_sheet.dart';

typedef _VariantInfo = ({
  String name,
  String? description,
  double? weight,
  DateTime? lastUpdated,
});
typedef _SlotGroup = ({
  String slotName,
  List<({int variantId, _VariantInfo info})> variants,
});
typedef _ListData = ({List<_SlotGroup> groups, bool showOneRmHint});

class OneRmHistoryListScreen extends StatefulWidget {
  const OneRmHistoryListScreen({super.key});

  @override
  State<OneRmHistoryListScreen> createState() => _OneRmHistoryListScreenState();
}

class _OneRmHistoryListScreenState extends State<OneRmHistoryListScreen> {
  late Future<_ListData> _future;
  final TextEditingController _searchController = TextEditingController();
  final _settingsRepo = SettingsRepository();
  String _searchQuery = '';
  bool _hintSuppressed = false;

  @override
  void initState() {
    super.initState();
    _future = _loadInitial();
  }

  Future<_ListData> _loadInitial() async {
    final groups = await _loadGroups();
    final seen = await _settingsRepo.getSeenOneRmDefinition();
    return (groups: groups, showOneRmHint: !seen);
  }

  Future<void> _dismissOneRmHint() async {
    await _settingsRepo.setSeenOneRmDefinition(true);
    if (mounted) setState(() => _hintSuppressed = true);
  }

  void _openOneRmInfo() {
    _dismissOneRmHint();
    showOneRmInfoSheet(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final slotVariants = <String, Map<int, ({String name, String? description})>>{};

    for (final workout in program.workouts) {
      for (final slot in workout.exerciseSlots) {
        if (!slotVariants.containsKey(slot.name)) {
          slotVariants[slot.name] = {};
          slotOrder.add(slot.name);
        }
        for (final variant in slot.variants) {
          if (variant.id != null) {
            slotVariants[slot.name]![variant.id!] = (
              name: variant.name,
              description: variant.description,
            );
          }
        }
      }
    }

    if (slotVariants.isEmpty) return [];

    final allVariantIds = slotVariants.values.expand((m) => m.keys).toList();
    final oneRmData = await oneRmRepo.getCurrentOneRmDataForVariants(
      allVariantIds,
    );

    return [
      for (final slotName in slotOrder)
        (
          slotName: slotName,
          variants: [
            for (final e in slotVariants[slotName]!.entries)
              (
                variantId: e.key,
                info: (
                  name: e.value.name,
                  description: e.value.description,
                  weight: oneRmData[e.key]?.weight,
                  lastUpdated: oneRmData[e.key]?.date,
                ),
              ),
          ],
        ),
    ];
  }

  List<_SlotGroup> _filterGroups(List<_SlotGroup> groups) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return groups;

    final filtered = <_SlotGroup>[];
    for (final group in groups) {
      final slotMatches = group.slotName.toLowerCase().contains(query);
      final matchingVariants = slotMatches
          ? group.variants
          : group.variants
                .where((v) => v.info.name.toLowerCase().contains(query))
                .toList();

      if (matchingVariants.isNotEmpty) {
        filtered.add((slotName: group.slotName, variants: matchingVariants));
      }
    }
    return filtered;
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search exercises',
          hintStyle: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF666666),
            size: 20,
          ),
          suffixIcon: _searchQuery.trim().isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF151515),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildOneRmHintBar() {
    return GestureDetector(
      onTap: _openOneRmInfo,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Text(
          'What is 1RM? Tap ⓘ to learn.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFF555555),
          ),
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF666666)),
            tooltip: 'What is 1RM?',
            onPressed: _openOneRmInfo,
          ),
        ],
      ),
      body: FutureBuilder<_ListData>(
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

          final data = snapshot.data;
          final groups = data?.groups ?? [];
          final showOneRmHint =
              !_hintSuppressed && (data?.showOneRmHint ?? false);
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No exercises yet',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Complete a workout to start tracking your strength.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF888888),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredGroups = _filterGroups(groups);
          final hasActiveFilter = _searchQuery.trim().isNotEmpty;

          if (filteredGroups.isEmpty) {
            return Column(
              children: [
                _buildSearchField(context),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No matching exercises',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasActiveFilter
                                ? 'Try a different search term.'
                                : 'No exercises available.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF888888),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Flatten groups into a linear list of header + row widgets.
          final items = <Widget>[];
          items.add(_buildSearchField(context));
          if (showOneRmHint) {
            items.add(_buildOneRmHintBar());
          }
          for (final group in filteredGroups) {
            items.add(_SlotHeader(name: group.slotName));
            for (final v in group.variants) {
              items.add(
                _VariantRow(
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
                    setState(() {
                      _future = _loadInitial();
                    });
                  },
                ),
              );
              items.add(const Divider(color: Color(0xFF1A1A1A), height: 1));
            }
            items.add(const SizedBox(height: 8));
          }

          return ListView(
            padding: EdgeInsets.symmetric(
              vertical: Responsive.space(context, 8, max: 10),
            ),
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
    final showDesc = shouldShowVariantDescription(info.name, info.description);

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
                  if (showDesc) ...[
                    const SizedBox(height: 2),
                    Text(
                      info.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(info.lastUpdated),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF666666),
                    ),
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
                    fontSize: Responsive.font(
                      context,
                      base: 20,
                      min: 16,
                      max: 21,
                    ),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00D9FF),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF666666),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
