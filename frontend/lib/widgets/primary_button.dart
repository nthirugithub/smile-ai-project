import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PrimaryButtonVariant { filled, inverted }

/// Primary action button using [AppTheme.elevatedButtonTheme] values.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.variant = PrimaryButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? height;
  final PrimaryButtonVariant variant;

  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(12));
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const TextStyle _textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  ButtonStyle _resolveStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeStyle = theme.elevatedButtonTheme.style;

    if (variant == PrimaryButtonVariant.inverted) {
      return (themeStyle ?? const ButtonStyle()).merge(
        ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.surfaceDarkColor : AppTheme.surfaceColor,
          foregroundColor: isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor,
          elevation: 0,
          padding: _padding,
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
          textStyle: _textStyle,
        ),
      );
    }

    return (themeStyle ?? const ButtonStyle()).merge(
      ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: _padding,
        shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
        textStyle: _textStyle,
      ),
    );
  }

  Color _loadingColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (variant == PrimaryButtonVariant.inverted) {
      return isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    }

    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _resolveStyle(context),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _loadingColor(context),
              ),
            )
          : icon == null
              ? Text(label)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 10),
                    Text(label),
                  ],
                ),
    );

    if (!fullWidth && height == null) {
      return button;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}
