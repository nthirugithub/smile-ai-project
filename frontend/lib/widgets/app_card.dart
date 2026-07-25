import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Surface card using [AppTheme.cardTheme] elevation, color, and shape.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.color,
    this.borderRadius = 16,
    this.elevation,
    this.width,
    this.constraints,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderRadius;
  final double? elevation;
  final double? width;
  final BoxConstraints? constraints;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedColor = color ??
        cardTheme.color ??
        (isDark ? AppTheme.surfaceDarkColor : AppTheme.cardColor);

    final resolvedElevation =
        elevation ?? cardTheme.elevation ?? (isDark ? 4.0 : 2.0);

    final resolvedShadowColor = cardTheme.shadowColor ??
        Colors.black.withAlpha(isDark ? 51 : 13);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    return Container(
      width: width,
      margin: margin,
      constraints: constraints,
      child: Material(
        color: resolvedColor,
        elevation: resolvedElevation,
        shadowColor: resolvedShadowColor,
        shape: shape,
        clipBehavior: clipBehavior,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
