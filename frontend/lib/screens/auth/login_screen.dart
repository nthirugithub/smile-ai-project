import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/auth_hero.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/login_card.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late final AnimationController _animationController;
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animationController.forward();
  }
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {


      try {
        await SessionService.saveUser(
          userId: result['user_id'] ?? 0,
          name: result['name'] ?? '',
          email: result['email'] ?? '',
          accessToken: result['access_token'] ?? '',
        );
        final token = await SessionService.getAccessToken();
        print("SAVED TOKEN: $token");

        final settingsResponse = await ApiService.getSettings(
          result['user_id'],
        );

        if (settingsResponse['success']) {
          await ThemeService.instance.setTheme(
            settingsResponse['settings']['theme'],
          );
        }

      } catch (e) {
        print('SESSION ERROR: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful'),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] ?? 'Login Failed',
          ),
        ),
      );
    }
  }
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return AuthLayout(
      hero: const AuthHero(),
      animationController: _animationController,
      child: LoginCard(
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        isLoading: _isLoading,
        onLogin: _handleLogin,
        onTogglePassword: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }
}

