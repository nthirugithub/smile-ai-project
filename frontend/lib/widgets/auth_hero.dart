import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'app_icon_container.dart';

class AuthHero extends StatelessWidget {
  const AuthHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: Responsive.isPhone(context) ? 0 : 40,
        bottom: Responsive.isPhone(context) ? 24 : 0,
      ),
      child: Column(
        crossAxisAlignment: Responsive.isPhone(context)
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconContainer(
                icon: Icons.health_and_safety_outlined,
                size: AppIconSize.lg,
                color: ThemeColors.primary(context),
                backgroundColor: ThemeColors.primaryContainer(context),
              ),
              const SizedBox(width: 14),
              Text(
                'SmileSync AI',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: Responsive.isPhone(context) ? 28 : 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: ThemeColors.text(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (!Responsive.isPhone(context)) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enterprise Medical AI\nClinical Smile Analysis',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: ThemeColors.text(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Generate standardized, AI-assisted smile assessments with structured clinical reporting and diagnostic workflows.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: ThemeColors.secondaryText(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Container(
              padding: EdgeInsets.all(Responsive.cardPadding(context)),
              decoration: BoxDecoration(
                color: ThemeColors.card(context),
                border: Border.all(
                  color: ThemeColors.border(context),
                  width: 1,
                ),
                borderRadius: AppRadius.borderLg,
                boxShadow: ThemeColors.shadowSm(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: ThemeColors.primary(context),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Clinical AI Diagnostic Suite',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ThemeColors.text(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Consistent AI-assisted smile analysis with high-accuracy landmark measurement and automated report generation.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.6,
                      color: ThemeColors.secondaryText(context),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: ThemeColors.border(context),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: ThemeColors.success(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Built for HIPAA-compliant clinical environments.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ThemeColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}