import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/theme_colors.dart';
import '../../services/theme_service.dart';
import '../../utils/responsive.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
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

            child:Responsive.isPhone(context)
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(context),

                SizedBox(
                  height: Responsive.isPhone(context) ? 20 : 32,
                ),

                _buildLoginCard(context),
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
                  child: _buildLoginCard(context),
                ),
              ],
            )

          ),
        ),
      ),
    );
  }
Widget _buildHeroSection(BuildContext context) {
  // LEFT SIDE
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

          SizedBox(
            height: Responsive.sectionSpacing(context) / 2,
          ),

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

          Container(
            padding: EdgeInsets.all(
              Responsive.isPhone(context)
                  ? Responsive.cardPadding(context) * 0.75
                  : Responsive.cardPadding(context),
            ),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                Responsive.cardRadius(context),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Row(
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
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                Text(
                  'Advanced smile symmetry, facial alignment, and orthodontic evaluation.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    height: 1.6,
                    color: ThemeColors.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
}
Widget _buildLoginCard(BuildContext context) {
  // RIGHT SIDE LOGIN CARD
  return Center(
      child: Container(
        width: Responsive.isPhone(context)
            ? double.infinity
            : 420,

        padding: EdgeInsets.all(
          Responsive.cardPadding(context),
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.cardRadius(context),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              'Welcome Back',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: Responsive.isPhone(context) ? 26 : 30,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Login to continue your clinical smile analysis workflow.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),

            SizedBox(
              height: Responsive.sectionSpacing(context),
            ),

            // EMAIL
            Text(
              'Email',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _emailController,
              style: const TextStyle(
                color: Colors.white,
              ),

              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                ),

                filled: true,
                fillColor: const Color(0xFF273449),

                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.cardRadius(context),
                  ),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.cardRadius(context),
                  ),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // PASSWORD
            Text(
              'Password',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,

              style: TextStyle(
                color: Colors.white,

              ),


              decoration: InputDecoration(

                hintText: 'Enter your password',
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                ),

                filled: true,
                fillColor: const Color(0xFF273449),

                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.cardRadius(context),
                  ),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius:BorderRadius.circular(
                    Responsive.cardRadius(context),
                  ),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 34),

            // LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: Responsive.buttonHeight(context),

              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF2563EB),

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      Responsive.cardRadius(context),
                    ),
                  ),
                ),

                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    Text(
                      'Logging in...',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Login',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/forgot-password',
                  );
                },

                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [

                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color:const Color(0xFF64748B),
                    fontFamily: 'Inter',
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}
}

