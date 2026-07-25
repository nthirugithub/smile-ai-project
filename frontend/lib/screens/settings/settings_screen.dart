import 'package:flutter/material.dart';
import '../../widgets/app_shell.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../theme/theme_colors.dart';
import '../../services/backup_service.dart';
import '../../services/cache_service.dart';
import '../../utils/responsive.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  String userName = 'User';
  String userEmail = '';

  bool emailNotifications = true;
  bool autoBackupReports = false;

  String selectedTheme = 'System';
  String? hoveredTheme;
  String? hoveredAction;

  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController clinicController =
  TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    clinicController.dispose();
    super.dispose();
  }
  Future<void> loadUserData() async {
    final name = await SessionService.getName();
    final email = await SessionService.getEmail();

    setState(() {
      userName = name;
      userEmail = email;
    });
  }
  Future<void> loadSettings() async {

    final userId = await SessionService.getUserId();

    final response =
    await ApiService.getSettings(userId);

    if (response['success']) {

      final settings = response['settings'];

      setState(() {

        emailNotifications =
        settings['email_notifications'];

        autoBackupReports =
        settings['auto_backup_reports'];

        selectedTheme =
        settings['theme'];

      });

    }

  }
  Future<void> loadProfileData() async {

    try {

      final userId =
      await SessionService.getUserId();

      final data = await ApiService.getProfile(userId);

      if (data['success']) {

        final profile = data['profile'];

        setState(() {

          nameController.text =
              profile['name'] ?? '';

          emailController.text =
              profile['email'] ?? '';

          clinicController.text =
              profile['clinic'] ?? '';

        });

      }

    } catch (e) {

      debugPrint(
        e.toString(),
      );

    }

  }
  @override
  void initState() {
    super.initState();

    loadUserData();

    loadProfileData();

    loadSettings();
  }
  Future<void> _showChangePasswordDialog() async {
    bool hideCurrentPassword = true;
    bool hideNewPassword = true;
    bool hideConfirmPassword = true;
    bool isChangingPassword = false;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(

      context: context,

      builder: (context) {
        return StatefulBuilder(

          builder: (context, setDialogState) {
            return AlertDialog(

              title: const Text(
                'Change Password',
              ),

              content: SizedBox(

                width: 400,

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    TextField(

                      controller: currentPasswordController,

                      obscureText: hideCurrentPassword,

                      decoration: InputDecoration(

                        labelText: 'Current Password',

                        prefixIcon: const Icon(Icons.lock_outline),

                        suffixIcon: IconButton(

                          icon: Icon(

                            hideCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,

                          ),

                          onPressed: () {

                            setDialogState(() {

                              hideCurrentPassword =
                              !hideCurrentPassword;

                            });

                          },

                        ),

                      ),

                    ),

                    const SizedBox(height: 16),

                    TextField(

                      controller: newPasswordController,

                      obscureText: hideNewPassword,

                      decoration: InputDecoration(

                        labelText: 'New Password',

                        prefixIcon: const Icon(Icons.lock),

                        suffixIcon: IconButton(

                          icon: Icon(

                            hideNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,

                          ),

                          onPressed: () {

                            setDialogState(() {

                              hideNewPassword =
                              !hideNewPassword;

                            });

                          },

                        ),

                      ),

                    ),

                    const SizedBox(height: 16),

                    TextField(

                      controller: confirmPasswordController,

                      obscureText: hideConfirmPassword,

                      decoration: InputDecoration(

                        labelText: 'Confirm Password',

                        prefixIcon: const Icon(Icons.lock_reset),

                        suffixIcon: IconButton(

                          icon: Icon(

                            hideConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,

                          ),

                          onPressed: () {

                            setDialogState(() {

                              hideConfirmPassword =
                              !hideConfirmPassword;

                            });

                          },

                        ),

                      ),

                    ),

                  ],

                ),

              ),

              actions: [

                TextButton(

                  onPressed: () {
                    setDialogState(() {
                      isChangingPassword = false;
                    });
                    Navigator.pop(context);
                  },

                  child: const Text("Cancel"),

                ),

                ElevatedButton(

                  onPressed: isChangingPassword
                      ? null
                      : () async {
                    setDialogState(() {
                      isChangingPassword = true;
                    });
                    if (currentPasswordController.text.isEmpty ||
                        newPasswordController.text.isEmpty ||
                        confirmPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(

                        const SnackBar(
                          content: Text(
                            'Please fill all fields',
                          ),
                        ),

                      );
                      setDialogState(() {
                        isChangingPassword = false;
                      });

                      return;
                    }

                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(

                        const SnackBar(
                          content: Text(
                            'New passwords do not match',
                          ),
                        ),

                      );
                      setDialogState(() {
                        isChangingPassword = false;
                      });

                      return;
                    }

                    if (newPasswordController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(

                        const SnackBar(
                          content: Text(
                            'Password must be at least 8 characters',
                          ),
                        ),

                      );
                      setDialogState(() {
                        isChangingPassword = false;
                      });

                      return;
                    }

                    final userId =
                    await SessionService.getUserId();

                    final response =
                    await ApiService.changePassword(

                      userId: userId,

                      currentPassword:
                      currentPasswordController.text,

                      newPassword:
                      newPasswordController.text,

                    );

                    if (!mounted) return;

                    if (response['success']) {
                      setDialogState(() {
                        isChangingPassword = false;
                      });
                      Navigator.pop(this.context);

                      ScaffoldMessenger.of(this.context).showSnackBar(

                        const SnackBar(

                          content: Text(
                            'Password changed successfully',
                          ),

                        ),

                      );
                    } else {
                      ScaffoldMessenger.of(this.context).showSnackBar(

                        SnackBar(

                          content: Text(

                            response['error'] ??
                                'Failed to change password',

                          ),

                        ),

                      );
                    }
                  },

                  child: isChangingPassword
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Change",
                  ),

                ),

              ],

            );
          },

        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {

    return AppShell(
      currentRoute: '/settings',
      title: 'Settings',
      userName: userName,
      userEmail: userEmail,

      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          Responsive.pagePadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 30),

            Column(
              children: [
                _buildAccountCard(),
                const SizedBox(height: 24),
                _buildThemeCard(),
                const SizedBox(height: 24),
                _buildSecurityCard(),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                onPressed: () async {

                  final messenger = ScaffoldMessenger.of(context);

                  final userId =
                  await SessionService.getUserId();

                  final response =
                  await ApiService.updateSettings(

                    userId: userId,

                    emailNotifications:
                    emailNotifications,

                    autoBackupReports:
                    autoBackupReports,

                    theme:
                    selectedTheme,

                  );

                  if (!mounted) return;
                  await ThemeService.instance.setTheme(
                    selectedTheme,
                  );

                  if (response['success']) {

                    messenger.showSnackBar(

                      const SnackBar(
                        content: Text(
                          'Settings updated successfully',
                        ),
                      ),
                    );

                  } else {

                    messenger.showSnackBar(

                      SnackBar(
                        content: Text(
                          response['error'] ??
                              'Failed to update settings',
                        ),
                      ),
                    );

                  }

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isMobile = Responsive.isPhone(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        Responsive.cardPadding(context),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
        ),
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Text(
              nameController.text.trim().isNotEmpty
                  ? nameController.text.trim()[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            nameController.text.isEmpty
                ? 'User'
                : nameController.text,
            style: TextStyle(
              fontSize: Responsive.titleFont(context),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            'SmileSync User',
            style: TextStyle(
              color: Colors.white70,
              fontSize: Responsive.bodyFont(context),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text(
                  'AI Engine Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Text(
              nameController.text.trim().isNotEmpty
                  ? nameController.text.trim()[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text.isEmpty
                      ? 'User'
                      : nameController.text,
                  style: TextStyle(
                    fontSize: Responsive.titleFont(context),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'SmileSync User',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: Responsive.bodyFont(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text(
                  'AI Engine Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return _buildSectionCard(
      title: 'Account Settings',
      child: Column(
        children: [
          _buildLabelTextField('Doctor Name', nameController),
          const SizedBox(height: 18),
          _buildLabelTextField('Email Address', emailController),
          const SizedBox(height: 18),
          _buildLabelTextField('Clinic / Hospital', clinicController),
          const SizedBox(height: 24),
          _buildSwitchRow(
            title: 'Email Notifications',
            subtitle: 'Receive updates about analysis results',
            value: emailNotifications,
            onChanged: (value) {
              setState(() {
                emailNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard() {
    return _buildSectionCard(
      title: 'Theme Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose App Theme',
            style: TextStyle(
              fontSize: Responsive.bodyFont(context),
              fontWeight: FontWeight.w600,
              color: ThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildThemeOption('Light'),
              _buildThemeOption('Dark'),
              _buildThemeOption('System'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Theme preference is ready for future light/dark mode switching.',
            style: TextStyle(
              color: ThemeColors.secondaryText(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _buildSectionCard(
      title: 'Security & Storage',
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.cloud_upload_outlined,
            title: 'Backup Reports',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);

              final userId = await SessionService.getUserId();

              final result = await BackupService.backupReports(
                userId: userId,
              );

              if (!mounted) return;

              messenger.showSnackBar(

                SnackBar(

                  content: Text(
                    result['success']
                        ? result['message']
                        : result['error'],
                  ),

                ),

              );

            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.delete_outline,
            title: 'Clear Local Cache',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);

              final confirm = await showDialog<bool>(

                context: context,

                builder: (context) {

                  return AlertDialog(

                    title: const Text(
                      'Clear Local Cache',
                    ),

                    content: const Text(
                      'This will remove temporary files stored on this device.\n\n'
                          'Your reports, account, and settings will not be affected.',
                    ),

                    actions: [

                      TextButton(

                        onPressed: () {
                          Navigator.pop(context, false);
                        },

                        child: const Text('Cancel'),

                      ),

                      ElevatedButton(

                        onPressed: () {
                          Navigator.pop(context, true);
                        },

                        child: const Text('Clear'),

                      ),

                    ],

                  );

                },

              );

              if (confirm != true) return;

              final result = await CacheService.clearCache();

              if (!mounted) return;

              messenger.showSnackBar(

                SnackBar(

                  content: Text(
                    result['success']
                        ? result['message']
                        : result['error'],
                  ),

                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ThemeColors.card(context),
        borderRadius: BorderRadius.circular(28),
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
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.headingFont(context),
              fontWeight: FontWeight.bold,
              color: ThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildLabelTextField(
      String label,
      TextEditingController controller,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: TextStyle(
            color: ThemeColors.text(context),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: ThemeColors.inputFill(context),
            hintStyle: TextStyle(
              color: ThemeColors.text(context),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: ThemeColors.border(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: ThemeColors.primary(context),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: Responsive.bodyFont(context),
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.text(context)
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: ThemeColors.text(context),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF2563EB),
          onChanged: onChanged,
        )
      ],
    );
  }

  Widget _buildThemeOption(String label) {
    final bool selected = selectedTheme == label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredTheme = label),
      onExit: (_) => setState(() => hoveredTheme = null),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTheme = label;
          });
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: hoveredTheme == label ? 1.03 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFFEAF1FF)
                  : hoveredTheme == label
                  ? ThemeColors.inputFill(context)
                  : ThemeColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected || hoveredTheme == label
                    ? const Color(0xFF2563EB)
                    : ThemeColors.border(context),
              ),
              boxShadow: hoveredTheme == label
                  ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF2563EB)
                    : ThemeColors.text(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredAction = title),
      onExit: (_) => setState(() => hoveredAction = null),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: hoveredAction == title
                ? ThemeColors.inputFill(context)
                : ThemeColors.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hoveredAction == title
                  ? const Color(0xFF2563EB)
                  : ThemeColors.border(context),
            ),
            boxShadow: hoveredAction == title
                ? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: hoveredAction == title ? 1.12 : 1,
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.text(context),
                ),
              ),
            ],
          ),
        ),),
    );
  }
}