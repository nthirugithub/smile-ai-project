import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../utils/responsive.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

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
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
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
                _buildHeroSection(context),
                SizedBox(
                  height: Responsive.isPhone(context) ? 20 : 32,
                ),
                _buildRegisterCard(context),
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildHeroSection(context),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: _buildRegisterCard(context),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }
Widget _buildHeroSection(BuildContext context) {
  return Padding(
    padding: EdgeInsets.only(
      right: Responsive.isPhone(context) ? 0 : 60,
      bottom: Responsive.isPhone(context) ? 32 : 0,
    ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Smile Analysis',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: Responsive.isPhone(context) ? 36 : 52,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Clinical Smile Analysis & Facial Symmetry Evaluation',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: Responsive.isPhone(context) ? 16 : 18,
              height: 1.7,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(
            height: Responsive.isPhone(context)
                ? Responsive.sectionSpacing(context) * 0.55
                : Responsive.sectionSpacing(context),
          ),
          AppCard(
            padding: EdgeInsets.all(
              Responsive.isPhone(context)
                  ? Responsive.cardPadding(context) * 0.75
                  : Responsive.cardPadding(context),
            ),
            borderRadius: Responsive.cardRadius(context),
            elevation: 0,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'AI Powered Analysis',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Advanced smile symmetry, facial alignment, and orthodontic evaluation.',
                  style:
                  TextStyle(
                    fontFamily: 'Inter',
                    height: 1.6,
                    color: Color(0xFF616161), // Grey 700
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
}
Widget _buildRegisterCard(BuildContext context) {
  return Center(
      child: AppCard(
        width: Responsive.isPhone(context)
            ? double.infinity
            : 420,
        padding: EdgeInsets.all(
          Responsive.cardPadding(context),
        ),
        borderRadius: Responsive.cardRadius(context),
        elevation: 0,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Create Account',
              subtitle:
              'Register to start your clinical smile analysis workflow.',
              spacing: 10,
            ),
            SizedBox(
              height: Responsive.sectionSpacing(context) * 0.6,
            ),
            CustomTextField(
              label: 'Full Name',
              controller: _nameController,
              hintText: 'Enter your full name',
              textInputAction: TextInputAction.next,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Email',
              controller: _emailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() => _emailError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Password',
              controller: _passwordController,
              hintText: 'Enter your password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              errorText: _passwordError,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Confirm Password',
              controller: _confirmController,
              hintText: 'Re-enter your password',
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              errorText: _confirmError,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword =
                    !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              onSubmitted: (_) => _handleRegister(),
              onChanged: (_) {
                if (_confirmError != null) {
                  setState(() => _confirmError = null);
                }
              },
            ),
            const SizedBox(height: 34),
            PrimaryButton(
              label: 'Register',
              height: Responsive.buttonHeight(context),
              onPressed: _handleRegister,
            ),
            SizedBox(
              height: Responsive.sectionSpacing(context),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'Inter',
                  ),
                ),
                TextButton(
                  onPressed: _goToLogin,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
}
}
