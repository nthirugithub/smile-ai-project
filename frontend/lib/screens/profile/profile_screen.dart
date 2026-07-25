import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../widgets/app_shell.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/primary_hover_button.dart';
import '../../utils/responsive.dart';
import '../../services/api_service.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {


  String userName = 'User';
  String userEmail = '';
  int totalCases = 0;

  int reportsGenerated = 0;

  double averageConfidence = 0.0;

  String lastAnalysis = 'No Analysis Yet';
  bool isEditing = false;
  String? hoveredAction;
  String? hoveredStat;
  String? hoveredActivity;

  final TextEditingController nameController =
  TextEditingController(text: 'Dr. John Smith');
  final TextEditingController emailController =
  TextEditingController(text: 'doctor@smilesync.ai');
  final TextEditingController phoneController =
  TextEditingController(text: '+91 98765 43210');
  final TextEditingController clinicController =
  TextEditingController(text: 'SmileSync Dental Center');
  final TextEditingController regController =
  TextEditingController(text: 'REG-2026-0142');
  final TextEditingController specializationController =
  TextEditingController();

  final TextEditingController experienceController =
  TextEditingController();

  List<dynamic> recentActivity = [];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    clinicController.dispose();
    regController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    super.dispose();
  }
  Future<void> loadUserData() async {
    final name = await SessionService.getName();
    final email = await SessionService.getEmail();

    setState(() {
      userName = name;
      userEmail = email;
    });
  }
  Future<void> loadProfile() async {

    try {

      final userId =
      await SessionService.getUserId();


      final data = await ApiService.getProfile(userId);

      if (data['success']) {

        final profile =
        data['profile'];
        final stats =
        data['stats'];
        final recent =
        data['recent_activity'];

        setState(() {

          nameController.text =
              profile['name'] ?? '';

          emailController.text =
              profile['email'] ?? '';

          phoneController.text =
              profile['phone'] ?? '';

          clinicController.text =
              profile['clinic'] ?? '';

          regController.text =
              profile['registration_number'] ?? '';
          specializationController.text =
              profile['specialization'] ?? '';

          experienceController.text =
              profile['experience'].toString();

          totalCases =
              stats['total_cases'] ?? 0;

          reportsGenerated =
              stats['reports_generated'] ?? 0;

          averageConfidence =
              (stats['average_confidence'] ?? 0).toDouble();

          lastAnalysis =
              stats['last_analysis'] ?? 'No Analysis Yet';
          recentActivity = recent ?? [];

        });

      }

    } catch (e) {

      debugPrint(e.toString());

    }
  }
  Future<void> updateProfile() async {
    final messenger = ScaffoldMessenger.of(context);

    try {

      final userId =
      await SessionService.getUserId();

      final data = await ApiService.updateProfile(
        userId: userId,
        name: nameController.text,
        phone: phoneController.text,
        clinic: clinicController.text,
        registrationNumber: regController.text,
        specialization: specializationController.text,
        experience:
        int.tryParse(experienceController.text) ?? 0,
      );

      if (data['success']) {

        setState(() {
          isEditing = false;
        });

        messenger.showSnackBar(

          const SnackBar(
            content: Text(
              'Profile updated successfully',
            ),
          ),

        );

        await loadProfile();

      }

    } catch (e) {

      debugPrint(
        "Update Error: $e",
      );

    }
  }

  @override
  void initState() {
    super.initState();

    loadUserData();

    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isPhone(context);

    return AppShell(
      currentRoute: '/profile',
      title: 'Profile',
      userName: userName,
      userEmail: userEmail,

      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Responsive.pagePadding(context),
          Responsive.pagePadding(context),
          Responsive.pagePadding(context),
          Responsive.bottomPagePadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 30),
            isMobile
                ? Column(
              children: [
                _buildPersonalInfoCard(),
                const SizedBox(height: 24),
                _buildProfessionalInfoCard(),
                const SizedBox(height: 24),
                _buildStatsCard(),
                const SizedBox(height: 24),
                _buildActivityCard(),
                const SizedBox(height: 24),
                _buildSecurityCard(),
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 24),
                      _buildProfessionalInfoCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildStatsCard(),
                      const SizedBox(height: 24),
                      _buildActivityCard(),
                      const SizedBox(height: 24),
                      _buildSecurityCard(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: Responsive.buttonHeight(context),
              child:
              PrimaryHoverButton(
                onPressed: () async {
                  if (!isEditing) {
                    setState(() {
                      isEditing = true;
                    });
                    return;
                  }

                  await updateProfile();
                },
                child: Text(
                  isEditing
                      ? 'Save Changes'
                      : 'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.bodyFont(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final bool isMobile = Responsive.isPhone(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        Responsive.cardPadding(context),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
      ),
      child: isMobile
          ? Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Text(
              (nameController.text.trim().isNotEmpty)
                  ? nameController.text.trim()[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            nameController.text.isEmpty
                ? 'User'
                : nameController.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.titleFont(context),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            specializationController.text.isEmpty
                ? 'Orthodontist'
                : specializationController.text,
            textAlign: TextAlign.center,
            style:  TextStyle(
              color: Colors.white70,
              fontSize: Responsive.bodyFont(context),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text(
                  'Profile Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Text(
              (nameController.text.trim().isNotEmpty)
                  ? nameController.text.trim()[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text.isEmpty
                      ? 'User'
                      : nameController.text,
                  style:  TextStyle(
                    fontSize: Responsive.titleFont(context),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  specializationController.text.isEmpty
                      ? 'Orthodontist'
                      : specializationController.text,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: Responsive.bodyFont(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  'Profile Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildSectionCard(
      title: 'Profile Information',
      child: Column(
        children: [
          _buildAvatarBlock(),
          const SizedBox(height: 24),
          _buildLabelTextField('Full Name', nameController),
          const SizedBox(height: 18),
          _buildLabelTextField('Email', emailController),
          const SizedBox(height: 18),
          _buildLabelTextField('Phone Number', phoneController),
          const SizedBox(height: 18),
          _buildLabelTextField('Registration Number', regController),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    return _buildSectionCard(
      title: 'Professional Information',
      child: Column(
        children: [
          _buildLabelTextField(
            'Clinic Name',
            clinicController,
          ),

          const SizedBox(height: 18),

          _buildLabelTextField(
            'Specialization',
            specializationController,
          ),

          const SizedBox(height: 18),

          _buildLabelTextField(
            'Experience (Years)',
            experienceController,
          ),

          const SizedBox(height: 18),

          _buildLabelTextField(
            'Role',
            TextEditingController(
              text: 'Orthodontist',
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return _buildSectionCard(
      title: 'Clinical Activity',
      child: Column(
        children: [

          _buildStatTile(
            'Cases Analyzed',
            totalCases.toString(),
            Colors.blue,
          ),

          const SizedBox(height: 14),

          _buildStatTile(
            'Reports Generated',
            reportsGenerated.toString(),
            Colors.green,
          ),

          const SizedBox(height: 14),

          _buildStatTile(
            'Average AI Confidence',
            '${averageConfidence.toStringAsFixed(1)}%',
            Colors.orange,
          ),

          const SizedBox(height: 14),

          _buildStatTile(
            'Last Analysis',
            lastAnalysis,
            Colors.purple,
          ),
        ],
      ),
    );
  }
  Widget _buildActivityCard() {
    return _buildSectionCard(
      title: 'Recent Activity',
      child: recentActivity.isEmpty
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeColors.inputFill(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 42,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No analyses yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.text(context)
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your recent smile analyses will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: ThemeColors.text(context)
              ),
            ),
          ],
        ),
      )
          : Column(
        children: recentActivity.map((item) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(
                  () => hoveredActivity = item['patient_name'] ?? '',
            ),
            onExit: (_) => setState(
                  () => hoveredActivity = null,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hoveredActivity == (item['patient_name'] ?? '')
                    ? ThemeColors.card(context)
                    : ThemeColors.inputFill(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hoveredActivity == (item['patient_name'] ?? '')
                      ? const Color(0xFF2563EB)
                      : Colors.transparent,
                  width: 1.4,
                ),
                boxShadow: hoveredActivity == (item['patient_name'] ?? '')
                    ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['patient_name'] ?? '',
                          style:  TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ThemeColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['severity']} • ${item['created_at']}',
                          style:  TextStyle(
                            color: ThemeColors.secondaryText(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _buildSectionCard(
      title: 'Security',
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {

              await SessionService.logout();

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth',
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.welcomePadding(context),
      ),
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
      ),
    );
  }

  Widget _buildAvatarBlock() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFFEAF1FF),
          child: Text(
            nameController.text.trim().isNotEmpty
                ? nameController.text.trim()[0].toUpperCase()
                : 'U',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Profile Photo'),
        ),
      ],
    );
  }

  Widget _buildLabelTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          enabled: label != 'Role' && isEditing,
          style: TextStyle(
            color: ThemeColors.text(context),
          ),
          decoration: InputDecoration(
            hintText: 'Not Added Yet',

            hintStyle: TextStyle(
              color: ThemeColors.secondaryText(context),
            ),
            filled: true,
            fillColor: ThemeColors.inputFill(context),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: ThemeColors.border(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 2,
              ),
            ),
            suffixIcon: isEditing
                ? const Icon(
              Icons.edit,
              color: Color(0xFF2563EB),
            )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredStat = label),
      onExit: (_) => setState(() => hoveredStat = null),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: hoveredStat == label ? 1.02 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hoveredStat == label
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hoveredStat == label
                  ? color
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: hoveredStat == label
                ? [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                flex: 2,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredAction = title),
      onExit: (_) => setState(() => hoveredAction = null),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: hoveredAction == title
                ? ThemeColors.inputFill(context)
                : ThemeColors.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hoveredAction == title
                  ? const Color(0xFF2563EB)
                  : ThemeColors.border(context),
            ),
            boxShadow: hoveredAction == title
                ? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: hoveredAction == title ? 1.12 : 1.0,
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.text(context),
                ),
              ),
            ],
          ),
        ),),
    );
  }
}