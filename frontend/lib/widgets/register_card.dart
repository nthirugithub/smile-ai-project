import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_card.dart';
import 'custom_text_field.dart';
import 'primary_button.dart';

class RegisterCard extends StatelessWidget {
  const RegisterCard({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.nameError,
    required this.emailError,
    required this.passwordError,
    required this.confirmError,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onRegister,
    required this.onGoToLogin,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onConfirmChanged,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;

  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmError;

  final bool obscurePassword;
  final bool obscureConfirmPassword;

  final VoidCallback onRegister;
  final VoidCallback onGoToLogin;

  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        width: Responsive.isPhone(context) ? double.infinity : 440,
        padding: EdgeInsets.all(Responsive.cardPadding(context)),
        borderRadius: AppRadius.lg,
        color: ThemeColors.card(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Account',
              style: AppTypography.pageTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Register to start your clinical smile analysis workflow.',
              style: AppTypography.body(context).copyWith(
                color: ThemeColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Full Name',
              controller: nameController,
              hintText: 'Dr. Jane Doe',
              textInputAction: TextInputAction.next,
              errorText: nameError,
              onChanged: onNameChanged,
            ),
            const SizedBox(height: 18),
            CustomTextField(
              label: 'Email Address',
              controller: emailController,
              hintText: 'name@clinic.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: emailError,
              onChanged: onEmailChanged,
            ),
            const SizedBox(height: 18),
            CustomTextField(
              label: 'Password',
              controller: passwordController,
              hintText: 'Enter your password',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.next,
              errorText: passwordError,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ThemeColors.secondaryText(context),
                  size: 20,
                ),
              ),
              onChanged: onPasswordChanged,
            ),
            const SizedBox(height: 18),
            CustomTextField(
              label: 'Confirm Password',
              controller: confirmController,
              hintText: 'Re-enter your password',
              obscureText: obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              errorText: confirmError,
              suffixIcon: IconButton(
                onPressed: onToggleConfirmPassword,
                icon: Icon(
                  obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ThemeColors.secondaryText(context),
                  size: 20,
                ),
              ),
              onSubmitted: (_) => onRegister(),
              onChanged: onConfirmChanged,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Create Account',
              onPressed: onRegister,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: ThemeColors.secondaryText(context),
                    fontFamily: 'Inter',
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: onGoToLogin,
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