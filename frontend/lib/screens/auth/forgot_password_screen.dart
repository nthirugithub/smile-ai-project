import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/theme_colors.dart';
import '../../utils/responsive.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  Future<void> _handleSendOtp() async {

    final result = await ApiService.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result['success']) {

      if (!mounted) return;

      Navigator.pushNamed(

        context,

        '/verify-otp',

        arguments: _emailController.text.trim(),

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),

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

                _buildForgotPasswordCard(context),
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
                  child: _buildForgotPasswordCard(context),
                ),
              ],
            ),
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
                        color: const Color(0xFF0F172A),
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
Widget _buildForgotPasswordCard(BuildContext context) {
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
              'Forgot Password',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: Responsive.isPhone(context) ? 26 : 30,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Enter your registered email address to receive a 6-digit verification code.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 40),

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

            const SizedBox(height: 24),

            // LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: Responsive.buttonHeight(context),

              child: ElevatedButton(
                onPressed: _handleSendOtp,

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

                child: Text(
                  'Send OTP',
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

            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [

                Text(
                  "Remember your password?",
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontFamily: 'Inter',
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Login",
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

