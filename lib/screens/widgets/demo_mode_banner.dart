import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key, this.label = 'DEMO MODE'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFFFC857).withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: const Color(0xFFFFC857),
        ),
      ),
    );
  }
}
