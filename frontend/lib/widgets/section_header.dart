import 'package:flutter/material.dart';

/// Section title styled with [AppTheme.appBarTheme.titleTextStyle].
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.spacing = 8,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  TextStyle _titleStyle(BuildContext context) {
    return const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF0F172A),
    );
  }

  TextStyle _subtitleStyle(BuildContext context) {
    return const TextStyle(
      fontSize: 15,
      height: 1.6,
      color: Color(0xFF64748B),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _titleStyle(context)),
              if (subtitle != null) ...[
                SizedBox(height: spacing),
                Text(subtitle!, style: _subtitleStyle(context)),
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
