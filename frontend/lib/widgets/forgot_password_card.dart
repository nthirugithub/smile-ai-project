import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import 'custom_text_field.dart';
import 'primary_button.dart';
import '../utils/responsive.dart';

class ForgotPasswordCard extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onSendOtp;

  const ForgotPasswordCard({
    super.key,
    required this.emailController,
    required this.onSendOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: Responsive.isPhone(context) ? double.infinity : 440,
        padding: EdgeInsets.all(Responsive.cardPadding(context)),
        decoration: BoxDecoration(
          color: ThemeColors.card(context),
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: ThemeColors.border(context)),
          boxShadow: ThemeColors.shadowMd(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forgot Password',
              style: AppTypography.pageTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your registered email address to receive a 6-digit verification code.',
              style: AppTypography.body(context).copyWith(
                color: ThemeColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 28),
            CustomTextField(
              label: 'Email Address',
              controller: emailController,
              hintText: 'name@clinic.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSendOtp(),
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Send Verification Code',
              onPressed: onSendOtp,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remember your password? ',
                  style: TextStyle(
                    color: ThemeColors.secondaryText(context),
                    fontFamily: 'Inter',
                    fontSize: 14,
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
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: ThemeColors.primary(context),
                      fontFamily: 'Inter',
                      fontSize: 14,
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