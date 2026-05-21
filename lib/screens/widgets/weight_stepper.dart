import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightStepper extends StatelessWidget {
  final double weight;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final void Function(double) onAdjust;
  final Color accentColor;
  final String? errorText;

  const WeightStepper({
    super.key,
    required this.weight,
    required this.controller,
    required this.onChanged,
    required this.onAdjust,
    required this.accentColor,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WEIGHT',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF909090),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StepButton(label: '−10', onTap: () => onAdjust(-10)),
            const SizedBox(width: 4),
            StepButton(label: '−5', onTap: () => onAdjust(-5), small: true),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: onChanged,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText: '0',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF444444),
                      ),
                      suffixText: 'lbs',
                      suffixStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            StepButton(label: '+5', onTap: () => onAdjust(5), small: true),
            const SizedBox(width: 4),
            StepButton(label: '+10', onTap: () => onAdjust(10)),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.redAccent),
          ),
        ],
      ],
    );
  }
}

class StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool small;

  const StepButton({super.key, required this.label, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: small ? 12 : 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB0B0B0),
          ),
        ),
      ),
    );
  }
}
