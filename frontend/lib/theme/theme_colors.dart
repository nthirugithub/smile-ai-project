import 'package:flutter/material.dart';

class ThemeColors {

  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color card(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color secondaryText(BuildContext context) {

    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : const Color(0xFF64748B);

  }

  static Color border(BuildContext context) {

    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : const Color(0xFFE2E8F0);

  }

  static Color inputFill(BuildContext context) {

    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);

  }

}