import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../widgets/app_shell.dart';
import '../../theme/theme_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon_container.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController clinicController = TextEditingController();
  final TextEditingController regController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController roleController = TextEditingController(text: 'Orthodontist');

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
    roleController.dispose();
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
      final userId = await SessionService.getUserId();
      final data = await ApiService.getProfile(userId);

      if (data['success']) {
        final profile = data['profile'];
        final stats = data['stats'];
        final recent = data['recent_activity'];

        setState(() {
          nameController.text = profile['name'] ?? '';
          emailController.text = profile['email'] ?? '';
          phoneController.text = profile['phone'] ?? '';
          clinicController.text = profile['clinic'] ?? '';
          regController.text = profile['registration_number'] ?? '';
          specializationController.text = profile['specialization'] ?? '';
          experienceController.text = (profile['experience'] ?? 0).toString();

          totalCases = stats['total_cases'] ?? 0;
          reportsGenerated = stats['reports_generated'] ?? 0;
          averageConfidence = (stats['average_confidence'] ?? 0).toDouble();
          lastAnalysis = stats['last_analysis'] ?? 'No Analysis Yet';
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
      final userId = await SessionService.getUserId();
      final data = await ApiService.updateProfile(
        userId: userId,
        name: nameController.text,
        phone: phoneController.text,
        clinic: clinicController.text,
        registrationNumber: regController.text,
        specialization: specializationController.text,
        experience: int.tryParse(experienceController.text) ?? 0,
      );

      if (data['success']) {
        setState(() {
          isEditing = false;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        await loadProfile();
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  Future<void> _logout() async {
    await SessionService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/auth',
      (route) => false,
    );
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
      title: 'Practitioner Profile',
      userName: userName,
      userEmail: userEmail,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 24),
            isMobile
                ? Column(
                    children: [
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 16),
                      _buildProfessionalInfoCard(),
                      const SizedBox(height: 16),
                      _buildStatsCard(),
                      const SizedBox(height: 16),
                      _buildActivityCard(),
                      const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                            _buildActivityCard(),
                            const SizedBox(height: 16),
                            _buildSecurityCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final isMobile = Responsive.isPhone(context);

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      color: ThemeColors.primaryContainer(context),
      border: BorderSide(color: ThemeColors.primary(context).withValues(alpha: 0.2)),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: ThemeColors.primary(context),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.pageTitle(context).copyWith(
                              color: ThemeColors.onPrimaryContainer(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const AppChip(
                      label: 'Verified Practitioner',
                      variant: AppChipVariant.success,
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit Photo'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        foregroundColor: ThemeColors.primary(context),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ThemeColors.primary(context),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTypography.pageTitle(context).copyWith(
                          color: ThemeColors.onPrimaryContainer(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: AppTypography.body(context).copyWith(
                          color: ThemeColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeColors.primary(context),
                  ),
                ),
                const SizedBox(width: 8),
                const AppChip(
                  label: 'Verified Practitioner',
                  variant: AppChipVariant.success,
                ),
              ],
            ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Personal Information', style: AppTypography.sectionTitle(context)),
              IconButton(
                icon: Icon(
                  isEditing ? Icons.check_circle : Icons.edit_outlined,
                  color: ThemeColors.primary(context),
                ),
                onPressed: () {
                  if (isEditing) {
                    updateProfile();
                  } else {
                    setState(() => isEditing = true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Full Name',
            controller: nameController,
            enabled: isEditing,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Email Address',
            controller: emailController,
            enabled: false,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Phone Number',
            controller: phoneController,
            enabled: isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Details', style: AppTypography.sectionTitle(context)),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Clinic / Hospital Name',
            controller: clinicController,
            enabled: isEditing,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Medical License / Registration No.',
            controller: regController,
            enabled: isEditing,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Specialization',
            controller: specializationController,
            enabled: isEditing,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Years of Experience',
            controller: experienceController,
            keyboardType: TextInputType.number,
            enabled: isEditing,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Clinical Role',
            controller: roleController,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Activity Overview', style: AppTypography.sectionTitle(context)),
          const SizedBox(height: 16),
          _buildStatRow('Total Patients Evaluated', totalCases.toString(), Icons.people_outline),
          const SizedBox(height: 12),
          _buildStatRow('Reports Generated', reportsGenerated.toString(), Icons.description_outlined),
          const SizedBox(height: 12),
          _buildStatRow('Average Model Score', '${(averageConfidence * 100).toStringAsFixed(1)}%', Icons.auto_awesome),
          const SizedBox(height: 12),
          _buildStatRow('Last Active Analysis', lastAnalysis, Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Diagnostic Activity', style: AppTypography.sectionTitle(context)),
          const SizedBox(height: 16),
          if (recentActivity.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeColors.surfaceVariant(context),
                borderRadius: AppRadius.borderMd,
              ),
              child: Column(
                children: [
                  AppIconContainer(icon: Icons.history_outlined, size: AppIconSize.md),
                  const SizedBox(height: 10),
                  Text('No recent activity', style: AppTypography.label(context)),
                  const SizedBox(height: 4),
                  Text('Your recent smile analyses will appear here.', style: AppTypography.caption(context)),
                ],
              ),
            )
          else
            ...recentActivity.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeColors.surfaceVariant(context),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: ThemeColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: ThemeColors.primary(context), size: 8),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['patient_name'] ?? 'Patient Analysis',
                              style: AppTypography.label(context),
                            ),
                            Text(
                              '${item['severity'] ?? 'Analysis'} • ${item['created_at'] ?? ''}',
                              style: AppTypography.caption(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Security & Session', style: AppTypography.sectionTitle(context)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Logout from System',
            icon: Icons.logout_outlined,
            variant: PrimaryButtonVariant.outlined,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeColors.surfaceVariant(context),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: ThemeColors.border(context)),
      ),
      child: Row(
        children: [
          AppIconContainer(icon: icon, size: AppIconSize.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption(context)),
                Text(value, style: AppTypography.label(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}