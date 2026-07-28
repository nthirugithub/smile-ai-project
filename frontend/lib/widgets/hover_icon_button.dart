import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

class HoverIconButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverIconButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            color: _hover ? ThemeColors.surfaceVariant(context) : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}