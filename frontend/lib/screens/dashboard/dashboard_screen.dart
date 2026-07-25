import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/session_service.dart';
import '../../widgets/app_shell.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/hover_card.dart';
import '../../widgets/primary_hover_button.dart';
import '../../utils/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  int totalCases = 0;

  int totalReports = 0;

  double avgConfidence = 0;

  bool isLoadingStats = true;
  String userName = 'User';
  String userEmail = '';
  List<dynamic> recentReports = [];

  final List<String> menuItems = [
    'Dashboard',
    'Cases',
    'Analysis',
    'Reports',
    'Settings',
    'Profile',
    'Help',
  ];

  final List<IconData> menuIcons = [
    Icons.grid_view_rounded,
    Icons.folder_open_outlined,
    Icons.analytics_outlined,
    Icons.description_outlined,
    Icons.settings_outlined,
    Icons.person_outline,
    Icons.help_outline,
  ];

  Future<void> fetchDashboardStats() async {

    try {

      final token = await SessionService.getAccessToken();

      final response = await http.get(
        Uri.parse(
          'http://localhost:5000/dashboard-stats',
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (data['success']) {

        setState(() {

          totalCases =
          data['total_cases'];

          totalReports =
          data['total_reports'];

          avgConfidence =
              (data['avg_confidence'] as num)
                  .toDouble();

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
        Uri.parse(
          'http://localhost:5000/reports',
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(
        response.body,
      );

      if (data['success']) {

        setState(() {

          recentReports =
          data['reports'];

        });
      }

    } catch (e) {

      debugPrint(
        e.toString(),
      );
    }
  }

  Future<void> loadUserData() async {

    final name =
    await SessionService.getName();

    final email =
    await SessionService.getEmail();

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
        child:



      Row(
        children: [


          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [

                // PAGE CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      Responsive.pagePadding(context),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // WELCOME
                        Container(
                          padding: EdgeInsets.all(
                            Responsive.welcomePadding(context),
                          ),

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),

                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,

                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.18),
                                blurRadius: 35,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),

                          child: isPhone
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, $userName 👋',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: Responsive.titleFont(context),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 14),

                              Text(
                                'Monitor patient smile reports, AI evaluations, and facial symmetry analysis in one place.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: Responsive.bodyFont(context),
                                  height: 1.7,
                                  color: Colors.white70,
                                ),
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: PrimaryHoverButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/analysis');
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined),
                                      SizedBox(width: 10),
                                      Text(
                                        'New Analysis',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                      'Welcome back, $userName 👋',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: Responsive.titleFont(context),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    Text(
                                      'Monitor patient smile reports, AI evaluations, and facial symmetry analysis in one place.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: Responsive.bodyFont(context),
                                        height: 1.7,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 30),

                              PrimaryHoverButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/analysis');
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined),
                                    SizedBox(width: 10),
                                    Text(
                                      'New Analysis',
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

                        const SizedBox(height: 34),

                        // STATS
                        Wrap(
                          spacing: 22,
                          runSpacing: 22,

                          children: [

                            _buildStatCard(
                              title: 'Total Patients',

                              value: isLoadingStats
                                  ? '...'
                                  : totalCases.toString(),

                              icon: Icons.people_outline,
                            ),

                            _buildStatCard(
                              title: 'AI Analyses',

                              value: isLoadingStats
                                  ? '...'
                                  : totalReports.toString(),

                              icon: Icons.analytics_outlined,
                            ),

                            _buildStatCard(
                              title: 'Model Status',

                              value: isLoadingStats
                                  ? '...'
                                  : 'Active',

                              icon: Icons.auto_awesome,
                            ),
                          ],
                        ),

                        SizedBox(
                          height: Responsive.sectionSpacing(context),
                        ),

                        // RECENT ANALYSES
                        Responsive.isPhone(context)
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Analyses',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: Responsive.headingFont(context),
                                fontWeight: FontWeight.w700,
                                color: ThemeColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/cases',
                                  );
                                },
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Analyses',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: Responsive.headingFont(context),
                                fontWeight: FontWeight.w700,
                                color: ThemeColors.text(context),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/cases',
                                );
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        ...recentReports.take(3).map((report) {

                          final patientName =
                              report['patient_name'] ?? 'Patient';

                          final createdAt =
                              report['created_at'] ?? '';

                          final faceRatio =
                          (double.tryParse(
                            report['face_ratio'].toString(),
                          ) ?? 0);

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 18,
                            ),
                            child: _buildPatientCard(
                              initials: patientName.isNotEmpty
                                  ? patientName[0]
                                  : 'P',

                              name: patientName,

                              date: createdAt,

                              score:
                              '${(faceRatio * 100).toStringAsFixed(0)}%',
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
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
        borderRadius: BorderRadius.circular(
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
              Responsive.isPhone(context) ? 10 : 12,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(
                Responsive.isPhone(context) ? 12 : 14,
              ),
            ),

            child: Icon(icon, color: const Color(0xFF2563EB),size: Responsive.isPhone(context) ? 24 : 28,),
          ),


          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: Responsive.statValueFont(context),
              fontWeight: FontWeight.w700,
              color: ThemeColors.text(context),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: Responsive.statTitleFont(context),
              color: ThemeColors.secondaryText(context),
            ),
          ),
        ],
      ),
          ),
        ),
    );
  }

  Widget _buildPatientCard({
    required String initials,
    required String name,
    required String date,
    required String score,
  }) {
    return HoverCard(
        child: Container(
          padding: EdgeInsets.all(
            Responsive.cardPadding(context),
          ),

      decoration: BoxDecoration(
        color: ThemeColors.card(context),
        borderRadius: BorderRadius.circular(
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

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFDBEAFE),

                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: Responsive.bodyFont(context) + 2,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.text(context),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: ThemeColors.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(30),
            ),

            child: Text(
              score,
              style: const TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),),
    );
  }
}
