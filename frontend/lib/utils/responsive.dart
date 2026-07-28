import 'package:flutter/material.dart';

class Responsive {
  static const double phone = 700;
  static const double desktop = 1000;

  static Size size(BuildContext context) =>
      MediaQuery.of(context).size;

  static double width(BuildContext context) =>
      size(context).width;

  static double height(BuildContext context) =>
      size(context).height;

  static bool isPhone(BuildContext context) =>
      width(context) < phone;

  static bool isTablet(BuildContext context) =>
      width(context) >= phone &&
          width(context) < desktop;

  static bool isDesktop(BuildContext context) =>
      width(context) >= desktop;

  // ---------- Spacing ----------

  static double pagePadding(BuildContext context) {
    if (isPhone(context)) return 16;
    if (isTablet(context)) return 20;
    return 30;
  }

  static double sectionSpacing(BuildContext context) {
    return isPhone(context) ? 20 : 34;
  }

  static double cardPadding(BuildContext context) {
    return isPhone(context) ? 16 : 26;
  }

  // ---------- Fonts ----------

  static double titleFont(BuildContext context) {
    return isPhone(context) ? 22 : 26;
  }

  static double headingFont(BuildContext context) {
    return isPhone(context) ? 18 : 20;
  }

  static double bodyFont(BuildContext context) {
    return isPhone(context) ? 13.5 : 14;
  }

  // ---------- Dashboard ----------

  static int dashboardColumns(BuildContext context) {
    if (isPhone(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
  // ---------- Radius ----------

  static double cardRadius(BuildContext context) {
    return isPhone(context) ? 16 : 24;
  }

// ---------- Button ----------

  static double buttonHeight(BuildContext context) {
    return isPhone(context) ? 46 : 56;
  }
// ---------- Welcome Card ----------

  static double welcomePadding(BuildContext context) {
    return isPhone(context) ? 18 : 32;
  }

// ---------- Stat Card ----------

  static double statValueFont(BuildContext context) {
    return isPhone(context) ? 24 : 32;
  }

  static double statTitleFont(BuildContext context) {
    return isPhone(context) ? 13 : 15;
  }
  // ---------- AppShell ----------

  static double sidebarWidth(BuildContext context) {
    final w = width(context);

    if (w < phone) return 0;          // Drawer
    if (w < desktop) return 220;      // Tablet
    if (w < 1400) return 250;         // Normal Desktop
    return 280;                       // Large Desktop
  }

  static double topBarHeight(BuildContext context) {
    return isPhone(context) ? 70 : 80;
  }

  static double searchWidth(BuildContext context) {
    final w = width(context);

    if (isPhone(context)) return w - 90;
    if (w < desktop) return 220;
    if (w < 1300) return 260;
    if (w < 1600) return 320;

    return 380;
  }

  static double profileAvatarRadius(BuildContext context) {
    return isPhone(context) ? 20 : 22;
  }

  static double appTitleFont(BuildContext context) {
    return isPhone(context) ? 22 : 28;
  }

  static double sidebarIconSize(BuildContext context) {
    return isPhone(context) ? 22 : 24;
  }

  static double sidebarFont(BuildContext context) {
    return isPhone(context) ? 14 : 15;
  }

  static double shellPadding(BuildContext context) {
    return isPhone(context) ? 8 : (isTablet(context) ? 14 : 20);
  }

  static double shellInnerPadding(BuildContext context) {
    return isPhone(context) ? 16 : (isTablet(context) ? 22 : 32);
  }

  static double maxDialogWidth(BuildContext context, {double defaultMaxWidth = 450}) {
    final w = width(context);
    return (w * 0.92).clamp(280.0, defaultMaxWidth);
  }

  static double bottomPagePadding(BuildContext context) {
    return pagePadding(context) +
        MediaQuery.of(context).padding.bottom;
  }

  static EdgeInsets pageInsets(BuildContext context) {
    return EdgeInsets.fromLTRB(
      pagePadding(context),
      pagePadding(context),
      pagePadding(context),
      bottomPagePadding(context),
    );
  }

}

