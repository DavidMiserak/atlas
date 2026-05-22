import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum ScreenSizeClass { compact, medium, expanded }

class Responsive {
  static ScreenSizeClass sizeClassForWidth(double width) {
    if (width < 380) return ScreenSizeClass.compact;
    if (width < 720) return ScreenSizeClass.medium;
    return ScreenSizeClass.expanded;
  }

  static double scaleForWidth(double width) {
    if (width < 360) return 0.9;
    if (width < 400) return 0.95;
    if (width < 600) return 1.0;
    if (width < 900) return 1.08;
    return 1.16;
  }

  static double font(
    BuildContext context, {
    required double base,
    double min = 10,
    double max = 72,
  }) {
    final media = MediaQuery.of(context);
    final scaled = base * scaleForWidth(media.size.width);
    final clamped = scaled.clamp(min, max);
    return media.textScaler.scale(clamped);
  }

  static double space(
    BuildContext context,
    double base, {
    double min = 2,
    double? max,
  }) {
    final width = MediaQuery.of(context).size.width;
    final scaled = base * scaleForWidth(width);
    final upper = max ?? base * 1.3;
    return scaled.clamp(min, upper).toDouble();
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 16);
    }
    if (width < 720) {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 28);
  }

  static double constrainedContentWidth(BuildContext context, {double max = 860}) {
    final width = MediaQuery.of(context).size.width;
    return math.min(width, max);
  }
}

extension ResponsiveBuildContext on BuildContext {
  bool get isCompact =>
      Responsive.sizeClassForWidth(MediaQuery.of(this).size.width) ==
      ScreenSizeClass.compact;

  bool get isExpanded =>
      Responsive.sizeClassForWidth(MediaQuery.of(this).size.width) ==
      ScreenSizeClass.expanded;
}
