import 'package:flutter/material.dart';

class PrimaryHoverButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry? padding;

  const PrimaryHoverButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = const Color(0xFF2563EB),
    this.foregroundColor = Colors.white,
    this.padding,
  });

  @override
  State<PrimaryHoverButton> createState() => _PrimaryHoverButtonState();
}

class _PrimaryHoverButtonState extends State<PrimaryHoverButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        scale: hovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: hovering
                ? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}