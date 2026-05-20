import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../data/models/session.dart';
import '../../data/models/workout.dart';

class VariantSelector extends StatelessWidget {
  final SessionExercise sessionExercise;
  final VoidCallback onVariantSwapped;

  const VariantSelector({
    super.key,
    required this.sessionExercise,
    required this.onVariantSwapped,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SessionProvider>();
    final slot = provider.getSlotForExercise(sessionExercise.slotId);

    if (slot == null || slot.variants.length <= 1) {
      return const SizedBox();
    }

    return ElevatedButton.icon(
      onPressed: () => _showVariantDialog(context, slot),
      icon: const Icon(Icons.swap_horiz),
      label: const Text('Change Exercise'),
    );
  }

  void _showVariantDialog(BuildContext context, ExerciseSlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Exercise Variant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...slot.variants.map((variant) {
                final isSelected = variant.id == sessionExercise.chosenVariantId;
                return ListTile(
                  title: Text(variant.name),
                  subtitle: variant.description != null
                      ? Text(variant.description!)
                      : null,
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: isSelected
                      ? null
                      : () {
                          Navigator.pop(context);
                          _swapVariant(context, variant.id!);
                        },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _swapVariant(BuildContext context, int newVariantId) async {
    final provider = context.read<SessionProvider>();
    await provider.swapVariant(sessionExercise.id!, newVariantId);
    onVariantSwapped();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise swapped')),
      );
    }
  }
}
