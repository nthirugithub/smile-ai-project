import 'package:flutter/material.dart';

/// Central Design System Color Tokens for Clinical Enterprise Medical AI UI.
/// Supports high-contrast Light and Dark theme palettes.
class ThemeColors {
  // ---------- Brand & Primary Colors ----------

  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3B82F6) // Clinical Sapphire Dark
        : const Color(0xFF1E40AF); // Clinical Deep Navy Blue Light
  }

  static Color primaryContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFEFF6FF);
  }

  static Color onPrimaryContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF1E40AF);
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
  }

  // ---------- Surfaces & Backgrounds ----------

  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color card(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);
  }

  // ---------- Typography ----------

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
  }

  static Color mutedText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);
  }

  // ---------- Borders & Dividers ----------

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
  }

  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
  }

  // ---------- Inputs ----------

  static Color inputFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFFFFFFF);
  }

  static Color inputHoverFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFF8FAFC);
  }

  static Color inputFocusFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFFFFFFF);
  }

  static Color inputBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
  }

  static Color inputHoverBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF475569)
        : const Color(0xFF94A3B8);
  }

  static Color inputFocus(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1E40AF);
  }

  static Color inputHint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);
  }

  // ---------- Status & Feedback (Clinical Grade) ----------

  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF22C55E)
          : const Color(0xFF16A34A);

  static Color successContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF064E3B)
          : const Color(0xFFDCFCE7);

  static Color onSuccessContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF86EFAC)
          : const Color(0xFF15803D);

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF59E0B)
          : const Color(0xFFD97706);

  static Color warningContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF78350F)
          : const Color(0xFFFEF3C7);

  static Color onWarningContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFDE68A)
          : const Color(0xFFB45309);

  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFEF4444)
          : const Color(0xFFDC2626);

  static Color errorContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF7F1D1D)
          : const Color(0xFFFEE2E2);

  static Color onErrorContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFCA5A5)
          : const Color(0xFFB91C1C);

  static Color info(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF38BDF8)
          : const Color(0xFF0284C7);

  static Color infoContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0C4A6E)
          : const Color(0xFFE0F2FE);

  static Color onInfoContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF7DD3FC)
          : const Color(0xFF0369A1);

  // ---------- Card & Shadow Tokens ----------

  static Color cardShadow(BuildContext context) {
    return Colors.black.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark
          ? 0.30
          : 0.05,
    );
  }

  static List<BoxShadow> shadowSm([BuildContext? context]) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: (context != null && Theme.of(context).brightness == Brightness.dark)
                ? 0.20
                : 0.04,
          ),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd([BuildContext? context]) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: (context != null && Theme.of(context).brightness == Brightness.dark)
                ? 0.25
                : 0.06,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowLg([BuildContext? context]) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: (context != null && Theme.of(context).brightness == Brightness.dark)
                ? 0.35
                : 0.08,
          ),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> cardShadowSoft([BuildContext? context]) => shadowSm(context);

  static List<BoxShadow> authCardShadow([BuildContext? context]) => shadowMd(context);

  static List<BoxShadow> cardShadowMedium([BuildContext? context]) => shadowMd(context);

  static List<BoxShadow> primaryGlowShadow([BuildContext? context, Color? color]) => [
        BoxShadow(
          color: (color ?? const Color(0xFF1E40AF)).withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> actionButtonShadow([BuildContext? context]) => shadowSm(context);

  static List<BoxShadow> statSubtleShadow([BuildContext? context]) => shadowSm(context);
}
