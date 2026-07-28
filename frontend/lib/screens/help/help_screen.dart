import 'package:flutter/material.dart';
import '../../widgets/app_shell.dart';
import '../../services/session_service.dart';
import '../../theme/theme_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon_container.dart';
import '../../utils/responsive.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String userName = 'User';
  String userEmail = '';

  final List<Map<String, dynamic>> faqList = [
    {
      "question": "How does AI smile analysis work?",
      "answer": "The AI engine detects facial landmarks and evaluates smile symmetry, lip curvature, dental midline, and facial proportions."
    },
    {
      "question": "Which image formats are supported?",
      "answer": "JPG and PNG images are supported with a maximum file size of 10MB."
    },
    {
      "question": "Can I export reports as PDF?",
      "answer": "Yes. Reports can be exported as professional clinical PDF documents."
    },
    {
      "question": "Is patient data stored securely?",
      "answer": "Yes. All patient records and AI analysis data are securely protected."
    },
    {
      "question": "How accurate is the AI engine?",
      "answer": "The current AI smile symmetry model provides approximately 94% average accuracy."
    },
  ];

  Future<void> loadUserData() async {
    final name = await SessionService.getName();
    final email = await SessionService.getEmail();
    setState(() {
      userName = name;
      userEmail = email;
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return AppShell(
      currentRoute: '/help',
      title: 'Help & Knowledge Center',
      userName: userName,
      userEmail: userEmail,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            AppCard(
              padding: EdgeInsets.all(isPhone ? 16 : 20),
              color: ThemeColors.primaryContainer(context),
              border: BorderSide(color: ThemeColors.primary(context).withValues(alpha: 0.2)),
              child: isPhone
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help & Technical Support',
                          style: AppTypography.pageTitle(context).copyWith(
                            color: ThemeColors.onPrimaryContainer(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get assistance with SmileSync AI clinical diagnostics, landmark detection, and PDF exports.',
                          style: AppTypography.body(context).copyWith(
                            color: ThemeColors.secondaryText(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const AppChip(
                          label: 'Support Active',
                          icon: Icons.check_circle_outline,
                          variant: AppChipVariant.success,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Help & Technical Support',
                                style: AppTypography.pageTitle(context).copyWith(
                                  color: ThemeColors.onPrimaryContainer(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Get assistance with SmileSync AI clinical diagnostics, landmark detection, and PDF exports.',
                                style: AppTypography.body(context).copyWith(
                                  color: ThemeColors.secondaryText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const AppChip(
                          label: 'Support Active',
                          icon: Icons.check_circle_outline,
                          variant: AppChipVariant.success,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Quick Help Cards
            isPhone
                ? Column(
                    children: [
                      _buildGuideCard(
                        Icons.cloud_upload_outlined,
                        'Image Capture Guide',
                        'Learn image requirements for highest AI accuracy.',
                      ),
                      const SizedBox(height: 12),
                      _buildGuideCard(
                        Icons.analytics_outlined,
                        'Interpreting Metrics',
                        'Detailed breakdown of symmetry and facial ratio metrics.',
                      ),
                      const SizedBox(height: 12),
                      _buildGuideCard(
                        Icons.picture_as_pdf_outlined,
                        'Exporting Reports',
                        'Guide on generating clinical PDF summaries for patients.',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildGuideCard(
                          Icons.cloud_upload_outlined,
                          'Image Capture Guide',
                          'Learn image requirements for highest AI accuracy.',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGuideCard(
                          Icons.analytics_outlined,
                          'Interpreting Metrics',
                          'Detailed breakdown of symmetry and facial ratio metrics.',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGuideCard(
                          Icons.picture_as_pdf_outlined,
                          'Exporting Reports',
                          'Guide on generating clinical PDF summaries for patients.',
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 32),

            // FAQ Section
            Text('Frequently Asked Questions', style: AppTypography.sectionTitle(context)),
            const SizedBox(height: 16),

            ...faqList.map((faq) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 14 : 20,
                    vertical: isPhone ? 10 : 16,
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Text(
                      faq["question"]!,
                      style: AppTypography.cardTitle(context),
                    ),
                    children: [
                      Text(
                        faq["answer"]!,
                        style: AppTypography.body(context).copyWith(
                          color: ThemeColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard(IconData icon, String title, String subtitle) {
    final isPhone = Responsive.isPhone(context);

    return AppCard(
      padding: EdgeInsets.all(isPhone ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconContainer(icon: icon, size: isPhone ? AppIconSize.sm : AppIconSize.md),
          SizedBox(height: isPhone ? 10 : 14),
          Text(title, style: AppTypography.cardTitle(context)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.caption(context)),
        ],
      ),
    );
  }
}