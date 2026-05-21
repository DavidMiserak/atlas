import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/one_rm_repository.dart';
import 'widgets/weight_stepper.dart';

class OneRmHistoryDetailScreen extends StatefulWidget {
  final int? variantId;

  const OneRmHistoryDetailScreen({super.key, required this.variantId});

  @override
  State<OneRmHistoryDetailScreen> createState() => _OneRmHistoryDetailScreenState();
}

class _OneRmHistoryDetailScreenState extends State<OneRmHistoryDetailScreen> {
  late Future<List<OneRmHistory>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<OneRmHistory>> _loadHistory() async {
    if (widget.variantId == null) return [];
    final repo = OneRmRepository();
    return repo.getOneRmHistory(widget.variantId!);
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
      body: widget.variantId == null
          ? _buildEmptyState(context)
          : FutureBuilder<List<OneRmHistory>>(
              future: _historyFuture,
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

                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Center(
                    child: Text(
                      'No 1RM history',
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(color: Color(0xFF222222), height: 1),
                  itemBuilder: (_, i) => _HistoryRow(record: history[i]),
                );
              },
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
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
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
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(),
      builder: (context) => _UpdateOneRmModal(
        variantId: widget.variantId,
        onUpdate: () {
          setState(() => _historyFuture = _loadHistory());
        },
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
    final dateStr = '${date.month}/${date.day}/${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF888888)),
          ),
          Text(
            '${record.weight.toStringAsFixed(0)} lbs',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Update 1RM',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
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
          if (_currentOneRm != null && _weight > 0 && _weight < _currentOneRm!) ...[
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
