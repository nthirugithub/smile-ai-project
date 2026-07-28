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
      final token = await SessionService.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/reports'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() {
        reports = data['reports'] ?? [];
        isLoading = false;
      });
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
    final patientName = item["patient_name"] ?? "Unknown";
    final createdAt = item["created_at"] ?? "";
    final faceRatio = (double.tryParse(item["face_ratio"].toString()) ?? 0);
    final scoreText = "${(faceRatio * 100).toStringAsFixed(0)}%";

    if (isPhone) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconContainer(
                    icon: Icons.person_outline,
                    size: AppIconSize.sm,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardTitle(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppChip(
                              label: 'Symmetry $scoreText',
                              variant: AppChipVariant.success,
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
                ],
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Open Case',
                icon: Icons.visibility_outlined,
                fullWidth: true,
                height: 38,
                variant: PrimaryButtonVariant.outlined,
                onPressed: () async {
                  await ApiService.markReportReviewed(item["id"]);
                  final report = await ApiService.getReportById(item["id"]);
                  if (!mounted) return;
                  Navigator.pushNamed(
                    context,
                    '/reports',
                    arguments: {"analysisData": report},
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppIconContainer(
              icon: Icons.person_outline,
              size: AppIconSize.md,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: AppTypography.cardTitle(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAt,
                    style: AppTypography.caption(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppChip(
              label: 'Symmetry $scoreText',
              variant: AppChipVariant.success,
            ),
            const SizedBox(width: 16),
            PrimaryButton(
              label: 'Open',
              icon: Icons.visibility_outlined,
              fullWidth: false,
              height: 40,
              variant: PrimaryButtonVariant.outlined,
              onPressed: () async {
                await ApiService.markReportReviewed(item["id"]);
                final report = await ApiService.getReportById(item["id"]);
                if (!mounted) return;
                Navigator.pushNamed(
                  context,
                  '/reports',
                  arguments: {"analysisData": report},
                );
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
