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

    return Column(
      children: [
        _buildMetricCard("Smile Symmetry", '${((features['smile_symmetry'] ?? 0) * 100).toStringAsFixed(1)}%', ((features['smile_symmetry'] ?? 0) > 0.8) ? "Normal" : "Moderate", AppChipVariant.success),
        const SizedBox(height: 12),
        _buildMetricCard("Smile Width", '${((features['smile_width'] ?? 0) * 100).toStringAsFixed(1)}%', "Measured", AppChipVariant.info),
        const SizedBox(height: 12),
        _buildMetricCard("Smile Arc", '${((features['smile_arc'] ?? 0) * 100).toStringAsFixed(1)}%', ((features['smile_arc'] ?? 0) > 0.5) ? "Consonant" : "Flat", AppChipVariant.success),
        const SizedBox(height: 12),
        _buildMetricCard("Midline Deviation", '${((features['midline_deviation'] ?? 0) * 100).toStringAsFixed(1)}%', ((features['midline_deviation'] ?? 0) < 0.1) ? "Normal" : "Deviation", AppChipVariant.warning),
        const SizedBox(height: 12),
        _buildMetricCard("Lip Opening", '${((features['lip_opening'] ?? 0) * 100).toStringAsFixed(1)}%', "Measured", AppChipVariant.info),
        const SizedBox(height: 12),
        _buildMetricCard("Gingival Display", '${((features['gingival_display'] ?? 0) * 100).toStringAsFixed(1)}%', ((features['gingival_display'] ?? 0) < 0.1) ? "Normal" : "Excessive", AppChipVariant.error),
        const SizedBox(height: 12),
        _buildMetricCard("Buccal Corridor", '${((features['buccal_corridor'] ?? 0) * 100).toStringAsFixed(1)}%', "Measured", AppChipVariant.info),
        const SizedBox(height: 12),
        _buildMetricCard("Face Ratio", '${((features['face_ratio'] ?? 0) * 100).toStringAsFixed(1)}%', "Balanced", AppChipVariant.info),
      ],
    );
  }

  Widget _buildAnalysisSummary() {
    final isMobile = Responsive.isPhone(context);
    final severity = analysis['severity']?.toString() ?? analysis['overall_severity']?.toString() ?? 'Unknown';
    final treatmentPriority = analysis['treatment_priority']?.toString() ?? analysis['priority']?.toString() ?? 'Unknown';
    final smileScore = ((analysis['smile_score'] ?? 0) as num).toStringAsFixed(1);
    final grade = analysis['grade']?.toString() ?? '-';
    final level = analysis['level']?.toString() ?? '-';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _summaryRow('Overall Severity', severity, AppChipVariant.warning),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Treatment Priority', treatmentPriority, AppChipVariant.info),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Smile Score', smileScore, AppChipVariant.neutral),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Grade', grade, AppChipVariant.neutral),
          Divider(height: 24, color: ThemeColors.border(context)),
          _summaryRow('Smile Quality', level, AppChipVariant.success),
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