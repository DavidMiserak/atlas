import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/responsive.dart';

/// Premium metric display for 1RM, PR, weight, etc.
/// Shows large bold number with supporting label
class MetricDisplay extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final bool isHighlight;

  const MetricDisplay({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = color ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Responsive.space(context, 20, max: 24),
          horizontal: Responsive.space(context, 20, min: 14, max: 24),
        ),
        decoration: BoxDecoration(
          color: isHighlight
              ? accentColor.withValues(alpha: 0.1)
              : colorScheme.surfaceContainer,
          border: isHighlight
              ? Border.all(
                  color: accentColor,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: Responsive.font(context, base: 12, min: 10, max: 13),
                fontWeight: FontWeight.w500,
                color: Color(0xFF909090),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: Responsive.font(context, base: 32, min: 22, max: 36),
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
