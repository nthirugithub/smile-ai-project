import 'package:flutter/material.dart';

class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.controller,
    required this.child,

    this.delay = 0.0,
    this.end = 1.0,

    this.beginOffset = const Offset(0, 0.06),
    this.beginScale = 0.985,

    this.curve = Curves.easeOutQuart,

    this.enableFade = true,
    this.enableSlide = true,
    this.enableScale = true,
  });

  final AnimationController controller;
  final Widget child;

  final double delay;
  final double end;

  final Offset beginOffset;
  final double beginScale;

  final Curve curve;

  final bool enableFade;
  final bool enableSlide;
  final bool enableScale;

  static const bool _disableAnimations =
      bool.fromEnvironment('DISABLE_ANIMATIONS', defaultValue: false);

  @override
  Widget build(BuildContext context) {
    if (_disableAnimations) {
      return child;
    }

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.clamp(0.0, 1.0),
        end.clamp(delay, 1.0),
        curve: curve,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: beginScale,
            end: 1.0,
          ).animate(animation),
          child: child,
        ),
      ),
    );
  }
}