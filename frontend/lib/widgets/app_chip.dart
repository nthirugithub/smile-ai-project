import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

enum AppChipVariant { success, warning, error, info, neutral }

/// Clinical Enterprise Status Chip / Badge component
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppChipVariant variant;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry padding;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppChipVariant.neutral,
    this.onTap,
    this.isSelected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  Color _bgColor(BuildContext context) {
    if (isSelected) {
      return ThemeColors.primary(context);
    }
    switch (variant) {
      case AppChipVariant.success:
        return ThemeColors.successContainer(context);
      case AppChipVariant.warning:
        return ThemeColors.warningContainer(context);
      case AppChipVariant.error:
        return ThemeColors.errorContainer(context);
      case AppChipVariant.info:
        return ThemeColors.infoContainer(context);
      case AppChipVariant.neutral:
        return ThemeColors.surfaceVariant(context);
    }
  }

  Color _fgColor(BuildContext context) {
    if (isSelected) {
      return Colors.white;
    }
    switch (variant) {
      case AppChipVariant.success:
        return ThemeColors.onSuccessContainer(context);
      case AppChipVariant.warning:
        return ThemeColors.onWarningContainer(context);
      case AppChipVariant.error:
        return ThemeColors.onErrorContainer(context);
      case AppChipVariant.info:
        return ThemeColors.onInfoContainer(context);
      case AppChipVariant.neutral:
        return ThemeColors.secondaryText(context);
    }
  }

  BorderSide _borderSide(BuildContext context) {
    if (isSelected) {
      return BorderSide.none;
    }
    switch (variant) {
      case AppChipVariant.neutral:
        return BorderSide(color: ThemeColors.border(context), width: 1);
      default:
        return BorderSide.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor(context);
    final fg = _fgColor(context);
    final border = _borderSide(context);

    Widget chipChild = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderPill,
        border: border != BorderSide.none ? Border.all(color: border.color, width: border.width) : null,
      ),
      child: chipChild,
    );

    if (onTap == null) {
      return container;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderPill,
      child: container,
    );
  }
}
