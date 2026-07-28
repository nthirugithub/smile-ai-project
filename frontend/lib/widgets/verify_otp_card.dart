import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import 'custom_text_field.dart';
import '../utils/responsive.dart';
import 'primary_button.dart';

class VerifyOtpCard extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final VoidCallback onVerifyOtp;

  const VerifyOtpCard({
    super.key,
    required this.email,
    required this.otpController,
    required this.onVerifyOtp,
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
              'Verify OTP',
              style: AppTypography.pageTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit verification code sent to your email.',
              style: AppTypography.body(context).copyWith(
                color: ThemeColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              email,
              style: TextStyle(
                color: ThemeColors.primary(context),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Verification Code',
              controller: otpController,
              hintText: '123456',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              onSubmitted: (_) => onVerifyOtp(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Verify OTP',
              onPressed: onVerifyOtp,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: ThemeColors.primary(context),
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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