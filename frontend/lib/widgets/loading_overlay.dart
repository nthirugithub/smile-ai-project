import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

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
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            width: (MediaQuery.of(context).size.width * 0.88).clamp(280.0, 460.0),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ThemeColors.card(context),
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: ThemeColors.border(context)),
              boxShadow: ThemeColors.shadowLg(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ThemeColors.primaryContainer(context),
                  ),
                  child: Icon(
                    Icons.document_scanner_rounded,
                    color: ThemeColors.primary(context),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: ThemeColors.text(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _steps[_currentStep],
                    key: ValueKey(_currentStep),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: ThemeColors.secondaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  minHeight: 6,
                  backgroundColor: ThemeColors.surfaceVariant(context),
                  color: ThemeColors.primary(context),
                  borderRadius: AppRadius.borderPill,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}