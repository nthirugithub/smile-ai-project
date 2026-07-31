import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:smile_analysis/widgets/app_shell.dart';
import 'package:smile_analysis/services/session_service.dart';
import 'package:smile_analysis/services/api_service.dart';
import '../../theme/theme_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon_container.dart';
import '../../widgets/primary_button.dart';
import '../../utils/responsive.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  String userName = 'User';
  String userEmail = '';
  List<dynamic> reports = [];
  int pendingReview = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchReports();
    fetchDashboardStats();
  }

  Future<void> loadUserData() async {
    final name = await SessionService.getName();
    final email = await SessionService.getEmail();

    if (!mounted) return;
    setState(() {
      userName = name;
      userEmail = email;
    });
  }

  Future<void> fetchReports() async {
    try {
      final data = await ApiService.getPatients();
      if (!mounted) return;
      if (data['success'] == true && data['patients'] != null && (data['patients'] as List).isNotEmpty) {
        setState(() {
          reports = data['patients'];
          isLoading = false;
        });
      } else {
        // Fallback to reports list for legacy compatibility
        final token = await SessionService.getAccessToken();
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/reports'),
          headers: {"Authorization": "Bearer $token"},
        );
        final repData = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          reports = repData['reports'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchDashboardStats() async {
    try {
      final token = await SessionService.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/dashboard-stats'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);

      if (data['success']) {
        if (!mounted) return;
        setState(() {
          pendingReview = data['pending_review'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return AppShell(
      currentRoute: '/cases',
      title: 'Cases & Records',
      userName: userName,
      userEmail: userEmail,
      enableSearch: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(context, isPhone),
          const SizedBox(height: 20),
          Expanded(
            child: buildCasesList(),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context, bool isPhone) {
    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinical Case Records',
            style: AppTypography.pageTitle(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage patient records, historical smile reports, and AI analysis archives.',
            style: AppTypography.body(context).copyWith(
              color: ThemeColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'New Case',
            icon: Icons.add,
            fullWidth: true,
            height: 44,
            onPressed: () => Navigator.pushNamed(context, '/analysis'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Case Records',
                style: AppTypography.pageTitle(context),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage patient records, historical smile reports, and AI analysis archives.',
                style: AppTypography.body(context).copyWith(
                  color: ThemeColors.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        PrimaryButton(
          label: 'New Case',
          icon: Icons.add,
          fullWidth: false,
          onPressed: () => Navigator.pushNamed(context, '/analysis'),
        ),
      ],
    );
  }

  Widget buildCasesList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        buildStats(context, reports.length, pendingReview),
        const SizedBox(height: 20),
        if (reports.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No patient cases recorded yet.',
                  style: AppTypography.body(context).copyWith(
                    color: ThemeColors.secondaryText(context),
                  ),
                ),
              ),
            ),
          )
        else
          ...reports.map((item) => buildPatientCard(item)),
      ],
    );
  }

  Widget buildStats(BuildContext context, int totalCases, int pendingReview) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        buildStatCard(
          totalCases.toString(),
          "Total Cases",
          Icons.folder_copy_outlined,
          ThemeColors.primary(context),
        ),
        buildStatCard(
          "94%",
          "AI Accuracy Score",
          Icons.auto_graph_outlined,
          ThemeColors.success(context),
        ),
        buildStatCard(
          pendingReview.toString(),
          "Pending Review",
          Icons.pending_actions_outlined,
          ThemeColors.warning(context),
        ),
      ],
    );
  }

  Widget buildPatientCard(dynamic item) {
    final isPhone = Responsive.isPhone(context);
    final patientName = item["full_name"] ?? item["patient_name"] ?? "Unknown";
    final patientCode = item["patient_code"] ?? item["patient_id"] ?? "P-${item["id"] ?? "000000"}";
    final gender = item["gender"] ?? "";
    final phone = item["phone_number"] ?? "";
    final qual = item["qualification"] ?? "";
    final severity = item["latest_severity"] ?? item["severity"] ?? "Normal";
    final dateStr = item["last_analysis_date"] ?? item["created_at"] ?? "";
    final totalReports = item["total_reports"] ?? 1;

    AppChipVariant badgeVariant = AppChipVariant.info;
    if (severity == 'Normal') {
      badgeVariant = AppChipVariant.success;
    } else if (severity == 'Mild') {
      badgeVariant = AppChipVariant.warning;
    } else if (severity == 'Moderate' || severity == 'Severe') {
      badgeVariant = AppChipVariant.error;
    }

    final subDetails = [
      if (gender.isNotEmpty) gender,
      if (phone.isNotEmpty) 'Ph: $phone',
      if (qual.isNotEmpty) qual,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconContainer(
                  icon: Icons.person_outline,
                  size: isPhone ? AppIconSize.sm : AppIconSize.md,
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 4),
                      if (subDetails.isNotEmpty)
                        Text(
                          subDetails,
                          style: AppTypography.caption(context),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'Last Analysis: ${dateStr.isEmpty ? "No scans yet" : dateStr}',
                        style: AppTypography.caption(context).copyWith(
                          color: ThemeColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppChip(
                      label: severity,
                      variant: badgeVariant,
                    ),
                    const SizedBox(height: 6),
                    AppChip(
                      label: '$totalReports Report${totalReports == 1 ? "" : "s"}',
                      variant: AppChipVariant.info,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Open Case Records',
              icon: Icons.folder_open_outlined,
              fullWidth: true,
              height: 38,
              variant: PrimaryButtonVariant.outlined,
              onPressed: () async {
                final reportId = item['reports'] != null && (item['reports'] as List).isNotEmpty
                    ? item['reports'][0]['id']
                    : item['id'];
                if (reportId != null) {
                  await ApiService.markReportReviewed(reportId);
                  final report = await ApiService.getReportById(reportId);
                  if (!mounted) return;
                  Navigator.pushNamed(
                    context,
                    '/reports',
                    arguments: {"analysisData": report},
                  );
                } else {
                  Navigator.pushNamed(context, '/reports');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatCard(String value, String title, IconData icon, Color iconColor) {
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
                AppIconContainer(
                  icon: icon,
                  size: isPhone ? AppIconSize.sm : AppIconSize.md,
                  color: iconColor,
                  backgroundColor: iconColor.withValues(alpha: 0.12),
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
