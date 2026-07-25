
import 'dart:typed_data';
import '../../widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/score_gauge.dart';
import '../../widgets/fade_slide.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/primary_hover_button.dart';
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
  String userName = 'User';
  String userEmail = '';


  Future<void> pickFromCamera() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedImage = image;

      selectedImageBytes = bytes;

      analysisData = null;
    });
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

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

        const SnackBar(
          content: Text(
            "Please select an image first",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userId =
      await SessionService.getUserId();

      debugPrint("Selected filename: ${selectedImage!.name}");

      final result =
      await ApiService.analyzeSmile(
        selectedImageBytes!,
        selectedImage!.name,
        userId,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;

        if (result['success']) {
          analysisData =
          result['data'];
          debugPrint("Analysis Data: $analysisData");
        }
      });

      if (!result['success']) {
        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(
            content: Text(
              result['error'],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
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

    final strengths = _asStringList(
      analysisData?['strengths'],
    );

    final improvements = _asStringList(
      analysisData?['improvements'],
    );

    final priority =
    analysisData?['priority']?.toString();
    final recommendations = _asStringList(analysisData?['recommendations']);
    final features = _asMap(
      analysisData?['features'],
    );

    return  Stack(
      children: [
        AppShell(
          currentRoute: '/analysis',
          title: 'Analysis',
          userName: userName,
          userEmail: userEmail,
          enableSearch: true,

          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              Responsive.pagePadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlide(
                  child: Container(
                    padding: EdgeInsets.all(
                      Responsive.cardPadding(context),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Responsive.cardRadius(context),
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.2),
                          blurRadius: 35,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Smile Analysis Engine',
                              style: TextStyle(
                                fontSize: Responsive.titleFont(context),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Upload smile images and generate real-time orthodontic facial symmetry evaluations powered by AI.',
                              style: TextStyle(
                                fontSize: Responsive.bodyFont(context),
                                height: 1.7,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: Responsive.sectionSpacing(context),
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: PrimaryHoverButton(
                            onPressed: pickImage,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt),
                                SizedBox(width: 10),
                                Text(
                                  'Start Scan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: Responsive.sectionSpacing(context),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final useSingleColumn = availableWidth < 800;

                    return Wrap(
                      spacing: Responsive.sectionSpacing(context),
                      runSpacing: Responsive.sectionSpacing(context),
                      children: [
                        SizedBox(
                          width: useSingleColumn
                              ? availableWidth
                              : availableWidth * 0.58,
                          child: Column(
                            children: [
                              FadeSlide(
                                delay: const Duration(milliseconds: 120),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Upload Patient Smile Image',
                                        style: TextStyle(
                                          fontSize: Responsive.headingFont(context),
                                          fontWeight: FontWeight.bold,
                                          color: ThemeColors.text(context),
                                        ),
                                      ),
                                      SizedBox(
                                        height: Responsive.sectionSpacing(context),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: ThemeColors.inputFill(context),
                                          borderRadius: BorderRadius.circular(
                                            Responsive.cardRadius(context),
                                          ),
                                          border: Border.all(
                                            color: ThemeColors.border(context),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                              const EdgeInsets.all(22),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFDBEAFE,
                                                ),
                                                borderRadius:
                                                BorderRadius.circular(22),
                                              ),
                                              child: const Icon(
                                                Icons.cloud_upload_rounded,
                                                size: 48,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              'Choose a smile image',
                                              style: TextStyle(
                                                fontSize: Responsive.headingFont(context),
                                                fontWeight: FontWeight.w700,
                                                color: ThemeColors.text(context),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Supported formats: JPG, PNG • Max 10MB',
                                              style: TextStyle(
                                                color: ThemeColors.secondaryText(context),
                                                fontSize: Responsive.bodyFont(context),
                                              ),
                                            ),
                                            const SizedBox(height: 28),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [

                                                Expanded(
                                                  child: ElevatedButton.icon(

                                                    onPressed: pickFromCamera,

                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(
                                                          0xFF2563EB),

                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 20,
                                                      ),

                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .circular(18),
                                                      ),
                                                    ),

                                                    icon: const Icon(
                                                      Icons.camera_alt,
                                                      color: Colors.white,
                                                    ),

                                                    label: const Text(
                                                      'Camera',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 16),

                                                Expanded(
                                                  child: ElevatedButton.icon(

                                                    onPressed: pickImage,

                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(
                                                          0xFF0F172A),

                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 20,
                                                      ),

                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .circular(18),
                                                      ),
                                                    ),

                                                    icon: const Icon(
                                                      Icons.photo_library,
                                                      color: Colors.white,
                                                    ),

                                                    label: const Text(
                                                      'Gallery',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      if (selectedImageBytes != null) ...[
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 700),
                                          tween: Tween(begin: 0.95, end: 1),
                                          curve: Curves.easeOut,
                                          builder: (context, scale, child) {
                                            return Transform.scale(
                                              scale: scale,
                                              child: Opacity(
                                                opacity: scale,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.memory(
                                              selectedImageBytes!,
                                              height: isPhone ? 180 : 220,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: isLoading
                                                ? null
                                                : () async {
                                              await analyzeImage();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                              const Color(0xFF0F172A),
                                              padding:
                                              const EdgeInsets.symmetric(
                                                vertical: 18,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(16),
                                              ),
                                            ),
                                            icon: isLoading
                                                ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child:
                                              CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                                : const Icon(
                                              Icons.analytics,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              isLoading
                                                  ? 'Analyzing...'
                                                  : 'Analyze Smile',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: ThemeColors.card(context),
                                            borderRadius:BorderRadius.circular(
                                              Responsive.cardRadius(context),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 18,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.analytics,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    "AI Feature Metrics",
                                                    style: TextStyle(
                                                      fontSize: Responsive.headingFont(context),
                                                      fontWeight: FontWeight.bold,
                                                      color: ThemeColors.text(context),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(
                                                height: Responsive.sectionSpacing(context),
                                              ),

                                              Wrap(
                                                spacing: isPhone ? 12 : 16,
                                                runSpacing: isPhone ? 12 : 16,

                                                children: [

                                                  _buildMetricTile(
                                                    "Smile Width",
                                                    features["smile_width"],
                                                    Colors.blue,
                                                  ),

                                                  _buildMetricTile(
                                                    "Lip Opening",
                                                    features["lip_opening"],
                                                    Colors.green,
                                                  ),

                                                  _buildMetricTile(
                                                    "Symmetry",
                                                    features["smile_symmetry"],
                                                    Colors.orange,
                                                  ),

                                                  _buildMetricTile(
                                                    "Smile Arc",
                                                    features["smile_arc"],
                                                    Colors.purple,
                                                  ),

                                                  _buildMetricTile(
                                                    "Midline",
                                                    features["midline_deviation"],
                                                    Colors.red,
                                                  ),

                                                  _buildMetricTile(
                                                    "Buccal Corridor",
                                                    features["buccal_corridor"],
                                                    Colors.teal,
                                                  ),

                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: analysisData == null
                                                ? null
                                                : () {
                                              Navigator.pushNamed(
                                                context,
                                                '/reports',
                                                arguments: {
                                                  'analysisData': analysisData,
                                                  'imageBytes': selectedImageBytes,
                                                },
                                              );
                                            },
                                            icon: const Icon(Icons.description),
                                            label: const Text("View Clinical Report"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2563EB),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: useSingleColumn
                              ? availableWidth
                              : availableWidth * 0.38,
                          child: analysisData == null
                              ? const SizedBox()
                              : Column(
                            children: [
                              FadeSlide(
                                delay: const Duration(milliseconds: 250),
                                child: Container(
                                  width: double.infinity,
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
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),

                                  child: Column(
                                    children: [

                                      const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFF2563EB),
                                        size: 42,
                                      ),

                                      const SizedBox(height: 18),

                                      Text(
                                        "AI Smile Assessment",
                                        style: TextStyle(
                                          fontSize: Responsive.headingFont(context),
                                          fontWeight: FontWeight.bold,
                                          color: ThemeColors.text(context),
                                        ),
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context),
                                      ),

                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(milliseconds: 800),
                                        curve: Curves.easeOutBack,
                                        tween: Tween(begin: 0.85, end: 1),
                                        builder: (context, scale, child) {
                                          return Transform.scale(
                                            scale: scale,
                                            child: child,
                                          );
                                        },
                                        child: SmileScoreGauge(
                                          score: (smileScore as num?)?.toDouble() ?? 0,
                                          level: level ?? "",
                                          size: isPhone ? 180 : 220,
                                        ),
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context) * 0.75,
                                      ),

                                      Divider(
                                        color: Colors.grey.shade300,
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context) * 0.75,
                                      ),
                                      Text(
                                        "AI Clinical Summary",
                                        style: TextStyle(
                                          fontSize: Responsive.bodyFont(context) + 2,
                                          fontWeight: FontWeight.w700,
                                          color: ThemeColors.text(context),
                                        ),
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context),
                                      ),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [

                                          Text(
                                            "Grade",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: ThemeColors.secondaryText(context),
                                            ),
                                          ),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDBEAFE),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              grade ?? "--",
                                              style:  TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.bold,
                                                fontSize: Responsive.bodyFont(context) + 2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context),
                                      ),

                                      Row(
                                        children: [

                                          Expanded(
                                            child: _buildMiniCard(
                                              "Severity",
                                              severity ?? "--",
                                            ),
                                          ),

                                          SizedBox(
                                            width: isPhone ? 8 : 12,
                                          ),

                                          Expanded(
                                            child: _buildMiniCard(
                                              "Priority",
                                              priority ?? "--",
                                            ),
                                          ),

                                        ],
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: Responsive.sectionSpacing(context),
                              ),

                              FadeSlide(
                                delay: const Duration(milliseconds: 350),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.card(context),
                                    borderRadius:BorderRadius.circular(
                                      Responsive.cardRadius(context),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.verified,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Smile Strengths",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context),
                                      ),

                                      if (strengths.isEmpty)
                                        const Text("No strengths available.")
                                      else
                                        ...strengths.map(
                                              (e) => Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    e,
                                                    style: TextStyle(
                                                      color: ThemeColors.text(context),
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: Responsive.sectionSpacing(context),
                              ),

                              FadeSlide(
                                delay: const Duration(milliseconds: 450),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.card(context),
                                    borderRadius:BorderRadius.circular(
                                      Responsive.cardRadius(context),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.trending_up,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Areas for Improvement",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context),
                                      ),

                                      if (improvements.isEmpty)
                                        const Text("No improvements suggested.")
                                      else
                                        ...improvements.map(
                                              (e) => Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.arrow_circle_up,
                                                  color: Colors.orange,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    e,
                                                    style: TextStyle(
                                                      color: ThemeColors.text(context),
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: Responsive.sectionSpacing(context),
                              ),

                              FadeSlide(
                                delay: const Duration(milliseconds: 550),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.card(context),
                                    borderRadius:BorderRadius.circular(
                                      Responsive.cardRadius(context),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.lightbulb,
                                            color: Colors.amber,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Recommendations",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(
                                        height: Responsive.sectionSpacing(context),
                                      ),

                                      if (recommendations.isEmpty)
                                        const Text("No recommendations available.")
                                      else
                                        ...recommendations.map(
                                              (e) => Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    e,
                                                    style: TextStyle(
                                                      color: ThemeColors.text(context),
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: Responsive.sectionSpacing(context),
                              ),


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

        LoadingOverlay(
          visible: isLoading,
        ),
      ],
    );
  }


  Widget _buildMiniCard(String title,
      String value,) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: ThemeColors.inputFill(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [

          Text(
            title,
            style: TextStyle(
              color: ThemeColors.secondaryText(context),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              color: ThemeColors.text(context),
              fontSize: Responsive.bodyFont(context) + 2,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
  Widget _buildMetricTile(
      String title,
      dynamic value,
      Color color,
      ) {
    if (value == null) {
      return SizedBox(
        width: Responsive.isPhone(context) ? double.infinity : 150,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ThemeColors.secondaryText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "--",
                style: TextStyle(
                  fontSize: Responsive.headingFont(context),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double number = value.toDouble();


    return SizedBox(
        width: Responsive.isPhone(context)
            ? double.infinity
            : 150,

        child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: number),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ThemeColors.secondaryText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatAnimatedValue(title, animatedValue),
                style: TextStyle(
                  fontSize: Responsive.headingFont(context),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
        ),
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
        return "${(number * 100).toStringAsFixed(2)}%";

      case "Smile Arc":
        return "${(number * 100).toStringAsFixed(2)}%";

      default:
        return number.toStringAsFixed(2);
    }
  }
}
