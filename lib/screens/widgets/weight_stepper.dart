import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/responsive.dart';

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
            fontSize: Responsive.font(context, base: 11, min: 10, max: 12),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF909090),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackSides = constraints.maxWidth < 380;
            final input = Center(
              child: IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onChanged,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: Responsive.font(context, base: 40, min: 30, max: 44),
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
                      fontSize: Responsive.font(context, base: 40, min: 30, max: 44),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF444444),
                    ),
                    suffixText: 'lbs',
                    suffixStyle: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, base: 16, min: 13, max: 17),
                      color: const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _WeightAdjustSide(
                  vertical: stackSides,
                  children: [
                    StepButton(label: '−10', onTap: () => onAdjust(-10)),
                    StepButton(label: '−5', onTap: () => onAdjust(-5), small: true),
                  ],
                ),
                SizedBox(width: stackSides ? 8 : 12),
                Expanded(child: input),
                SizedBox(width: stackSides ? 8 : 12),
                _WeightAdjustSide(
                  vertical: stackSides,
                  children: [
                    StepButton(label: '+5', onTap: () => onAdjust(5), small: true),
                    StepButton(label: '+10', onTap: () => onAdjust(10)),
                  ],
                ),
              ],
            );
          },
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

class _WeightAdjustSide extends StatelessWidget {
  final bool vertical;
  final List<Widget> children;

  const _WeightAdjustSide({required this.vertical, required this.children});

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            children[i],
          ],
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          children[i],
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
