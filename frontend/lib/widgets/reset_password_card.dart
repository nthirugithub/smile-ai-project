import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../utils/responsive.dart';
import '../widgets/primary_button.dart';

class ResetPasswordCard extends StatelessWidget {
  final String email;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onResetPassword;

  const ResetPasswordCard({
    super.key,
    required this.email,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onResetPassword,
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
              'Reset Password',
              style: AppTypography.pageTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new secure password for your account.',
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
              label: 'New Password',
              controller: newPasswordController,
              hintText: 'Enter new password',
              obscureText: obscureNewPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                icon: Icon(
                  obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ThemeColors.secondaryText(context),
                  size: 20,
                ),
                onPressed: onToggleNewPassword,
              ),
            ),
            const SizedBox(height: 18),
            CustomTextField(
              label: 'Confirm Password',
              controller: confirmPasswordController,
              hintText: 'Confirm new password',
              obscureText: obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onResetPassword(),
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ThemeColors.secondaryText(context),
                  size: 20,
                ),
                onPressed: onToggleConfirmPassword,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Reset Password',
              onPressed: onResetPassword,
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