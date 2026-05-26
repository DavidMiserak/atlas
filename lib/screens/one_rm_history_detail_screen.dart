import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/reference/exercise_reference_urls.dart';
import '../data/repositories/one_rm_repository.dart';
import '../data/repositories/program_repository.dart';
import '../theme/responsive.dart';
import '../utils/variant_description_display.dart';
import 'widgets/one_rm_info_sheet.dart';
import 'widgets/weight_stepper.dart';

typedef _DetailData = ({List<OneRmHistory> history, String? description});

class OneRmHistoryDetailScreen extends StatefulWidget {
  final int? variantId;
  final String? variantName;

  const OneRmHistoryDetailScreen({
    super.key,
    required this.variantId,
    this.variantName,
  });

  @override
  State<OneRmHistoryDetailScreen> createState() => _OneRmHistoryDetailScreenState();
}

class _OneRmHistoryDetailScreenState extends State<OneRmHistoryDetailScreen> {
  late Future<_DetailData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_DetailData> _loadData() async {
    if (widget.variantId == null) {
      return (history: <OneRmHistory>[], description: null);
    }
    final historyFuture = OneRmRepository()
        .getOneRmHistory(widget.variantId!)
        .catchError((_) => <OneRmHistory>[]);
    final descriptionFuture = ProgramRepository()
        .getVariantById(widget.variantId!)
        .then((v) => v?.description)
        .catchError((_) => null);
    final results = await Future.wait([historyFuture, descriptionFuture]);
    return (
      history: results[0] as List<OneRmHistory>,
      description: results[1] as String?,
    );
  }

  void _reloadData() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

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
        title: widget.variantName != null
            ? Text(
                widget.variantName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: Responsive.font(context, base: 18, min: 15, max: 20),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : Text(
                '1RM HISTORY',
                style: GoogleFonts.outfit(
                  fontSize: Responsive.font(context, base: 11, min: 10, max: 12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.5,
                  color: const Color(0xFF555555),
                ),
              ),
        actions: [
          if (widget.variantName != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Color(0xFF666666)),
              tooltip: 'Exercise form guide',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await launchExrxReference(widget.variantName!);
                if (!ok && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Could not open browser')),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF666666)),
            tooltip: 'What is 1RM?',
            onPressed: () => showOneRmInfoSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: widget.variantId == null
            ? _buildEmptyState(context)
            : FutureBuilder<_DetailData>(
                future: _dataFuture,
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

                  final data = snapshot.data;
                  final history = data?.history ?? [];
                  final description = data?.description;
                  final variantName = widget.variantName ?? '';
                  final showDesc = shouldShowVariantDescription(
                    variantName,
                    description,
                  );

                  if (history.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDesc) _DescriptionCard(text: description!),
                        Expanded(
                          child: Center(
                            child: Text(
                              'No 1RM history',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length + (showDesc ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const Divider(color: Color(0xFF222222), height: 1),
                    itemBuilder: (_, i) {
                      if (showDesc && i == 0) {
                        return _DescriptionCard(text: description!);
                      }
                      final recordIndex = showDesc ? i - 1 : i;
                      return _HistoryRow(record: history[recordIndex]);
                    },
                  );
                },
              ),
      ),
      floatingActionButton: widget.variantId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showUpdateModal(context),
              label: const Text('Update 1RM'),
              icon: const Icon(Icons.edit),
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add a 1RM',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showUpdateModal(context),
            child: const Text('Set 1RM'),
          ),
        ],
      ),
    );
  }

  void _showUpdateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(),
      builder: (context) => _UpdateOneRmModal(
        variantId: widget.variantId,
        onUpdate: _reloadData,
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String text;

  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: const Color(0xFF777777),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final OneRmHistory record;

  const _HistoryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = record.date;
    final dateStr = DateFormat('MMM d, yyyy').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF888888),
            ),
          ),
          Text(
            '${record.weight.toStringAsFixed(0)} lbs',
            maxLines: 1,
            style: GoogleFonts.spaceGrotesk(
              fontSize: Responsive.font(context, base: 18, min: 15, max: 20),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateOneRmModal extends StatefulWidget {
  final int? variantId;
  final VoidCallback onUpdate;

  const _UpdateOneRmModal({required this.variantId, required this.onUpdate});

  @override
  State<_UpdateOneRmModal> createState() => _UpdateOneRmModalState();
}

class _UpdateOneRmModalState extends State<_UpdateOneRmModal> {
  late TextEditingController _weightController;
  double _weight = 0.0;
  double? _currentOneRm;
  bool _isSaving = false;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _loadCurrentOneRm();
  }

  Future<void> _loadCurrentOneRm() async {
    if (widget.variantId == null) return;
    final repo = OneRmRepository();
    final oneRm = await repo.getCurrentOneRm(widget.variantId!);
    if (mounted) {
      setState(() => _currentOneRm = oneRm);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _adjustWeight(double delta) {
    final newWeight = (_weight + delta).clamp(0.0, 999.9);
    setState(() {
      _weight = newWeight;
      if (newWeight > 0) _weightError = null;
    });
    _weightController.text = newWeight.toStringAsFixed(0);
  }

  Future<void> _submit() async {
    if (_weight <= 0) {
      setState(() => _weightError = 'Enter a weight greater than 0');
      return;
    }
    if (widget.variantId == null) return;

    setState(() => _isSaving = true);
    try {
      await OneRmRepository().recordNewOneRm(
        widget.variantId!,
        _weight,
        DateTime.now(),
        notes: 'Manual update',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('1RM updated — ${_weight.toStringAsFixed(0)} lbs'),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save failed — please retry'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomSafeArea = mediaQuery.padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset + bottomSafeArea),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentOneRm == null ? 'Set 1RM' : 'Update 1RM',
            style: GoogleFonts.spaceGrotesk(
              fontSize: Responsive.font(context, base: 20, min: 17, max: 22),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showOneRmInfoSheet(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'What is 1RM?',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
          ),
          if (_currentOneRm != null) ...[
            const SizedBox(height: 4),
            Text(
              'Current: ${_currentOneRm!.toStringAsFixed(0)} lbs',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
          ],
          const SizedBox(height: 24),
          WeightStepper(
            weight: _weight,
            controller: _weightController,
            onChanged: (v) {
              final parsed = (double.tryParse(v) ?? 0.0).clamp(0.0, 999.9);
              setState(() {
                _weight = parsed;
                if (parsed > 0) _weightError = null;
              });
            },
            onAdjust: _adjustWeight,
            accentColor: const Color(0xFF00D9FF),
            errorText: _weightError,
          ),
          if (_currentOneRm != null &&
              _weight > 0 &&
              _weight < _currentOneRm!) ...[
            const SizedBox(height: 12),
            Text(
              'Lower than current 1RM (${_currentOneRm!.toStringAsFixed(0)} lbs) — this will reset your baseline',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF444444),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}
