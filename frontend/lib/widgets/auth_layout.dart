import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../widgets/animated_entrance.dart';
import '../services/theme_service.dart';
import '../theme/theme_colors.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.hero,
    required this.child,
    required this.animationController,
  });

  final Widget hero;
  final Widget child;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      floatingActionButton: const _AuthThemeSwitcher(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: EdgeInsets.fromLTRB(
              Responsive.pagePadding(context),
              Responsive.pagePadding(context),
              Responsive.pagePadding(context),
              Responsive.isPhone(context)
                  ? Responsive.pagePadding(context) * 2
                  : Responsive.pagePadding(context),
            ),
            child: Responsive.isPhone(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedEntrance(
                        controller: animationController,
                        delay: 0.0,
                        beginOffset: const Offset(-0.10, 0),
                        child: hero,
                      ),
                      SizedBox(
                        height: Responsive.isPhone(context) ? 16 : 32,
                      ),
                      AnimatedEntrance(
                        controller: animationController,
                        delay: 0.12,
                        beginOffset: const Offset(0, 0.05),
                        beginScale: 0.98,
                        child: child,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AnimatedEntrance(
                          controller: animationController,
                          delay: 0.0,
                          beginOffset: const Offset(-0.10, 0),
                          child: hero,
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        child: AnimatedEntrance(
                          controller: animationController,
                          delay: 0.12,
                          beginOffset: const Offset(0.05, 0),
                          beginScale: 0.98,
                          child: child,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AuthThemeSwitcher extends StatelessWidget {
  const _AuthThemeSwitcher();

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final currentThemeMode = ThemeService.instance.themeMode;

        return Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: ThemeColors.border(context),
                  width: 1,
                ),
              ),
              color: ThemeColors.card(context),
              elevation: 6,
            ),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Appearance',
            offset: const Offset(0, -160),
            onSelected: (String theme) async {
              await ThemeService.instance.setTheme(theme);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Light',
                child: Row(
                  children: [
                    Icon(
                      Icons.light_mode_outlined,
                      size: 20,
                      color: ThemeColors.primary(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Light',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: currentThemeMode == ThemeMode.light
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: ThemeColors.text(context),
                        ),
                      ),
                    ),
                    if (currentThemeMode == ThemeMode.light)
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: ThemeColors.primary(context),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Dark',
                child: Row(
                  children: [
                    Icon(
                      Icons.dark_mode_outlined,
                      size: 20,
                      color: ThemeColors.primary(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dark',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: currentThemeMode == ThemeMode.dark
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: ThemeColors.text(context),
                        ),
                      ),
                    ),
                    if (currentThemeMode == ThemeMode.dark)
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: ThemeColors.primary(context),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'System',
                child: Row(
                  children: [
                    Icon(
                      Icons.brightness_auto_outlined,
                      size: 20,
                      color: ThemeColors.primary(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'System',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: currentThemeMode == ThemeMode.system
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: ThemeColors.text(context),
                        ),
                      ),
                    ),
                    if (currentThemeMode == ThemeMode.system)
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: ThemeColors.primary(context),
                      ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeColors.card(context),
                border: Border.all(
                  color: ThemeColors.border(context),
                  width: 1.5,
                ),
                boxShadow: ThemeColors.shadowMd(context),
              ),
              child: Icon(
                _getThemeIcon(currentThemeMode),
                color: ThemeColors.primary(context),
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}