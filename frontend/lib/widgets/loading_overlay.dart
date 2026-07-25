import 'dart:async';

import 'package:flutter/material.dart';

class LoadingOverlay extends StatefulWidget {
  final bool visible;
  final String title;

  const LoadingOverlay({
    super.key,
    required this.visible,
    this.title = "AI Analysis in Progress",
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  final List<String> _steps = [
    "Detecting face...",
    "Extracting facial landmarks...",
    "Measuring smile metrics...",
    "Running AI model...",
    "Generating clinical summary..."
  ];

  int _currentStep = 0;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible && !oldWidget.visible) {
      _startAnimation();
    }

    if (!widget.visible) {
      _timer?.cancel();
      _currentStep = 0;
    }
  }

  void _startAnimation() {
    _timer?.cancel();

    _currentStep = 0;

    _timer = Timer.periodic(
      const Duration(milliseconds: 700),
          (timer) {
        if (!mounted) return;

        if (_currentStep < _steps.length - 1) {
          setState(() {
            _currentStep++;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: .9, end: 1),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 1.1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    onEnd: () {
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      height: 82,
                      width: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF3B82F6),
                        size: 42,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 14),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child:
                    Text(
                      _steps[_currentStep],
                      key: ValueKey(_currentStep),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween(
                      begin: 0,
                      end: (_currentStep + 1) / _steps.length,
                    ),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}