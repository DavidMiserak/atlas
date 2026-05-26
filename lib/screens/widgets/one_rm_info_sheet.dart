import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/responsive.dart';

/// Bottom sheet explaining what 1RM means. Shared by list screen, detail modal, etc.
class OneRmInfoSheet extends StatelessWidget {
  const OneRmInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is 1RM?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: Responsive.font(context, base: 20, min: 17, max: 22),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your One Rep Maximum (1RM) is the heaviest weight you can lift for '
            'a single repetition of an exercise. Atlas uses your 1RM to calculate '
            'target weights for each training set — typically a percentage of your 1RM.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.45,
              color: const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

void showOneRmInfoSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0D0D0D),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const OneRmInfoSheet(),
  );
}
