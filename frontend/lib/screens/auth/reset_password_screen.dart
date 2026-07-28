import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/reset_password_card.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/auth_hero.dart';
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final TextEditingController _newPasswordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animationController.forward();
  }
  @override
  void dispose() {
    _animationController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  Future<void> _handleResetPassword() async {

    final email =
    ModalRoute.of(context)!.settings.arguments
    as String;

    if (_newPasswordController.text !=
        _confirmPasswordController.text) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            'Passwords do not match',
          ),
        ),

      );

      return;
    }

    final result =
    await ApiService.resetPassword(

      email: email,

      newPassword:
      _newPasswordController.text.trim(),

    );

    if (!mounted) return;

    if (result['success']) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            result['message'],
          ),
        ),

      );

      Navigator.pushNamedAndRemoveUntil(

        context,

        '/auth',

            (route) => false,

      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            result['error'],
          ),
        ),

      );

    }

  }


  @override
  Widget build(BuildContext context) {
    final email =
    ModalRoute.of(context)!.settings.arguments as String;

    return AuthLayout(
      hero: const AuthHero(),
      animationController: _animationController,
      child: ResetPasswordCard(
        email: email,
        newPasswordController: _newPasswordController,
        confirmPasswordController: _confirmPasswordController,
        obscureNewPassword: _obscureNewPassword,
        obscureConfirmPassword: _obscureConfirmPassword,
        onToggleNewPassword: () {
          setState(() {
            _obscureNewPassword = !_obscureNewPassword;
          });
        },
        onToggleConfirmPassword: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
        onResetPassword: _handleResetPassword,
      ),
    );
  }
}

