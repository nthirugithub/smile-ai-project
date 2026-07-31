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
    this.rememberMe = true,
    this.onToggleRememberMe,
    this.onGoogleSignIn,
    this.enableGoogleSignIn = false,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onTogglePassword;
  final bool rememberMe;
  final ValueChanged<bool?>? onToggleRememberMe;
  final VoidCallback? onGoogleSignIn;
  final bool enableGoogleSignIn;


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
              key: const ValueKey('email_input_key'),
              label: 'Email Address',
              controller: emailController,
              hintText: 'name@clinic.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              key: const ValueKey('password_input_key'),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: onToggleRememberMe,
                      activeColor: ThemeColors.primary(context),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(
                      'Remember Me',
                      style: TextStyle(
                        color: ThemeColors.secondaryText(context),
                        fontFamily: 'Inter',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: ThemeColors.primary(context),
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              key: const ValueKey('login_button_key'),
              label: 'Sign In',
              loadingLabel: 'Signing in...',
              isLoading: isLoading,
              onPressed: onLogin,
            ),
            if (enableGoogleSignIn && onGoogleSignIn != null) ...[

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: ThemeColors.border(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: ThemeColors.secondaryText(context),
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: ThemeColors.border(context))),
                ],
              ),
              const SizedBox(height: 16),
              BrandedGoogleSignInButton(
                key: const ValueKey('google_signin_button_key'),
                onPressed: isLoading ? null : onGoogleSignIn,
                isLoading: isLoading,
              ),
            ],

            const SizedBox(height: 16),
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
                    Navigator.pushReplacementNamed(context, '/register');
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

class BrandedGoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const BrandedGoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<BrandedGoogleSignInButton> createState() => _BrandedGoogleSignInButtonState();
}

class _BrandedGoogleSignInButtonState extends State<BrandedGoogleSignInButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFDADCE0);
    Color textColor = const Color(0xFF3C4043);

    if (!enabled) {
      bgColor = const Color(0xFFF8F9FA);
      borderColor = const Color(0xFFF1F3F4);
      textColor = const Color(0xFF3C4043).withValues(alpha: 0.4);
    } else if (_isHovered) {
      bgColor = const Color(0xFFF8F9FA);
      borderColor = const Color(0xFFD2E3FC);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Continue with Google',
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused ? const Color(0xFF1A73E8) : borderColor,
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: _isHovered && enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),

            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: enabled ? widget.onPressed : null,
                splashColor: const Color(0xFFE8F0FE),
                highlightColor: const Color(0xFFF1F3F4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        Opacity(
                          opacity: enabled ? 1.0 : 0.4,
                          child: const GoogleLogoWidget(size: 18),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // Blue Path
    final Path bluePath = Path()
      ..moveTo(23.49, 12.27)
      ..cubicTo(23.49, 11.48, 23.42, 10.73, 23.3, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.51)
      ..lineTo(18.47, 14.51)
      ..cubicTo(18.18, 15.99, 17.34, 17.25, 16.08, 18.1)
      ..lineTo(16.08, 21.1)
      ..lineTo(19.94, 21.1)
      ..cubicTo(22.2, 19.01, 23.49, 15.92, 23.49, 12.27)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    // Green Path
    final Path greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 19.94, 21.1)
      ..lineTo(16.08, 18.1)
      ..cubicTo(15.01, 18.82, 13.62, 19.24, 12.0, 19.24)
      ..cubicTo(8.87, 19.24, 6.22, 17.13, 5.27, 14.29)
      ..lineTo(1.29, 14.29)
      ..lineTo(1.29, 17.38)
      ..cubicTo(3.27, 21.31, 7.33, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    // Yellow Path
    final Path yellowPath = Path()
      ..moveTo(5.27, 14.29)
      ..cubicTo(5.03, 13.57, 4.89, 12.8, 4.89, 12.0)
      ..cubicTo(4.89, 11.2, 5.03, 10.43, 5.27, 9.71)
      ..lineTo(5.27, 6.62)
      ..lineTo(1.29, 6.62)
      ..cubicTo(0.47, 8.24, 0.0, 10.06, 0.0, 12.0)
      ..cubicTo(0.0, 13.94, 0.47, 15.76, 1.29, 17.38)
      ..lineTo(5.27, 14.29)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // Red Path
    final Path redPath = Path()
      ..moveTo(12.0, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.6, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.33, 0.0, 3.27, 2.69, 1.29, 6.62)
      ..lineTo(5.27, 9.71)
      ..cubicTo(6.22, 6.87, 8.87, 4.75, 12.0, 4.75)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}