import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onLogin,
    required this.onTogglePassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onTogglePassword;

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
              'Welcome Back',
              style: AppTypography.pageTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access clinical smile analysis & patient records.',
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Password',
              controller: passwordController,
              hintText: 'Enter your password',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onLogin(),
              autofillHints: const [AutofillHints.password],
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ThemeColors.secondaryText(context),
                  size: 20,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Sign In',
              loadingLabel: 'Signing in...',
              isLoading: isLoading,
              onPressed: onLogin,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: ThemeColors.primary(context),
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: ThemeColors.secondaryText(context),
                    fontFamily: 'Inter',
                    fontSize: 14,
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
                  child: Text(
                    'Sign Up',
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