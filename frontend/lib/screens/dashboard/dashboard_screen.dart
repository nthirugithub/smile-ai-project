import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/session_service.dart';
import '../../widgets/app_shell.dart';
import '../../theme/theme_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon_container.dart';
import '../../widgets/primary_button.dart';
import '../../utils/responsive.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalCases = 0;
  int totalReports = 0;
  double avgConfidence = 0;

  bool isLoadingStats = true;
  String userName = 'User';
  String userEmail = '';
  List<dynamic> recentReports = [];

  Future<void> fetchDashboardStats() async {
    try {
      final token = await SessionService.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/dashboard-stats'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          totalCases = data['total_cases'];
          totalReports = data['total_reports'];
          avgConfidence = (data['avg_confidence'] as num).toDouble();
          isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  Future<void> fetchRecentReports() async {
    try {
      final token = await SessionService.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/reports'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          recentReports = data['reports'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

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
    fetchDashboardStats();
    fetchRecentReports();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return AppShell(
      currentRoute: '/dashboard',
      title: 'Dashboard',
      userName: userName,
      userEmail: userEmail,
      enableSearch: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinical Banner Card
            AppCard(
              padding: EdgeInsets.all(Responsive.welcomePadding(context)),
              color: ThemeColors.primaryContainer(context),
              border: BorderSide(color: ThemeColors.primary(context).withValues(alpha: 0.2)),
              child: isPhone
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $userName',
                          style: AppTypography.pageTitle(context).copyWith(
                            color: ThemeColors.onPrimaryContainer(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monitor patient smile reports, AI evaluations, and facial symmetry analysis in one place.',
                          style: AppTypography.body(context).copyWith(
                            color: ThemeColors.secondaryText(context),
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'New Analysis',
                          icon: Icons.add_a_photo_outlined,
                          onPressed: () => Navigator.pushNamed(context, '/analysis'),
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
                                'Welcome back, $userName',
                                style: AppTypography.pageTitle(context).copyWith(
                                  color: ThemeColors.onPrimaryContainer(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Monitor patient smile reports, AI evaluations, and facial symmetry analysis in one place.',
                                style: AppTypography.body(context).copyWith(
                                  color: ThemeColors.secondaryText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        PrimaryButton(
                          label: 'New Analysis',
                          icon: Icons.add_a_photo_outlined,
                          fullWidth: false,
                          onPressed: () => Navigator.pushNamed(context, '/analysis'),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // STATS GRID
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  title: 'Total Patients',
                  value: isLoadingStats ? '...' : totalCases.toString(),
                  icon: Icons.people_outline,
                ),
                _buildStatCard(
                  title: 'AI Analyses',
                  value: isLoadingStats ? '...' : totalReports.toString(),
                  icon: Icons.analytics_outlined,
                ),
                _buildStatCard(
                  title: 'Model Status',
                  value: isLoadingStats ? '...' : 'Active',
                  icon: Icons.check_circle_outline,
                  statusVariant: AppChipVariant.success,
                ),
              ],
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Clinical Analyses',
                    style: AppTypography.sectionTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/cases'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isPhone ? 'View All' : 'View All Cases',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: isPhone ? 13 : 14,
                      color: ThemeColors.primary(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (recentReports.isEmpty)
              AppCard(
                padding: EdgeInsets.all(isPhone ? 16 : 24),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(isPhone ? 16 : 24),
                    child: Text(
                      'No recent analyses found.',
                      style: AppTypography.body(context).copyWith(
                        color: ThemeColors.secondaryText(context),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...recentReports.take(4).map((report) {
                final patientName = report['patient_name'] ?? 'Patient';
                final patientCode = report['patient_code'] ?? (report['patient_id'] != null ? 'P-${report['patient_id'].toString().padLeft(6, '0')}' : 'P-${report['id'].toString().padLeft(6, '0')}');
                final createdAt = report['created_at'] ?? '';
                final severity = report['severity'] ?? 'Normal';

                AppChipVariant badgeVariant = AppChipVariant.info;
                if (severity == 'Normal') {
                  badgeVariant = AppChipVariant.success;
                } else if (severity == 'Mild') {
                  badgeVariant = AppChipVariant.warning;
                } else if (severity == 'Moderate' || severity == 'Severe') {
                  badgeVariant = AppChipVariant.error;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 14 : 18,
                      vertical: isPhone ? 10 : 14,
                    ),
                    child: Row(
                      children: [
                        AppIconContainer(
                          icon: Icons.person_outline,
                          size: isPhone ? AppIconSize.sm : AppIconSize.md,
                        ),
                        SizedBox(width: isPhone ? 10 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ThemeColors.primary(context).withValues(alpha: 0.1),
                                      borderRadius: AppRadius.borderSm,
                                    ),
                                    child: Text(
                                      patientCode,
                                      style: AppTypography.caption(context).copyWith(
                                        color: ThemeColors.primary(context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      patientName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.cardTitle(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                createdAt,
                                style: AppTypography.caption(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppChip(
                          label: severity,
                          variant: badgeVariant,
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    AppChipVariant statusVariant = AppChipVariant.info,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = Responsive.isPhone(context);
        final isTablet = Responsive.isTablet(context);
        double cardWidth;
        if (isPhone) {
          cardWidth = constraints.maxWidth;
        } else if (isTablet) {
          cardWidth = (constraints.maxWidth - 16) / 2;
        } else {
          cardWidth = (constraints.maxWidth - 32) / 3;
        }

        return SizedBox(
          width: cardWidth.clamp(200.0, double.infinity),
          child: AppCard(
            padding: EdgeInsets.all(isPhone ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppIconContainer(
                      icon: icon,
                      size: isPhone ? AppIconSize.sm : AppIconSize.md,
                    ),
                    if (title == 'Model Status')
                      const AppChip(
                        label: 'Operational',
                        variant: AppChipVariant.success,
                      ),
                  ],
                ),
                SizedBox(height: isPhone ? 10 : 16),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: Responsive.statValueFont(context),
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
