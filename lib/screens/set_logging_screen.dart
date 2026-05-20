import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class SetLoggingScreen extends StatefulWidget {
  final int sessionExerciseId;

  const SetLoggingScreen({
    super.key,
    required this.sessionExerciseId,
  });

  @override
  State<SetLoggingScreen> createState() => _SetLoggingScreenState();
}

class _SetLoggingScreenState extends State<SetLoggingScreen> {
  int _setNumber = 1;
  int _reps = 5;
  double _weight = 0.0;
  int _rpe = 7;
  String? _notes;

  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _rpeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weightController.text = _weight.toString();
    _repsController.text = _reps.toString();
    _rpeController.text = _rpe.toString();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitSet() async {
    final provider = context.read<SessionProvider>();

    try {
      await provider.logSet(
        widget.sessionExerciseId,
        _setNumber,
        _reps,
        _weight,
        _rpe,
        notes: _notes,
      );

      if (mounted) {
        _setNumber++;
        _repsController.clear();
        _weightController.clear();
        _rpeController.clear();
        _notesController.clear();

        setState(() {
          _reps = 5;
          _weight = 0.0;
          _rpe = 7;
          _notes = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set $_setNumber logged'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _finishExercise() {
    final provider = context.read<SessionProvider>();
    provider.nextExercise();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Set'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set $_setNumber',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              _buildInputField(
                label: 'Reps',
                controller: _repsController,
                hint: '5',
                onChanged: (value) {
                  setState(() => _reps = int.tryParse(value) ?? 5);
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Weight (lbs)',
                controller: _weightController,
                hint: '225',
                onChanged: (value) {
                  setState(() => _weight = double.tryParse(value) ?? 0.0);
                },
              ),
              const SizedBox(height: 16),
              _buildRPESelector(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      onPressed: _submitSet,
                      child: const Text('Log Set'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      onPressed: _finishExercise,
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRPESelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RPE (Rate of Perceived Exertion)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Slider(
                  value: _rpe.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() => _rpe = value.toInt());
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'RPE $_rpe / 10',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (optional)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          onChanged: (value) => setState(() => _notes = value.isEmpty ? null : value),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Felt strong, form good, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
