import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/cases/cases_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/help/help_screen.dart';
import 'services/theme_service.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/verify_otp_screen.dart';
import 'screens/auth/reset_password_screen.dart';
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService.instance.loadTheme();

  runApp(const MyApp());

}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {

  final ThemeService themeService =
      ThemeService.instance;

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(

      animation: themeService,

      builder: (context, child) {

        return MaterialApp(
      title: 'Smile Analysis AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
      initialRoute: '/auth', // Default starting screen
      routes: {
        '/auth': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/verify-otp': (context) => const VerifyOtpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/cases': (context) => const CasesScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/reports': (context) {

          final args =
          ModalRoute.of(context)
              ?.settings.arguments
          as Map<String, dynamic>?;

          return ReportsScreen(
            analysisData: args,
          );
        },
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  },
  );
}
}
