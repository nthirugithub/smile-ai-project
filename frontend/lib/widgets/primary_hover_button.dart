import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

class PrimaryHoverButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  const PrimaryHoverButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  @override
  State<PrimaryHoverButton> createState() => _PrimaryHoverButtonState();
}

class _PrimaryHoverButtonState extends State<PrimaryHoverButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? ThemeColors.primary(context);
    final fg = widget.foregroundColor ?? Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderMd,
          boxShadow: hovering
              ? ThemeColors.primaryGlowShadow(context, bg)
              : [],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: bg,
            foregroundColor: fg,
            padding: widget.padding ??
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}