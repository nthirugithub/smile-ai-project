import 'package:flutter/material.dart';
import '../../widgets/app_shell.dart';
import '../../services/session_service.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/fade_slide.dart';
import '../../widgets/hover_card.dart';
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
      "answer":
      "The AI engine detects facial landmarks and evaluates smile symmetry, lip curvature, dental midline, and facial proportions."
    },
    {
      "question": "Which image formats are supported?",
      "answer":
      "JPG and PNG images are supported with a maximum file size of 10MB."
    },
    {
      "question": "Can I export reports as PDF?",
      "answer":
      "Yes. Reports can be exported as professional clinical PDF documents."
    },
    {
      "question": "Is patient data stored securely?",
      "answer":
      "Yes. All patient records and AI analysis data are securely protected."
    },
    {
      "question": "How accurate is the AI engine?",
      "answer":
      "The current AI smile symmetry model provides approximately 94% average accuracy."
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return AppShell(
      currentRoute: '/help',
      title: 'Help',
      userName: userName,
      userEmail: userEmail,

      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          Responsive.pagePadding(context),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // HERO SECTION

            FadeSlide(
              delay: Duration.zero,
              child: Container(
                padding: const EdgeInsets.all(32),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),

                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF3B82F6),
                    ],
                  ),
                ),

                child: isMobile
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        Text(
                          'Help & Support',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.titleFont(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 14),

                        Text(
                          'Get assistance with SmileSync AI analysis platform and clinical workflow support.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.bodyFont(context),
                            height: 1.6,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: Colors.green,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Support Online',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
                            'Help & Support',
                            style: TextStyle(
                              fontSize: Responsive.titleFont(context),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: 14),

                          Text(
                            'Get assistance with SmileSync AI analysis platform and clinical workflow support.',
                            style: TextStyle(
                              fontSize: Responsive.bodyFont(context),
                              height: 1.6,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: Colors.green,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Support Online',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),),),

            const SizedBox(height: 30),

            // QUICK HELP CARDS

            FadeSlide(
              delay: const Duration(milliseconds: 120),
              child:
              Wrap(
                spacing: 22,
                runSpacing: 22,

                children: [
                  _buildHelpCard(
                    Icons.upload_file,
                    'Upload Guide',
                    'Learn how to upload patient smile images properly.',
                  ),

                  _buildHelpCard(
                    Icons.analytics,
                    'AI Analysis',
                    'Understand AI-based smile symmetry evaluations.',
                  ),

                  _buildHelpCard(
                    Icons.picture_as_pdf,
                    'Report Export',
                    'Generate and export clinical PDF reports.',
                  ),

                  _buildHelpCard(
                    Icons.medical_services_outlined,
                    'Clinical Interpretation',
                    'Understand clinical smile analysis metrics.',
                  ),

                  _buildHelpCard(
                    Icons.security,
                    'Privacy & Security',
                    'Learn about patient data protection and storage.',
                  ),

                  _buildHelpCard(
                    Icons.settings,
                    'Account Support',
                    'Manage settings, password, and profile support.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 34),

            // FAQ SECTION

            FadeSlide(
              delay: const Duration(milliseconds: 240),
              child: _buildSectionCard(
                title: 'Frequently Asked Questions',

                child: Column(
                  children: faqList.map((faq) {
                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 16),

                      decoration: BoxDecoration(
                        color: ThemeColors.inputFill(context),
                        borderRadius:
                        BorderRadius.circular(18),
                      ),

                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),

                        collapsedShape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),

                        tilePadding:
                        const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),

                        title: Text(
                          faq['question'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ThemeColors.text(context),
                          ),
                        ),

                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              20,
                            ),

                            child: Text(
                              faq['answer'],
                              style: TextStyle(
                                height: 1.7,
                                color: ThemeColors.secondaryText(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),),

            const SizedBox(height: 30),

            // CONTACT + SYSTEM STATUS

            FadeSlide(
              delay: const Duration(milliseconds: 360),
              child:isMobile
                  ? Column(
                children: [
                  _buildContactCard(),
                  const SizedBox(height: 24),
                  _buildStatusCard(),
                ],
              )
                  : Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: _buildContactCard(),
                  ),

                  const SizedBox(width: 24),

                  Expanded(
                    child: _buildStatusCard(),
                  ),
                ],
              ),),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return SizedBox(
        width: Responsive.isPhone(context)
            ? double.infinity
            : 280,

        child: HoverCard(
          child: Container(
        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          color: ThemeColors.card(context),
          borderRadius: BorderRadius.circular(24),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Icon(
                icon,
                color: const Color(0xFF2563EB),
              ),
            ),

            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.headingFont(context),
                fontWeight: FontWeight.bold,
                color: ThemeColors.text(context),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              subtitle,
              style: TextStyle(
                height: 1.6,
                color: ThemeColors.secondaryText(context),
              ),
            ),
          ],
        ),),
        ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return HoverCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),

        decoration: BoxDecoration(
          color: ThemeColors.card(context),
          borderRadius: BorderRadius.circular(28),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.headingFont(context),
                fontWeight: FontWeight.bold,
                color: ThemeColors.text(context),
              ),
            ),

            const SizedBox(height: 24),

            child,
          ],
        ),),
    );
  }

  Widget _buildContactCard() {
    return _buildSectionCard(
      title: 'Contact Support',

      child: Column(
        children: [
          _buildContactTile(
            Icons.email_outlined,
            'Available Soon',
          ),

          const SizedBox(height: 18),

          _buildContactTile(
            Icons.email_outlined,
            'Available Soon',
          ),

          const SizedBox(height: 18),

          _buildContactTile(
            Icons.language,
            'Under Development',
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Feedback feature will be available in a future update.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              icon: const Icon(
                Icons.feedback_outlined,
                color: Colors.white,
              ),

              label: const Text(
                'Send Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return _buildSectionCard(
      title: 'AI Engine Information',

      child: Column(
        children: [
          _buildStatusTile(
            'AI Model',
            'ExtraTrees Classifier',
            Colors.green,
          ),

          const SizedBox(height: 18),

          _buildStatusTile(
            'Feature Extraction',
            'MediaPipe Face Mesh',
            Colors.blue,
          ),

          const SizedBox(height: 18),

          _buildStatusTile(
            'Backend Framework',
            'Flask REST API',
            Colors.orange,
          ),

          const SizedBox(height: 18),

          _buildStatusTile(
            'Clinical Reporting',
            'Dynamic AI Interpretation',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
      IconData icon,
      String text,
      ){
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: ThemeColors.inputFill(context),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF2563EB),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ThemeColors.text(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(
      String title,
      String status,
      Color color,
      ) {
    return Responsive.isPhone(context)
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 10),
        Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.text(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}