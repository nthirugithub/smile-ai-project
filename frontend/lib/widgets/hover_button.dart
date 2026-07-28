import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class HoverButton extends StatefulWidget {
  const HoverButton({
    super.key,
    required this.child,
    this.enabled = true,
    this.lift = 2.0,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 160),
    this.curve = Curves.easeOutCubic,
    this.borderRadius = AppRadius.borderMd,
  });

  final Widget child;
  final bool enabled;
  final double lift;
  final double scale;
  final Duration duration;
  final Curve curve;
  final BorderRadius borderRadius;

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovering = false;

  bool get _canHover {
    return widget.enabled &&
        (kIsWeb ||
            {
              TargetPlatform.macOS,
              TargetPlatform.windows,
              TargetPlatform.linux,
            }.contains(defaultTargetPlatform));
  }

  @override
  Widget build(BuildContext context) {
    if (!_canHover) {
      return widget.child;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        transform: Matrix4.translationValues(
          0,
          _hovering ? -widget.lift : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: _hovering ? ThemeColors.shadowSm(context) : const [],
        ),
        child: widget.child,
      ),
    );
  }
}