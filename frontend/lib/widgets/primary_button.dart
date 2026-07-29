import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

enum PrimaryButtonVariant { filled, inverted, outlined }

/// Primary action button using enterprise design system tokens.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.fullWidth = true,
    this.height = 48.0,
    this.variant = PrimaryButtonVariant.filled,
  }) : super(key: null);

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final String? loadingLabel;
  final bool fullWidth;
  final double? height;
  final PrimaryButtonVariant variant;

  static const TextStyle _textStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  ButtonStyle _resolveStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (variant == PrimaryButtonVariant.inverted) {
      return ElevatedButton.styleFrom(
        backgroundColor: ThemeColors.card(context),
        foregroundColor: ThemeColors.primary(context),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: ThemeColors.border(context)),
        ),
        textStyle: _textStyle,
      );
    }

    if (variant == PrimaryButtonVariant.outlined) {
      return ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: ThemeColors.primary(context),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: ThemeColors.border(context), width: 1.2),
        ),
        textStyle: _textStyle,
      );
    }

    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      textStyle: _textStyle,
    );
  }

  Color _loadingColor(BuildContext context) {
    if (variant == PrimaryButtonVariant.inverted || variant == PrimaryButtonVariant.outlined) {
      return ThemeColors.primary(context);
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      key: key,
      onPressed: () {
        if (isLoading) return;
        onPressed?.call();
      },
      style: _resolveStyle(context),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: 0.7,
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _loadingColor(context),
                    ),
                  ),
                ),
                if (loadingLabel != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    loadingLabel!,
                    style: _textStyle.copyWith(
                      color: _loadingColor(context),
                    ),
                  ),
                ],
              ],
            )
          : icon == null
              ? Text(label)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
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
