import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

/// Surface card using standardized design system tokens for elevation, border, and color.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.borderRadius = 16,
    this.elevation,
    this.width,
    this.height,
    this.constraints,
    this.clipBehavior = Clip.antiAlias,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderRadius;
  final double? elevation;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final Clip clipBehavior;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final resolvedColor = color ?? ThemeColors.card(context);
    final resolvedElevation = elevation ?? cardTheme.elevation ?? AppElevation.low;
    final resolvedBorder = border ?? BorderSide(color: ThemeColors.border(context), width: 1);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: resolvedBorder,
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      constraints: constraints,
      child: Material(
        color: resolvedColor,
        elevation: resolvedElevation,
        shadowColor: ThemeColors.cardShadow(context),
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
