import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/patient_information_modal.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/theme_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon_container.dart';
import '../../widgets/score_gauge.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/primary_button.dart';
import '../../utils/responsive.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  bool isLoading = false;
  Map<String, dynamic>? analysisData;
  Map<String, dynamic>? patientData;
  String userName = 'User';
  String userEmail = '';

  Future<void> pickFromCamera() async {
    if (isLoading) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
      analysisData = null;
    });
  }

  Future<void> pickImage() async {
    if (isLoading) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
      analysisData = null;
    });
  }

  Future<void> analyzeImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    if (patientData == null || patientData!['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete patient details first")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userId = await SessionService.getUserId();
      final result = await ApiService.analyzeSmile(
        selectedImageBytes!,
        selectedImage!.name,
        userId,
        patientId: patientData!['id'],
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (result['success']) {
          analysisData = result['data'];
        }
      });

      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Analysis failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final severity = analysisData?['severity']?.toString();
    final smileScore = analysisData?['smile_score'];
    final grade = analysisData?['grade']?.toString();
    final level = analysisData?['level']?.toString();
    final isPhone = Responsive.isPhone(context);

    final strengths = _asStringList(analysisData?['strengths']);
    final improvements = _asStringList(analysisData?['improvements']);
    final priority = analysisData?['priority']?.toString();
    final recommendations = _asStringList(analysisData?['recommendations']);
    final features = _asMap(analysisData?['features']);

    return Stack(
      children: [
        AppShell(
          currentRoute: '/analysis',
          title: 'AI Diagnostic Engine',
          userName: userName,
          userEmail: userEmail,
          enableSearch: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Clinical Banner Card
                AppCard(
                  color: ThemeColors.primaryContainer(context),
                  border: BorderSide(color: ThemeColors.primary(context).withValues(alpha: 0.2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical AI Diagnostic Suite',
                        style: AppTypography.pageTitle(context).copyWith(
                          color: ThemeColors.onPrimaryContainer(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload patient smile imagery to extract high-precision facial landmarks, symmetry metrics, and AI orthodontic assessments.',
                        style: AppTypography.body(context).copyWith(
                          color: ThemeColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final useSingleColumn = availableWidth < 800;

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        SizedBox(
                          width: useSingleColumn ? availableWidth : availableWidth * 0.56,
                          child: Column(
                            children: [
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Patient Smile Image Capture',
                                      style: AppTypography.sectionTitle(context),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: ThemeColors.surfaceVariant(context),
                                        borderRadius: AppRadius.borderMd,
                                        border: Border.all(
                                          color: ThemeColors.border(context),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          AppIconContainer(
                                            icon: Icons.cloud_upload_outlined,
                                            size: AppIconSize.lg,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Select or Capture Patient Image',
                                            style: AppTypography.cardTitle(context),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Supported formats: JPG, PNG • High Resolution Recommended',
                                            style: AppTypography.caption(context),
                                          ),
                                          const SizedBox(height: 20),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isPhone = Responsive.isPhone(context);
                                              final availableWidth = constraints.maxWidth;
                                              final useVertical = isPhone && (availableWidth < 300);

                                              if (useVertical) {
                                                return Column(
                                                  children: [
                                                    PrimaryButton(
                                                      label: 'Camera',
                                                      icon: Icons.camera_alt_outlined,
                                                      variant: PrimaryButtonVariant.outlined,
                                                      onPressed: pickFromCamera,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    PrimaryButton(
                                                      label: 'Gallery',
                                                      icon: Icons.photo_library_outlined,
                                                      variant: PrimaryButtonVariant.outlined,
                                                      onPressed: pickImage,
                                                    ),
                                                  ],
                                                );
                                              }

                                              return Row(
                                                children: [
                                                  Expanded(
                                                    child: PrimaryButton(
                                                      label: 'Camera',
                                                      icon: Icons.camera_alt_outlined,
                                                      variant: PrimaryButtonVariant.outlined,
                                                      onPressed: pickFromCamera,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: PrimaryButton(
                                                      label: 'Gallery',
                                                      icon: Icons.photo_library_outlined,
                                                      variant: PrimaryButtonVariant.outlined,
                                                      onPressed: pickImage,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    if (selectedImageBytes != null) ...[
                                      ClipRRect(
                                        borderRadius: AppRadius.borderMd,
                                        child: Container(
                                          height: isPhone ? 200 : 260,
                                          width: double.infinity,
                                          color: ThemeColors.surfaceVariant(context),
                                          child: Image.memory(
                                            selectedImageBytes!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (patientData == null) ...[
                                        PrimaryButton(
                                          label: 'Complete Patient Details',
                                          icon: Icons.person_add_outlined,
                                          onPressed: isLoading
                                              ? null
                                              : () => PatientInformationModal.show(
                                                    context,
                                                    initialData: patientData,
                                                    onSaved: (p) {
                                                      setState(() {
                                                        patientData = p;
                                                      });
                                                    },
                                                  ),
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: ThemeColors.success(context).withValues(alpha: 0.1),
                                            borderRadius: AppRadius.borderMd,
                                            border: Border.all(color: ThemeColors.success(context).withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle_outline, color: ThemeColors.success(context), size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Patient Information Saved',
                                                      style: AppTypography.caption(context).copyWith(
                                                        color: ThemeColors.success(context),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${patientData!['full_name']} (${patientData!['patient_code'] ?? 'P-${patientData!['id']}'})',
                                                      style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              TextButton.icon(
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                label: const Text('Edit Details'),
                                                onPressed: isLoading
                                                    ? null
                                                    : () => PatientInformationModal.show(
                                                          context,
                                                          initialData: patientData,
                                                          onSaved: (p) {
                                                            setState(() {
                                                              patientData = p;
                                                            });
                                                          },
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        PrimaryButton(
                                          label: 'Run AI Diagnostic Scan',
                                          icon: Icons.analytics_outlined,
                                          isLoading: isLoading,
                                          loadingLabel: 'Scanning Image...',
                                          onPressed: isLoading ? null : analyzeImage,
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),

                              if (features.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          AppIconContainer(
                                            icon: Icons.straighten_outlined,
                                            size: isPhone ? AppIconSize.sm : AppIconSize.md,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Extracted Landmark Metrics',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.sectionTitle(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          _buildMetricTile('Smile Width', features["smile_width"], ThemeColors.info(context)),
                                          _buildMetricTile('Lip Opening', features["lip_opening"], ThemeColors.success(context)),
                                          _buildMetricTile('Symmetry', features["smile_symmetry"], ThemeColors.warning(context)),
                                          _buildMetricTile('Smile Arc', features["smile_arc"], ThemeColors.primary(context)),
                                          _buildMetricTile('Midline', features["midline_deviation"], ThemeColors.error(context)),
                                          _buildMetricTile('Buccal Corridor', features["buccal_corridor"], ThemeColors.secondary(context)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(
                          width: useSingleColumn ? availableWidth : availableWidth * 0.40,
                          child: analysisData == null
                              ? AppCard(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: Column(
                                        children: [
                                          AppIconContainer(
                                            icon: Icons.analytics_outlined,
                                            size: AppIconSize.lg,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Awaiting Image Scan',
                                            style: AppTypography.cardTitle(context),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Upload patient image to generate real-time clinical score and symmetry metrics.',
                                            textAlign: TextAlign.center,
                                            style: AppTypography.caption(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    AppCard(
                                      child: Column(
                                        children: [
                                          Text(
                                            'AI Smile Assessment Score',
                                            style: AppTypography.cardTitle(context),
                                          ),
                                          const SizedBox(height: 20),
                                          SmileScoreGauge(
                                            score: (smileScore as num?)?.toDouble() ?? 0,
                                            level: level ?? "",
                                            size: isPhone ? 180 : 200,
                                          ),
                                          const SizedBox(height: 20),
                                          Divider(color: ThemeColors.border(context)),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Classification Grade', style: AppTypography.body(context)),
                                              AppChip(
                                                label: grade ?? "--",
                                                variant: AppChipVariant.info,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(child: _buildMiniCard("Severity", severity ?? "--")),
                                              const SizedBox(width: 12),
                                              Expanded(child: _buildMiniCard("Priority", priority ?? "--")),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          PrimaryButton(
                                            label: isPhone ? 'Clinical Report' : 'Open Complete Clinical Report',
                                            icon: Icons.description_outlined,
                                            variant: PrimaryButtonVariant.outlined,
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/reports',
                                                arguments: {
                                                  'analysisData': analysisData,
                                                  'imageBytes': selectedImageBytes,
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    if (strengths.isNotEmpty)
                                      AppCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.check_circle_outline, color: ThemeColors.success(context), size: 20),
                                                const SizedBox(width: 8),
                                                Text('Smile Strengths', style: AppTypography.cardTitle(context)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            ...strengths.map(
                                              (e) => Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.check, color: ThemeColors.success(context), size: 16),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(e, style: AppTypography.body(context))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    if (improvements.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      AppCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.trending_up, color: ThemeColors.warning(context), size: 20),
                                                const SizedBox(width: 8),
                                                Text('Areas for Improvement', style: AppTypography.cardTitle(context)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            ...improvements.map(
                                              (e) => Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.arrow_forward, color: ThemeColors.warning(context), size: 16),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(e, style: AppTypography.body(context))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    if (recommendations.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      AppCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.lightbulb_outline, color: ThemeColors.info(context), size: 20),
                                                const SizedBox(width: 8),
                                                Text('Clinical Recommendations', style: AppTypography.cardTitle(context)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            ...recommendations.map(
                                              (e) => Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.circle, color: ThemeColors.info(context), size: 6),
                                                    const SizedBox(width: 10),
                                                    Expanded(child: Text(e, style: AppTypography.body(context))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        LoadingOverlay(visible: isLoading),
      ],
    );
  }

  Widget _buildMiniCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: ThemeColors.surfaceVariant(context),
        borderRadius: AppRadius.borderMd,
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(context),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, dynamic value, Color color) {
    final double number = (value != null) ? value.toDouble() : 0.0;
    final formattedValue = value == null ? "--" : _formatAnimatedValue(title, number);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = Responsive.isPhone(context);
        final parentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (MediaQuery.of(context).size.width - 64);
        final tileWidth = isPhone ? ((parentWidth - 12) / 2).clamp(120.0, 200.0) : 140.0;

        return SizedBox(
          width: tileWidth,
          child: Container(
            padding: EdgeInsets.all(isPhone ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(context),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedValue,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isPhone ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAnimatedValue(String title, double number) {
    switch (title) {
      case "Smile Width":
      case "Lip Opening":
      case "Buccal Corridor":
        return "${(number * 100).toStringAsFixed(1)}%";
      case "Symmetry":
        return "${((1 - number) * 100).toStringAsFixed(1)}%";
      case "Midline":
      case "Smile Arc":
        return "${(number * 100).toStringAsFixed(2)}%";
      default:
        return number.toStringAsFixed(2);
    }
  }
}
