import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

/// Minimal clinical hover card with subtle lift and elevation transition.
class HoverCard extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.borderLg,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(
            0.0,
            hovering ? -2.0 : 0.0,
            0.0,
            1.0,
          ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: hovering
              ? ThemeColors.shadowMd(context)
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}