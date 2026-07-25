import 'package:flutter/material.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(24),
    ),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,

        transform: Matrix4.identity()
          ..translateByDouble(
            0.0,
            hovering ? -6.0 : 0.0,
            0.0,
            1.0,
          )
          ..scaleByDouble(
            hovering ? 1.01 : 1.0,
            hovering ? 1.01 : 1.0,
            1.0,
            1.0,
          ),

        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: hovering
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            )
          ]
              : [],
        ),

        child: widget.child,
      ),
    );
  }
}