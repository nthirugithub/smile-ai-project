import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/verify_otp_card.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/auth_hero.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animationController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleResendOtp(String email) async {
    final result = await ApiService.forgotPassword(email: email);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new OTP has been sent to your email.'),
          duration: Duration(seconds: 2),
        ),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to resend OTP'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
        ),
      );
      return;
    }

    final email = ModalRoute.of(context)!.settings.arguments as String;

    final result = await ApiService.verifyOtp(
      email: email,
      otp: _otpController.text.trim(),
    );
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: email,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] ?? 'Invalid OTP code',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)!.settings.arguments as String;

    return AuthLayout(
      hero: const AuthHero(),
      animationController: _animationController,
      child: VerifyOtpCard(
        email: email,
        otpController: _otpController,
        onVerifyOtp: _handleVerifyOtp,
        resendCountdown: _countdown,
        onResendOtp: () => _handleResendOtp(email),
      ),
    );
  }
}

