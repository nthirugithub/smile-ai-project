import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/forgot_password_card.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/auth_hero.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
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

  Future<void> _handleSendOtp() async {
    final result = await ApiService.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result['success']) {
      Navigator.pushNamed(
        context,
        '/verify-otp',
        arguments: _emailController.text.trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] ?? 'Failed to send OTP.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forgotPasswordCard = ForgotPasswordCard(
      emailController: _emailController,
      onSendOtp: _handleSendOtp,
    );

    return AuthLayout(
      hero: const AuthHero(),
      animationController: _animationController,
      child: forgotPasswordCard,
    );
  }
}
