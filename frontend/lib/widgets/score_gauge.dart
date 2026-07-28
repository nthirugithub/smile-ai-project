import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';

class SmileScoreGauge extends StatefulWidget {
  final double score;
  final String level;
  final double size;

  const SmileScoreGauge({
    super.key,
    required this.score,
    required this.level,
    this.size = 220,
  });

  @override
  State<SmileScoreGauge> createState() => _SmileScoreGaugeState();
}

class _SmileScoreGaugeState extends State<SmileScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  Color getGaugeColor(BuildContext context) {
    if (widget.score >= 8.5) {
      return ThemeColors.success(context);
    }
    if (widget.score >= 7.0) {
      return ThemeColors.info(context);
    }
    if (widget.score >= 5.0) {
      return ThemeColors.warning(context);
    }
    return ThemeColors.error(context);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.score.clamp(0.0, 10.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SmileScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: 0,
        end: widget.score.clamp(0.0, 10.0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );

      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gaugeColor = getGaugeColor(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              progress: _animation.value / 10,
              color: gaugeColor,
              trackColor: ThemeColors.border(context),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _animation.value.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: ThemeColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "/10",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ThemeColors.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.level,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: gaugeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    // Background Track Ring
    final backgroundPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      backgroundPaint,
    );

    // Progress Ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
