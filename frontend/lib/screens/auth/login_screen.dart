import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    debugPrint('[FLUTTER_E2E_LOG] _handleLogin triggered. Email: "$email"');

    if (email.isEmpty || password.isEmpty) {
      debugPrint('[FLUTTER_E2E_LOG] Empty credentials check failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        // RC-4: Short explicit duration so the ModalBarrier clears quickly.
        // The beforeEach in auth.spec.js waits for this snackbar to disappear
        // before proceeding to the next test (goToSignUp). Without this fix,
        // the 4-second default ModalBarrier blocked the Sign Up tap.
        const SnackBar(
          content: Text('Please enter an email address'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.loginUser(
      email: email,
      password: password,
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

        // DEF-005: Check mounted after each await to avoid setState on disposed widget
        if (!mounted) return;

        final settingsResponse = await ApiService.getSettings(
          result['user_id'],
        );

        if (!mounted) return;

        if (settingsResponse['success'] == true) {
          await ThemeService.instance.setTheme(
            settingsResponse['settings']['theme'],
          );
        }
      } catch (e) {
        debugPrint('[FLUTTER_E2E_LOG] SESSION ERROR: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful'),
          duration: Duration(seconds: 2),
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
            result['error'] ?? 'Invalid credentials provided. Access denied.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  bool _rememberMe = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

      if (googleAccount == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to obtain Google authentication token. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final result = await ApiService.googleAuth(
        idToken: idToken,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (_rememberMe) {
          await SessionService.saveUser(
            userId: result['user_id'] ?? 0,
            name: result['name'] ?? '',
            email: result['email'] ?? '',
            accessToken: result['access_token'] ?? '',
            profileImage: result['profile_image'] ?? '',
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In Successful'),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Google Sign-In failed'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on UnimplementedError {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In is supported on Web and Android devices.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final String errorMsg = e.toString();
      if (errorMsg.contains('UnimplementedError') || errorMsg.contains('MissingPluginException')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In is supported on Web and Android devices.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In error: $errorMsg'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }



  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Feature Flag: Temporarily set to false until Google Cloud Console OAuth Client IDs are configured.
  /// Change to `enableGoogleSignIn = true;` to instantly restore the complete Google OAuth flow.
  static const bool enableGoogleSignIn = false;

  @override
  Widget build(BuildContext context) {
    debugPrint('[TRACE_LOG] Step 15: LoginScreen built / rendered');

    return AuthLayout(
      hero: const AuthHero(),
      animationController: _animationController,
      child: LoginCard(
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        isLoading: _isLoading,
        rememberMe: _rememberMe,
        enableGoogleSignIn: enableGoogleSignIn,
        onToggleRememberMe: (val) {
          setState(() {
            _rememberMe = val ?? true;
          });
        },
        onLogin: _handleLogin,
        onGoogleSignIn: _handleGoogleSignIn,
        onTogglePassword: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }

}

