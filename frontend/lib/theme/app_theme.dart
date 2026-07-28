import 'package:flutter/material.dart';
import 'theme_colors.dart';
import '../utils/responsive.dart';

/// Design Tokens: Radii for clinical enterprise UI elements
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

/// Design Tokens: Spacing scale
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Design Tokens: Standardized Elevation Levels
class AppElevation {
  static const double flat = 0.0;
  static const double low = 1.0;
  static const double medium = 2.0;
  static const double high = 4.0;
  static const double dialog = 8.0;
}

/// Typography Design Tokens & Helper Methods
class AppTypography {
  static TextStyle pageTitle(BuildContext context) => TextStyle(
        fontFamily: 'Inter',
        fontSize: Responsive.titleFont(context),
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: ThemeColors.text(context),
      );

  static TextStyle sectionTitle(BuildContext context) => TextStyle(
        fontFamily: 'Inter',
        fontSize: Responsive.headingFont(context),
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: ThemeColors.text(context),
      );

  static TextStyle cardTitle(BuildContext context) => TextStyle(
        fontFamily: 'Inter',
        fontSize: Responsive.isPhone(context) ? 15 : 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: ThemeColors.text(context),
      );

  static TextStyle label(BuildContext context) => TextStyle(
        fontFamily: 'Inter',
        fontSize: Responsive.isPhone(context) ? 13.5 : 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: ThemeColors.text(context),
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontFamily: 'Inter',
        fontSize: Responsive.bodyFont(context),
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: ThemeColors.text(context),
      );

  static TextStyle caption(BuildContext context) => TextStyle(
        fontFamily: 'Inter',
        fontSize: Responsive.isPhone(context) ? 11.5 : 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: ThemeColors.secondaryText(context),
      );
}

/// Enterprise Medical AI Theme Configuration
class AppTheme {
  // Brand Primary & Accent Colors
  static const Color primaryColor = Color(0xFF1E40AF); // Clinical Deep Navy Light
  static const Color primaryLightColor = Color(0xFF3B82F6); // Clinical Sapphire Dark
  static const Color accentColor = Color(0xFF0284C7); // Clinical Cyan Accent
  static const Color successColor = Color(0xFF16A34A); // Clinical Emerald Green
  static const Color warningColor = Color(0xFFD97706); // Clinical Amber
  static const Color errorColor = Color(0xFFDC2626); // Clinical Crimson

  // Backgrounds & Surfaces (Light)
  static const Color backgroundColor = Color(0xFFF8FAFC); // Clean Clinical Slate Background
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Backgrounds & Surfaces (Dark)
  static const Color primaryDarkColor = Color(0xFF0F172A);
  static const Color backgroundDarkColor = Color(0xFF0B0F17); // Premium Dark Background
  static const Color surfaceDarkColor = Color(0xFF1E293B); // Dark Surface Card

  /// Light Theme Definition
  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.4),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), letterSpacing: -0.2),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF0F172A), height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.4),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF64748B)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: AppElevation.low,
        shadowColor: Colors.black.withAlpha(10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: AppElevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF475569),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark Theme Definition
  static ThemeData get darkTheme {
    const textTheme = TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC), letterSpacing: -0.4),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC), letterSpacing: -0.2),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFFF8FAFC), height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF94A3B8), height: 1.4),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF64748B)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLightColor,
      scaffoldBackgroundColor: backgroundDarkColor,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: primaryLightColor,
        secondary: accentColor,
        surface: surfaceDarkColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF8FAFC),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceDarkColor,
        elevation: AppElevation.low,
        shadowColor: Colors.black.withAlpha(50),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFFF8FAFC),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLightColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLightColor,
          side: const BorderSide(color: Color(0xFF334155), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDarkColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: primaryLightColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDarkColor,
        elevation: AppElevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF8FAFC),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF94A3B8),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
