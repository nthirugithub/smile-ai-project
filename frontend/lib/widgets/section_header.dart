import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

/// Standardized Section Header with page/section typography hierarchy.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.spacing = 6,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.pageTitle(context),
              ),
              if (subtitle != null) ...[
                SizedBox(height: spacing),
                Text(
                  subtitle!,
                  style: AppTypography.body(context).copyWith(
                    color: ThemeColors.secondaryText(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );

    if (padding == null) {
      return content;
    }

    return Padding(
      padding: padding!,
      child: content,
    );
  }
}
