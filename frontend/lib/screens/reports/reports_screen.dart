import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../widgets/app_shell.dart';
import '../../services/session_service.dart';
import '../../theme/theme_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon_container.dart';
import '../../widgets/primary_button.dart';
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
          pw.Image(image, height: 250),
          pw.SizedBox(height: 24),
          pw.Text('Severity: ${analysis['severity'] ?? 'Unknown'}'),
          pw.Text('Priority: ${analysis['priority'] ?? 'Unknown'}'),
          pw.SizedBox(height: 24),
          pw.Text(
            'Smile Metrics',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Smile Symmetry: ${analysis['features']?['smile_symmetry']}'),
          pw.Text('Smile Width: ${analysis['features']?['smile_width']}'),
          pw.Text('Smile Arc: ${analysis['features']?['smile_arc']}'),
          pw.Text('Midline Deviation: ${analysis['features']?['midline_deviation']}'),
          pw.Text('Lip Opening: ${analysis['features']?['lip_opening']}'),
          pw.SizedBox(height: 24),
          pw.Text(
            'Recommendations',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...((analysis['recommendations'] ?? []) as List).map(
            (item) => pw.Bullet(text: item.toString()),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Clinical Interpretation',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...((analysis['clinical_interpretation'] ?? []) as List).map(
            (item) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item['title'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(item['description'] ?? ''),
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
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final routeAnalysis = args?['analysisData'] as Map<String, dynamic>?;

    analysis = routeAnalysis ??
        (widget.analysisData?['analysisData'] as Map<String, dynamic>?) ??
        widget.analysisData ??
        {};

    imageBytes = args?['imageBytes'] as Uint8List?;

    if (analysis.isEmpty) {
      return AppShell(
        currentRoute: '/reports',
        title: 'Clinical Report',
        userName: userName,
        userEmail: userEmail,
        enableSearch: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconContainer(
                icon: Icons.description_outlined,
                size: AppIconSize.lg,
              ),
              const SizedBox(height: 20),
              Text(
                "No report selected",
                style: AppTypography.pageTitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                "Open a report from Search, Cases, or complete a new analysis.",
                style: AppTypography.body(context).copyWith(
                  color: ThemeColors.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<dynamic> interpretations = analysis['clinical_interpretation'] ?? [];
    final bool isMobile = Responsive.isPhone(context);

    return AppShell(
      currentRoute: '/reports',
      title: 'Clinical Diagnostic Report',
      userName: userName,
      userEmail: userEmail,
      child: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner
              AppCard(
                color: ThemeColors.primaryContainer(context),
                border: BorderSide(color: ThemeColors.primary(context).withValues(alpha: 0.2)),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Clinical Report',
                            style: AppTypography.pageTitle(context).copyWith(
                              color: ThemeColors.onPrimaryContainer(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Detailed orthodontic smile analysis powered by AI-assisted facial symmetry interpretation.',
                            style: AppTypography.body(context).copyWith(
                              color: ThemeColors.secondaryText(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Export PDF',
                            icon: Icons.picture_as_pdf_outlined,
                            onPressed: () async {
                              if (analysis['overlay_image'] != null) {
                                final bytes = base64Decode(analysis['overlay_image']);
                                await generatePdfReport(analysis, bytes);
                              }
                            },
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Clinical Report',
                                  style: AppTypography.pageTitle(context).copyWith(
                                    color: ThemeColors.onPrimaryContainer(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Detailed orthodontic smile analysis powered by AI-assisted facial symmetry interpretation.',
                                  style: AppTypography.body(context).copyWith(
                                    color: ThemeColors.secondaryText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          PrimaryButton(
                            label: 'Export PDF',
                            icon: Icons.picture_as_pdf_outlined,
                            fullWidth: false,
                            onPressed: () async {
                              if (analysis['overlay_image'] != null) {
                                final bytes = base64Decode(analysis['overlay_image']);
                                await generatePdfReport(analysis, bytes);
                              }
                            },
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              isMobile
                  ? Column(
                      children: [
                        _buildImageSection(),
                        const SizedBox(height: 20),
                        _buildMetricsPanel(),
                        const SizedBox(height: 20),
                        _buildAnalysisSummary(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildImageSection(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _buildMetricsPanel(),
                              const SizedBox(height: 20),
                              _buildAnalysisSummary(),
                            ],
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 24),

              // CLINICAL RECOMMENDATIONS SECTION
              _buildRecommendationsSection(),

              const SizedBox(height: 24),

              // INTERPRETATION SECTION
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconContainer(
                          icon: Icons.medical_information_outlined,
                          size: isMobile ? AppIconSize.sm : AppIconSize.md,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Clinical Interpretation",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sectionTitle(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (interpretations.isEmpty)
                      Text(
                        "No clinical interpretation available.",
                        style: AppTypography.body(context).copyWith(
                          color: ThemeColors.secondaryText(context),
                        ),
                      )
                    else
                      ...interpretations.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInterpretationTile(
                            title: item["title"] ?? "",
                            description: item["description"] ?? "",
                            status: item["status"] ?? "good",
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CLINICAL DISCLAIMER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.warningContainer(context),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: ThemeColors.warning(context).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ThemeColors.onWarningContainer(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "AI-generated clinical suggestions should be validated by a qualified orthodontic professional before treatment planning.",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ThemeColors.onWarningContainer(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final isMobile = Responsive.isPhone(context);
    final imageHeight = isMobile ? 240.0 : (MediaQuery.of(context).size.width < 900 ? 320.0 : 500.0);

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Annotated Smile Landmark Image",
                  style: AppTypography.sectionTitle(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text("Original"),
                      ),
                      ButtonSegment(
                        value: true,
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
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Annotated Smile Landmark Image",
                  style: AppTypography.sectionTitle(context),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text("Original"),
                    ),
                    ButtonSegment(
                      value: true,
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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: AppRadius.borderMd,
            child: (_showOverlay && analysis['overlay_image'] != null)
                ? Image.memory(
                    base64Decode(analysis['overlay_image']),
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  )
                : imageBytes != null
                    ? Image.memory(
                        imageBytes!,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        height: imageHeight,
                        width: double.infinity,
                        color: ThemeColors.surfaceVariant(context),
                        child: Center(
                          child: Text(
                            'No Image Available',
                            style: AppTypography.body(context),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsPanel() {
    final features = (analysis['features'] as Map<String, dynamic>?) ?? {};

    final sym = (features['smile_symmetry'] as num?)?.toDouble() ?? 0.0;
    final width = (features['smile_width'] as num?)?.toDouble() ?? 0.0;
    final arc = (features['smile_arc'] as num?)?.toDouble() ?? 0.0;
    final midline = (features['midline_deviation'] as num?)?.toDouble() ?? 0.0;
    final lip = (features['lip_opening'] as num?)?.toDouble() ?? 0.0;
    final ging = (features['gingival_display'] as num?)?.toDouble() ?? 0.0;
    final buccal = (features['buccal_corridor'] as num?)?.toDouble() ?? 0.0;
    final face = (features['face_ratio'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        _buildMetricCard(
          "Smile Symmetry",
          '${(sym * 100).toStringAsFixed(1)}%',
          sym <= 0.020 ? "Normal" : "Asymmetric",
          sym <= 0.020 ? AppChipVariant.success : AppChipVariant.warning,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          "Smile Width",
          '${(width * 100).toStringAsFixed(1)}%',
          (width >= 0.42 && width <= 0.52) ? "Normal" : "Measured",
          (width >= 0.42 && width <= 0.52) ? AppChipVariant.success : AppChipVariant.info,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          "Smile Arc",
          '${(arc * 100).toStringAsFixed(1)}%',
          arc >= 0.25 ? "Consonant" : (arc >= 0.10 ? "Mildly Flat" : "Flat"),
          arc >= 0.25 ? AppChipVariant.success : (arc >= 0.10 ? AppChipVariant.info : AppChipVariant.warning),
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          "Midline Deviation",
          '${(midline * 100).toStringAsFixed(1)}%',
          midline <= 0.025 ? "Normal" : (midline <= 0.040 ? "Minor Shift" : "Deviated"),
          midline <= 0.025 ? AppChipVariant.success : (midline <= 0.040 ? AppChipVariant.info : AppChipVariant.warning),
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          "Lip Opening",
          '${(lip * 100).toStringAsFixed(1)}%',
          (lip >= 0.06 && lip <= 0.16) ? "Normal" : "Measured",
          (lip >= 0.06 && lip <= 0.16) ? AppChipVariant.success : AppChipVariant.info,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          "Gingival Display",
          '${(ging * 100).toStringAsFixed(1)}%',
          ging <= 0.035 ? "Normal" : (ging <= 0.055 ? "Slight" : "Excessive"),
          ging <= 0.035 ? AppChipVariant.success : (ging <= 0.055 ? AppChipVariant.info : AppChipVariant.warning),
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          "Buccal Corridor",
          '${(buccal * 100).toStringAsFixed(1)}%',
          (buccal >= 0.10 && buccal <= 0.18) ? "Normal" : "Measured",
          (buccal >= 0.10 && buccal <= 0.18) ? AppChipVariant.success : AppChipVariant.info,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          "Face Ratio",
          '${(face * 100).toStringAsFixed(1)}%',
          (face >= 1.15 && face <= 1.45) ? "Balanced" : "Measured",
          (face >= 1.15 && face <= 1.45) ? AppChipVariant.success : AppChipVariant.info,
        ),
      ],
    );
  }

  Widget _buildAnalysisSummary() {
    final isMobile = Responsive.isPhone(context);
    final patientName = analysis['patient_name'] ?? 'Patient';
    final patientCode = analysis['patient_code'] ?? (analysis['patient_id'] != null ? 'P-${analysis['patient_id'].toString().padLeft(6, '0')}' : 'P-${analysis['id'] ?? "000000"}');
    final gender = analysis['gender'] ?? '';
    final phone = analysis['phone_number'] ?? '';
    final qual = analysis['qualification'] ?? '';
    final age = analysis['age'];

    final severity = analysis['severity']?.toString() ?? analysis['overall_severity']?.toString() ?? 'Unknown';
    final treatmentPriority = analysis['treatment_priority']?.toString() ?? analysis['priority']?.toString() ?? 'Unknown';
    final smileScore = ((analysis['smile_score'] ?? 0) as num).toStringAsFixed(1);
    final grade = analysis['grade']?.toString() ?? '-';
    final level = analysis['level']?.toString() ?? '-';

    AppChipVariant getSeverityVariant(String sev) {
      final s = sev.toLowerCase();
      if (s.contains('normal')) return AppChipVariant.success;
      if (s.contains('mild')) return AppChipVariant.info;
      if (s.contains('moderate')) return AppChipVariant.warning;
      if (s.contains('severe')) return AppChipVariant.error;
      return AppChipVariant.neutral;
    }

    AppChipVariant getPriorityVariant(String prio) {
      final p = prio.toLowerCase();
      if (p.contains('low') || p.contains('routine')) return AppChipVariant.success;
      if (p.contains('medium') || p.contains('consultation')) return AppChipVariant.info;
      if (p.contains('high') || p.contains('urgent') || p.contains('evaluation')) return AppChipVariant.warning;
      return AppChipVariant.neutral;
    }

    AppChipVariant getLevelVariant(String lvl) {
      final l = lvl.toLowerCase();
      if (l.contains('excellent') || l.contains('very good') || l.contains('good')) return AppChipVariant.success;
      if (l.contains('fair') || l.contains('improvement')) return AppChipVariant.warning;
      if (l.contains('poor')) return AppChipVariant.error;
      return AppChipVariant.neutral;
    }

    final pDetails = [
      if (gender.isNotEmpty) gender,
      if (phone.isNotEmpty) 'Ph: $phone',
      if (qual.isNotEmpty) qual,
      if (age != null) 'Age: $age',
    ].join(' • ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Header Tag
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeColors.primary(context).withValues(alpha: 0.08),
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: ThemeColors.primary(context).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: ThemeColors.primary(context), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ThemeColors.primary(context),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              patientCode,
                              style: AppTypography.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              patientName,
                              style: AppTypography.cardTitle(context),
                            ),
                          ),
                        ],
                      ),
                      if (pDetails.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          pDetails,
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppIconContainer(
                icon: Icons.analytics_outlined,
                size: isMobile ? AppIconSize.sm : AppIconSize.md,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AI Analysis Summary",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _summaryRow('Overall Severity', severity, getSeverityVariant(severity)),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Treatment Priority', treatmentPriority, getPriorityVariant(treatmentPriority)),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Smile Score', smileScore, AppChipVariant.neutral),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Grade', grade, AppChipVariant.neutral),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Smile Quality', level, getLevelVariant(level)),

          if ((analysis['clinical_interpretation'] ?? []).isNotEmpty) ...[
            Divider(height: 24, color: ThemeColors.border(context)),
            _summaryRow(
              analysis['clinical_interpretation'][0]['title'] ?? 'Assessment',
              (analysis['clinical_interpretation'][0]['status'] ?? 'good').toString().toUpperCase(),
              analysis['clinical_interpretation'][0]['status'] == 'critical'
                  ? AppChipVariant.error
                  : analysis['clinical_interpretation'][0]['status'] == 'warning'
                      ? AppChipVariant.warning
                      : AppChipVariant.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, AppChipVariant variant) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.body(context).copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeColors.secondaryText(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        AppChip(label: value, variant: variant),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    final isMobile = Responsive.isPhone(context);
    final List<dynamic> recommendations = (analysis['recommendations'] as List<dynamic>?) ?? [];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconContainer(
                icon: Icons.lightbulb_outlined,
                size: isMobile ? AppIconSize.sm : AppIconSize.md,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Clinical Recommendations",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recommendations.isEmpty)
            Text(
              "No specific clinical recommendations required for this case.",
              style: AppTypography.body(context).copyWith(
                color: ThemeColors.secondaryText(context),
              ),
            )
          else
            ...recommendations.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ThemeColors.surfaceVariant(context),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: ThemeColors.border(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: ThemeColors.primary(context),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.toString(),
                          style: AppTypography.body(context).copyWith(
                            color: ThemeColors.text(context),
                          ),
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

  Widget _buildMetricCard(String title, String value, String status, AppChipVariant variant) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.label(context)),
              const SizedBox(height: 4),
              Text(value, style: AppTypography.cardTitle(context)),
            ],
          ),
          AppChip(label: status, variant: variant),
        ],
      ),
    );
  }

  Widget _buildInterpretationTile({
    required String title,
    required String description,
    required String status,
  }) {
    AppChipVariant chipVariant = AppChipVariant.neutral;
    if (status == 'good' || status == 'normal') chipVariant = AppChipVariant.success;
    if (status == 'moderate' || status == 'warning') chipVariant = AppChipVariant.warning;
    if (status == 'severe' || status == 'error') chipVariant = AppChipVariant.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeColors.surfaceVariant(context),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: ThemeColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.label(context)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.body(context).copyWith(
                    color: ThemeColors.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppChip(label: status.toUpperCase(), variant: chipVariant),
        ],
      ),
    );
  }
}