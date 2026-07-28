import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/register_card.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/auth_hero.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final AnimationController _animationController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmError;

    if (name.isEmpty) {
      nameError = 'Full name is required';
    } else if (name.length < 2) {
      nameError = 'Full name must be at least 2 characters';
    }

    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!_emailRegex.hasMatch(email)) {
      emailError = 'Enter a valid email address';
    }

    if (password.isEmpty) {
      passwordError = 'Password is required';
    } else if (password.length < 8) {
      passwordError = 'Password must be at least 8 characters';
    }

    if (confirm.isEmpty) {
      confirmError = 'Please confirm your password';
    } else if (confirm != password) {
      confirmError = 'Passwords do not match';
    }

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });

    return nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmError == null;
  }
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animationController.forward();
  }

  Future<void> _handleRegister() async {

    _clearErrors();

    if (!_validate()) {
      return;
    }

    final result =
    await ApiService.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Registration Successful'),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/auth',
      );

    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result['error'] ??
                'Registration Failed',
          ),
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    final registerCard = RegisterCard(
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      confirmController: _confirmController,

      nameError: _nameError,
      emailError: _emailError,
      passwordError: _passwordError,
      confirmError: _confirmError,

      obscurePassword: _obscurePassword,
      obscureConfirmPassword: _obscureConfirmPassword,

      onRegister: _handleRegister,
      onGoToLogin: _goToLogin,

      onTogglePassword: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },

      onToggleConfirmPassword: () {
        setState(() {
          _obscureConfirmPassword = !_obscureConfirmPassword;
        });
      },

      onNameChanged: (_) {
        if (_nameError != null) {
          setState(() => _nameError = null);
        }
      },

      onEmailChanged: (_) {
        if (_emailError != null) {
          setState(() => _emailError = null);
        }
      },

      onPasswordChanged: (_) {
        if (_passwordError != null) {
          setState(() => _passwordError = null);
        }
      },

      onConfirmChanged: (_) {
        if (_confirmError != null) {
          setState(() => _confirmError = null);
        }
      },
    );

    return AuthLayout(
      hero: const AuthHero(),
      animationController: _animationController,
      child: registerCard,
    );
  }
}
