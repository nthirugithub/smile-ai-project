import 'dart:math' as math;
import 'package:flutter/material.dart';

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

  Color get gaugeColor {
    if (widget.score >= 8.5) {
      return Colors.green;
    }

    if (widget.score >= 7) {
      return Colors.blue;
    }

    if (widget.score >= 5) {
      return Colors.orange;
    }

    return Colors.red;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
            ),

            child: Center(

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Text(
                    _animation.value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "/10",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    widget.level,
                    style: TextStyle(
                      color: gaugeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
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

  const _GaugePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;

    final center = Offset(size.width / 2, size.height / 2);

    final radius =
        (math.min(size.width, size.height) - strokeWidth) / 2;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    // Background Ring
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
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

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      glowPaint,
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
        oldDelegate.color != color;
  }
}
