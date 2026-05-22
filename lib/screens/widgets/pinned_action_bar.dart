import 'package:flutter/material.dart';

/// Fixed bottom dock matching [WorkoutOverviewScreen] primary-action styling.
class PinnedActionBar extends StatelessWidget {
  final Widget child;

  const PinnedActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: child,
    );
  }
}
