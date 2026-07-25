import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:smile_analysis/widgets/app_shell.dart';
import 'package:smile_analysis/services/session_service.dart';
import 'package:smile_analysis/services/api_service.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/hover_card.dart';
import '../../widgets/primary_hover_button.dart';
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

        Uri.parse(
          'http://localhost:5000/reports',
        ),

        headers: {
          "Authorization": "Bearer $token",
        },

      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        reports = data['reports'] ?? [];
        isLoading = false;
      });

    }
    catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> fetchDashboardStats() async {

    try {

      final token =
      await SessionService.getAccessToken();

      final response = await http.get(
        Uri.parse(
          'http://localhost:5000/dashboard-stats',
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );


      final data = jsonDecode(
        response.body,
      );


      if (data['success']) {

        if (!mounted) return;

        setState(() {

          pendingReview =
          data['pending_review'];

        });

      }

    } catch (e) {

      debugPrint(
        e.toString(),
      );

    }
  }


  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return AppShell(
      currentRoute: '/cases',
      title: 'Cases',
      userName: userName,
      userEmail: userEmail,

      enableSearch: true,

      child: Padding(
        padding: EdgeInsets.all(
          Responsive.pagePadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(context, isPhone),

            const SizedBox(height: 24),

            Expanded(
              child: buildCasesList(),
            ),
          ],
        ),
      ),
    );
  }



  // ================= STAT CARD =================
  Widget buildHeader(BuildContext context, bool isPhone) {
    if (isPhone) {
      return Align(
        alignment: Alignment.centerLeft,
        child: PrimaryHoverButton(
          onPressed: () {
            Navigator.pushNamed(context, '/analysis');
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add),
              SizedBox(width: 10),
              Text(
                "New Case",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        const Spacer(),
        PrimaryHoverButton(
          onPressed: () {
            Navigator.pushNamed(context, '/analysis');
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add),
              SizedBox(width: 10),
              Text(
                "New Case",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget buildCasesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        buildStats(
          context,
          reports.length,
          pendingReview,
        ),

        SizedBox(
          height: Responsive.sectionSpacing(context),
        ),

        ...reports.map(
              (item) => buildPatientCard(item),
        ),
      ],
    );
  }
  Widget buildStats(
      BuildContext context,
      int totalCases,
      int pendingReview,
      ) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        buildStatCard(
          totalCases.toString(),
          "Total Cases",
          Icons.folder_copy_outlined,
          const Color(0xFF2563EB),
        ),

        buildStatCard(
          "94%",
          "AI Accuracy",
          Icons.auto_graph,
          Colors.green,
        ),

        buildStatCard(
          pendingReview.toString(),
          "Pending Review",
          Icons.pending_actions,
          Colors.orange,
        ),
      ],
    );
  }
  Widget buildPatientCard(dynamic item) {
    return HoverCard(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(
          Responsive.cardPadding(context),
        ),
        decoration: BoxDecoration(
          color: ThemeColors.card(context),
          borderRadius: BorderRadius.circular(
            Responsive.cardRadius(context),
          ),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Responsive.isPhone(context)
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0EAFF),
                  child: Text(
                    (item["patient_name"] ?? "P")[0],
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["patient_name"],
                        style: TextStyle(
                          fontSize: Responsive.bodyFont(context) + 2,
                          fontWeight: FontWeight.w600,
                          color: ThemeColors.text(context),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        item["created_at"],
                        style: TextStyle(
                          color: ThemeColors.secondaryText(context),
                          fontSize: Responsive.bodyFont(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EC),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "${((double.tryParse(item["face_ratio"].toString()) ?? 0) * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                PrimaryHoverButton(
                  onPressed: () async {
                    await ApiService.markReportReviewed(item["id"]);

                    final report =
                    await ApiService.getReportById(item["id"]);

                    if (!mounted) return;

                    Navigator.pushNamed(
                      context,
                      '/reports',
                      arguments: {
                        "analysisData": report,
                      },
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Open",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
              backgroundColor: const Color(0xFFE0EAFF),
              child: Text(
                (item["patient_name"] ?? "P")[0],
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    item["patient_name"],
                    style: TextStyle(
                      fontSize: Responsive.bodyFont(context) + 2,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.text(context),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item["created_at"],
                    style: TextStyle(
                      color: ThemeColors.secondaryText(context),
                      fontSize: Responsive.bodyFont(context),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EC),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "${((double.tryParse(item["face_ratio"].toString()) ?? 0) * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 18),

            PrimaryHoverButton(
              onPressed: () async {
                await ApiService.markReportReviewed(item["id"]);

                final report =
                await ApiService.getReportById(item["id"]);

                if (!mounted) return;

                Navigator.pushNamed(
                  context,
                  '/reports',
                  arguments: {
                    "analysisData": report,
                  },
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Open",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildStatCard(
      String value,
      String title,
      IconData icon,
      Color iconColor,
      ) {
    final isPhone = Responsive.isPhone(context);

    return SizedBox(
      width: Responsive.isPhone(context)
          ? double.infinity
          : 280,

      child: HoverCard(
        child: Container(
          padding: EdgeInsets.all(
            Responsive.cardPadding(context),
          ),

          decoration: BoxDecoration(
            color: ThemeColors.card(context),
            borderRadius:BorderRadius.circular(
              Responsive.cardRadius(context),
            ),

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
                padding: EdgeInsets.all(
                  Responsive.isPhone(context) ? 10 : 14,
                ),

                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: isPhone ? 24 : 28,
                ),
              ),

              SizedBox(
                height: Responsive.isPhone(context) ? 14 : 26,
              ),

              Text(
                value,

                style: TextStyle(
                  fontSize: Responsive.statValueFont(context),
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.text(context),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                title,

                style: TextStyle(
                  color: ThemeColors.secondaryText(context),
                  fontSize: Responsive.statTitleFont(context),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


