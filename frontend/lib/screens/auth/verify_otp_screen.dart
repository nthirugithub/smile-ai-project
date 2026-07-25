import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/theme_colors.dart';
import '../../utils/responsive.dart';
import 'package:flutter/services.dart';
class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() =>
      _VerifyOtpScreenState();
}

class _VerifyOtpScreenState
    extends State<VerifyOtpScreen> {
  final TextEditingController _otpController =
  TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
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

    final email =
    ModalRoute.of(context)!.settings.arguments
    as String;

    final result =
    await ApiService.verifyOtp(
      email: email,
      otp: _otpController.text.trim(),
    );
    if (!mounted) return;

    if (result['success']) {

      Navigator.pushNamed(

        context,

        '/reset-password',

        arguments: email,

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

                _buildVerifyOtpCard(context),
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
                  child: _buildVerifyOtpCard(context),
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
Widget _buildVerifyOtpCard(BuildContext context) {
  final email =
  ModalRoute.of(context)!.settings.arguments as String;
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
              'Verify OTP',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: Responsive.isPhone(context) ? 26 : 30,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Enter the 6-digit verification code sent to your email.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),

            SelectableText(
              email,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            // EMAIL
            Text(
              'Verification Code',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(
                color: Colors.white,
              ),

              decoration: InputDecoration(
                hintText: 'Enter 6-digit OTP',
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                ),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF273449),

                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),

                border: OutlineInputBorder(
                  borderRadius:BorderRadius.circular(
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

            // LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: Responsive.buttonHeight(context),

              child: ElevatedButton(
                onPressed: _handleVerifyOtp,

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
                  'Verify OTP',
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
                  Navigator.pop(context);
                },

                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
}

