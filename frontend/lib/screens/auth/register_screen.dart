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
  // DEF-004: Loading guard prevents concurrent API calls / double-taps
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

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

  // DEF-001: Password minimum raised to 8 to match backend requirement
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
      // DEF-001 fix: backend requires >= 8 characters
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

  Future<void> _handleRegister() async {
    debugPrint('[TRACE_LOG] Step 1: Create Account button pressed / _handleRegister() entered');
    // DEF-004: Prevent re-entrant calls while request is in-flight
    if (_isLoading) {
      debugPrint('[TRACE_LOG] _handleRegister blocked: _isLoading is true');
      return;
    }

    _clearErrors();

    debugPrint('[TRACE_LOG] Step 2: Running form validation');
    if (!_validate()) {
      debugPrint('[TRACE_LOG] Form validation failed: nameError=$_nameError, emailError=$_emailError, passwordError=$_passwordError, confirmError=$_confirmError');
      return;
    }
    debugPrint('[TRACE_LOG] Form validation passed');

    setState(() {
      _isLoading = true;
    });

    debugPrint('[TRACE_LOG] Step 3 & 4: Calling ApiService.registerUser() for email "${_emailController.text.trim()}"');
    final result = await ApiService.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    debugPrint('[TRACE_LOG] Step 10 & 11: Received response from ApiService.registerUser(): $result');

    if (!mounted) {
      debugPrint('[TRACE_LOG] Widget unmounted after ApiService.registerUser() call');
      return;
    }

    debugPrint('[TRACE_LOG] Step 13: Resetting _isLoading = false');
    setState(() {
      _isLoading = false;
    });

    debugPrint('[TRACE_LOG] Step 12: Continuing _handleRegister() with success flag = ${result['success']}');

    if (result['success'] == true) {
      debugPrint('[TRACE_LOG] Step 14: Executing Navigator.pushReplacementNamed(context, "/auth") immediately');
      Navigator.pushReplacementNamed(context, '/auth');
      debugPrint('[TRACE_LOG] Step 14 complete: Navigator.pushReplacementNamed called');
    } else {
      debugPrint('[TRACE_LOG] Registration failed response: ${result['error']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'Registration Failed',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

      // DEF-004: Pass loading state to disable button during request
      isLoading: _isLoading,

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
