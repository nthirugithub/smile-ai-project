import 'package:flutter/material.dart';

class AnimatedGlow extends StatefulWidget {
  const AnimatedGlow({
    super.key,
    required this.size,
    required this.top,
    required this.left,
    required this.colors,
  });

  final double size;
  final double top;
  final double left;
  final List<Color> colors;

  @override
  State<AnimatedGlow> createState() => _AnimatedGlowState();
}

class _AnimatedGlowState extends State<AnimatedGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    const isTestMode = bool.fromEnvironment('DISABLE_ANIMATIONS', defaultValue: false);
    if (!isTestMode) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animation = Curves.easeInOut.transform(_controller.value);

        return Positioned(
          top: widget.top + (animation * 12),
          left: widget.left + (animation * 12),
          child: Opacity(
            opacity: 0.82 + (animation * 0.18),
            child: child,
          ),
        );
      },
      child: IgnorePointer(
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: widget.colors,
            ),
          ),
        ),
      ),
    );
  }
}