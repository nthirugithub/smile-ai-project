import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

enum AppIconSize { sm, md, lg }

/// Standardized Icon Container / Avatar Badge for Enterprise UI
class AppIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final AppIconSize size;
  final BorderRadius? borderRadius;

  const AppIconContainer({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = AppIconSize.md,
    this.borderRadius,
  });

  double get _boxSize {
    switch (size) {
      case AppIconSize.sm:
        return 32.0;
      case AppIconSize.md:
        return 40.0;
      case AppIconSize.lg:
        return 48.0;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppIconSize.sm:
        return 16.0;
      case AppIconSize.md:
        return 20.0;
      case AppIconSize.lg:
        return 24.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFg = color ?? ThemeColors.primary(context);
    final effectiveBg = backgroundColor ?? ThemeColors.primaryContainer(context);
    final effectiveRadius = borderRadius ?? AppRadius.borderMd;

    return Container(
      width: _boxSize,
      height: _boxSize,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          size: _iconSize,
          color: effectiveFg,
        ),
      ),
    );
  }
}
