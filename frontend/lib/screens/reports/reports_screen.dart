import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../widgets/app_shell.dart';
import '../../services/session_service.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/fade_slide.dart';
import '../../utils/responsive.dart';
class ReportsScreen extends StatefulWidget {

  final Map<String, dynamic>? analysisData;

  const ReportsScreen({
    super.key,
    this.analysisData,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {

  Map<String, dynamic> analysis = {};

  Uint8List? imageBytes;
  bool _showOverlay = true;

  String userName = 'User';
  String userEmail = '';

  Future<void> generatePdfReport(
      Map<String, dynamic> analysis,
      Uint8List imageBytes,
      ) async {

    final pdf = pw.Document();

    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(

      pw.MultiPage(

        build: (context) => [

          pw.Text(
            'Smile AI Clinical Report',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Image(
            image,
            height: 250,
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Severity: ${analysis['severity'] ?? 'Unknown'}',
          ),


          pw.Text(
            'Treatment Priority: ${analysis['treatment_priority'] ?? 'Unknown'}',
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'Smile Metrics',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 12),

          pw.Text(
            'Smile Symmetry: ${analysis['features']['smile_symmetry']}',
          ),

          pw.Text(
            'Smile Width: ${analysis['features']['smile_width']}',
          ),

          pw.Text(
            'Smile Arc: ${analysis['features']['smile_arc']}',
          ),

          pw.Text(
            'Midline Deviation: ${analysis['features']['midline_deviation']}',
          ),

          pw.Text(
            'Lip Opening: ${analysis['features']['lip_opening']}',
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'Recommendations',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          ...((analysis['recommendations'] ?? []) as List).map(
                (item) => pw.Bullet(
              text: item.toString(),
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'Clinical Interpretation',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          ...((analysis['clinical_interpretation'] ?? []) as List).map(
                (item) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                pw.Text(
                  item['title'],
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  item['description'],
                ),

                pw.SizedBox(height: 12),
              ],
            ),
          ),

        ],
      ),
    );

    await Printing.layoutPdf(

      onLayout: (format) async => pdf.save(),
    );
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
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>?;

    final routeAnalysis =
    args?['analysisData'] as Map<String, dynamic>?;

    analysis =
        routeAnalysis ??
            (widget.analysisData?['analysisData'] as Map<String, dynamic>?) ??
            widget.analysisData ??
            {};

    imageBytes = args?['imageBytes'] as Uint8List?;

    if (analysis.isEmpty) {
      return AppShell(
        currentRoute: '/reports',
        title: 'Reports',
        userName: userName,
        userEmail: userEmail,
        enableSearch: true,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 72),
              SizedBox(height: 20),
              Text(
                "No report selected",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Open a report from Search, Cases, or complete a new analysis.",
              ),
            ],
          ),
        ),
      );
    }

    final List<dynamic> interpretations =
        analysis['clinical_interpretation'] ?? [];

    final bool isMobile =
        MediaQuery.of(context).size.width < 900;

    return AppShell(
      currentRoute: '/reports',
      title: 'Reports',
      userName: userName,
      userEmail: userEmail,

        child: SelectionArea(
          child: SingleChildScrollView(
        padding: EdgeInsets.all(
          Responsive.pagePadding(context),
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // HERO SECTION
            FadeSlide(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(32),

                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(28),

                  gradient:
                  const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,

                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF3B82F6),
                    ],
                  ),
                ),

                child: isMobile
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Clinical Report',
                          style: TextStyle(
                            fontSize: Responsive.titleFont(context),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Detailed orthodontic smile analysis powered by AI-assisted facial symmetry interpretation.',
                          style: TextStyle(
                            fontSize: Responsive.bodyFont(context),
                            height: 1.7,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: () async {
                        if (analysis['overlay_image'] != null) {
                          final imageBytes =
                          base64Decode(analysis['overlay_image']);

                          await generatePdfReport(
                            analysis,
                            imageBytes,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        'Export PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
                    : Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Text(
                            'AI Clinical Report',
                            style: TextStyle(
                              fontSize: Responsive.titleFont(context),
                              fontWeight:
                              FontWeight
                                  .w700,
                              color:
                              Colors.white,
                            ),
                          ),

                          SizedBox(height: 14),

                          Text(
                            'Detailed orthodontic smile analysis powered by AI-assisted facial symmetry interpretation.',
                            style: TextStyle(
                              fontSize: Responsive.bodyFont(context),
                              height: 1.7,
                              color:
                              Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 30),
                    ElevatedButton.icon(
                      onPressed: () async {

                        if (
                        analysis['overlay_image'] != null
                        ) {

                          final imageBytes = base64Decode(
                            analysis['overlay_image'],
                          );

                          await generatePdfReport(
                            analysis,
                            imageBytes,
                          );
                        }
                      },

                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        Colors.white,
                        foregroundColor:
                        const Color(
                          0xFF2563EB,
                        ),

                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 28,
                          vertical: 20,
                        ),

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            16,
                          ),
                        ),
                      ),

                      icon: const Icon(
                        Icons.picture_as_pdf,
                      ),

                      label: const Text(
                        'Export PDF',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),),

            const SizedBox(height: 34),

            isMobile
                ? Column(
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),

                _buildMetricsPanel(),
                const SizedBox(height: 24),

                _buildAnalysisSummary(),
              ],
            )
                : Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Expanded(
                  flex: 2,
                  child: FadeSlide(
                    delay: const Duration(milliseconds: 250),
                    child: _buildImageSection(),
                  ),
                ),

                const SizedBox(
                    width: 30),

                Expanded(
                  child: FadeSlide(
                    delay: const Duration(milliseconds: 350),
                    child: Column(
                      children: [

                        _buildMetricsPanel(),

                        const SizedBox(height: 28),

                        _buildAnalysisSummary(),
                      ],
                    ),
                  ),
                ),

              ],
            ),


            const SizedBox(height: 34),

            // INTERPRETATION SECTION
            FadeSlide(
              delay: const Duration(milliseconds: 500),
              child: Container(
                padding:
                const EdgeInsets.all(28),

                decoration: BoxDecoration(
                  color: ThemeColors.card(context),
                  borderRadius:
                  BorderRadius.circular(
                    28,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    Text(
                      "Clinical Interpretation",
                      style: TextStyle(
                        fontSize: Responsive.headingFont(context) + 2,
                        fontWeight:
                        FontWeight.w700,
                        color: ThemeColors.text(context),
                      ),
                    ),

                    const SizedBox(height: 26),

                    if (interpretations.isEmpty)

                      const Text(
                        "No clinical interpretation available.",
                      )

                    else

                      ...interpretations.map((item) {

                        return Padding(

                          padding: const EdgeInsets.only(
                            bottom: 18,
                          ),

                          child: _buildInterpretationTile(

                            title: item["title"] ?? "",

                            description: item["description"] ?? "",

                            status: item["status"] ?? "good",

                          ),

                        );

                      }),
                  ],
                ),
              ),),

            const SizedBox(height: 30),

            // DISCLAIMER
            FadeSlide(
              delay: const Duration(milliseconds: 650),
              child: Container(
                padding:
                const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFFBEB,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),

                  border: Border.all(
                    color: const Color(
                      0xFFFCD34D,
                    ),
                  ),
                ),

                child: const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    Icon(
                      Icons.info_outline,
                      color:
                      Color(0xFFD97706),
                    ),

                    SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        "AI-generated clinical suggestions should be validated by a qualified orthodontic professional before treatment planning.",
                        style: TextStyle(
                          height: 1.6,
                          color:
                          Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),),
          ],
        ),
          ),
        ),
    );
  }


  Widget _buildImageSection() {
    final imageHeight = MediaQuery.of(context).size.width < 900
        ? 380.0
        : 650.0;

    return Container(
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: ThemeColors.card(context),
        borderRadius: BorderRadius.circular(28),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Responsive.isPhone(context)
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Annotated Smile Image",
                style: TextStyle(
                  fontSize: Responsive.headingFont(context),
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.text(context),
                ),
              ),

              const SizedBox(height: 16),

              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.image_outlined),
                    label: Text("Original"),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.auto_awesome),
                    label: Text("AI Overlay"),
                  ),
                ],

                selected: {_showOverlay},

                onSelectionChanged: (value) {
                  setState(() {
                    _showOverlay = value.first;
                  });
                },
              ),
            ],
          )
              : Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                "Annotated Smile Image",
                style: TextStyle(
                  fontSize: Responsive.headingFont(context),
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.text(context),
                ),
              ),

              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.image_outlined),
                    label: Text("Original"),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.auto_awesome),
                    label: Text("AI Overlay"),
                  ),
                ],

                selected: {_showOverlay},

                onSelectionChanged: (value) {
                  setState(() {
                    _showOverlay = value.first;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          Stack(
            children: [

              ClipRRect(
                borderRadius:
                BorderRadius.circular(24),


                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: (_showOverlay && analysis['overlay_image'] != null)
                      ? Image.memory(
                    base64Decode(analysis['overlay_image']),
                    key: const ValueKey('overlay'),
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  )
                      : imageBytes != null
                      ? Image.memory(
                    imageBytes!,
                    key: const ValueKey('original'),
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  )
                      : Container(
                    key: const ValueKey('empty'),
                    height: imageHeight,
                    width: double.infinity,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF111827)
                        : const Color(0xFFF1F5F9),
                    child: Center(
                      child: Text(
                        'No Image Available',
                        style: TextStyle(
                          color: ThemeColors.inputFill(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 18,
                right: 18,

                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.65,
                    ),

                    borderRadius:
                    BorderRadius.circular(18),
                  ),

                  child: const Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [

                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 18,
                      ),

                      SizedBox(width: 8),

                      Text(
                        'AI Overlay',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsPanel() {

    final features = analysis['features'] as Map<String, dynamic>;

    return Column(
      children: [

        _buildMetricCard(
          "Smile Symmetry",
          '${((features['smile_symmetry'] ?? 0) * 100).toStringAsFixed(1)}%',
          ((features['smile_symmetry'] ?? 0) > 0.8)
              ? "Normal"
              : "Moderate",
          Colors.green,
        ),

        const SizedBox(height: 20),

        _buildMetricCard(
          "Smile Width",
          '${((features['smile_width'] ?? 0) * 100).toStringAsFixed(1)}%',
          "Measured",
          Colors.blue,
        ),

        const SizedBox(height: 20),

        _buildMetricCard(
          "Smile Arc",
          '${((features['smile_arc'] ?? 0) * 100).toStringAsFixed(1)}%',
          ((features['smile_arc'] ?? 0) > 0.5)
              ? "Consonant"
              : "Flat",
          Colors.green,
        ),

        const SizedBox(height: 20),

        _buildMetricCard(
          "Midline Deviation",
          '${((features['midline_deviation'] ?? 0) * 100).toStringAsFixed(1)}%',
          ((features['midline_deviation'] ?? 0) < 0.1)
              ? "Normal"
              : "Deviation",
          Colors.orange,
        ),

        const SizedBox(height: 20),

        _buildMetricCard(
          "Lip Opening",
          '${((features['lip_opening'] ?? 0) * 100).toStringAsFixed(1)}%',
          "Measured",
          Colors.green,
        ),

        const SizedBox(height: 20),

        _buildMetricCard(
          "Gingival Display",
          '${((features['gingival_display'] ?? 0) * 100).toStringAsFixed(1)}%',
          ((features['gingival_display'] ?? 0) < 0.1)
              ? "Normal"
              : "Excessive",
          Colors.red,
        ),

        const SizedBox(height: 20),

        _buildMetricCard(
          "Buccal Corridor",
          '${((features['buccal_corridor'] ?? 0) * 100).toStringAsFixed(1)}%',
          "Measured",
          Colors.green,
        ),

        const SizedBox(height: 20),

        _buildMetricCard(
          "Face Ratio",
          '${((features['face_ratio'] ?? 0) * 100).toStringAsFixed(1)}%',
          "Balanced",
          Colors.purple,
        ),
      ],
    );
  }
  Widget _buildMetricCard(
      String title,
      String value,
      String status,
      Color statusColor,
      ) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setHoverState) {
        return MouseRegion(
          onEnter: (_) => setHoverState(() => isHovered = true),
          onExit: (_) => setHoverState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              0,
              isHovered ? -4 : 0,
              0,
            ),


            padding: const EdgeInsets.all(22),

            decoration: BoxDecoration(
              color: ThemeColors.card(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHovered
                    ? ThemeColors.primary(context).withValues(alpha: 0.25)
                    : ThemeColors.border(context),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isHovered ? 0.18 : 0.08,
                  ),
                  blurRadius: isHovered ? 22 : 10,
                  offset: Offset(
                    0,
                    isHovered ? 10 : 4,
                  ),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Responsive.headingFont(context),
                          fontWeight: FontWeight.w700,
                          color: ThemeColors.text(context),
                        ),
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.12,
                        ),

                        borderRadius:
                        BorderRadius.circular(
                          30,
                        ),
                      ),

                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  tween: Tween(
                    begin: 0,
                    end: _extractPercentage(value),
                  ),
                  builder: (context, animatedValue, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: animatedValue,
                            minHeight: 7,
                            backgroundColor: statusColor.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(statusColor),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          "${(animatedValue * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: Responsive.headingFont(context) + 2,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.text(context),
                          ),
                        ),
                      ],
                    );
                  },
                ),],
            ),
          ),
        );
      },
    );
  }

  double _extractPercentage(String value) {
    final cleaned = value.replaceAll('%', '');

    final number = double.tryParse(cleaned) ?? 0;

    return (number / 100).clamp(0.0, 1.0);
  }

  Widget _buildInterpretationTile({

    required String title,

    required String description,

    required String status,

  }) {
    Color color;

    IconData icon;

    switch (status) {

      case "critical":

        color = Colors.red;
        icon = Icons.error_outline;
        break;

      case "warning":

        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;

      default:

        color = Colors.green;
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: color,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.bodyFont(context) + 2,
                    fontWeight:
                    FontWeight.w700,
                    color: ThemeColors.text(context),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  description,
                  style:  TextStyle(
                    height: 1.6,
                    color: ThemeColors.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAnalysisSummary() {

    final severity =
        analysis['severity']
            ?.toString() ?? 'Unknown';

    final treatmentPriority =
        analysis['treatment_priority']
            ?.toString() ?? 'Unknown';
    final smileScore =
    ((analysis['smile_score'] ?? 0) as num).toStringAsFixed(1);

    final grade =
        analysis['grade']?.toString() ?? '-';

    final level =
        analysis['level']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: ThemeColors.card(context),
        borderRadius: BorderRadius.circular(28),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            'AI Analysis Summary',
            style: TextStyle(
              fontSize: Responsive.headingFont(context),
              fontWeight: FontWeight.w700,
              color: ThemeColors.text(context),
            ),
          ),

          const SizedBox(height: 28),

          _summaryRow(
            'Overall Severity',
            severity,
            Colors.orange,
          ),

          Divider(
            height: 28,
            color: ThemeColors.border(context),
          ),

          _summaryRow(
            'Treatment Priority',
            treatmentPriority,
            Colors.blue,
          ),
          Divider(
            height: 28,
            color: ThemeColors.border(context),
          ),

          _summaryRow(
            'Smile Score',
            smileScore,
            Colors.purple,
          ),

          Divider(
            height: 28,
            color: ThemeColors.border(context),
          ),

          _summaryRow(
            'Grade',
            grade,
            Colors.indigo,
          ),

          Divider(
            height: 28,
            color: ThemeColors.border(context),
          ),

          _summaryRow(
            'Smile Quality',
            level,
            Colors.teal,
          ),

          Divider(
            height: 28,
            color: ThemeColors.border(context),
          ),

          if ((analysis['clinical_interpretation'] ?? []).isNotEmpty)

            _summaryRow(

              analysis['clinical_interpretation'][0]['title'] ?? 'Assessment',

              (analysis['clinical_interpretation'][0]['status'] ?? 'good')
                  .toString()
                  .toUpperCase(),

              (analysis['clinical_interpretation'][0]['status'] == 'critical')
                  ? Colors.red
                  : (analysis['clinical_interpretation'][0]['status'] == 'warning')
                  ? Colors.orange
                  : Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      String title,
      String value,
      Color color,
      ) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.bodyFont(context) - 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: ThemeColors.secondaryText(context),
            ),
          ),
        ),
        const SizedBox(width: 12),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),

          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius:
            BorderRadius.circular(30),
          ),

          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}