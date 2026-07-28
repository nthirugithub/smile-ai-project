import 'package:flutter/material.dart';
import '../../widgets/app_shell.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../theme/theme_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon_container.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
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
  bool isSaving = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController clinicController = TextEditingController();

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

  Future<void> loadProfileData() async {
    try {
      final userId = await SessionService.getUserId();
      final data = await ApiService.getProfile(userId);
      if (data['success']) {
        final profile = data['profile'];
        setState(() {
          nameController.text = profile['name'] ?? '';
          emailController.text = profile['email'] ?? '';
          clinicController.text = profile['clinic'] ?? '';
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadSettings() async {
    final userId = await SessionService.getUserId();
    final response = await ApiService.getSettings(userId);
    if (response['success']) {
      final settings = response['settings'];
      setState(() {
        emailNotifications = settings['email_notifications'] ?? true;
        autoBackupReports = settings['auto_backup_reports'] ?? false;
        selectedTheme = settings['theme'] ?? 'System';
      });
    }
  }

  Future<void> updateSettings() async {
    setState(() => isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final userId = await SessionService.getUserId();
    final response = await ApiService.updateSettings(
      userId: userId,
      emailNotifications: emailNotifications,
      autoBackupReports: autoBackupReports,
      theme: selectedTheme,
    );
    await ThemeService.instance.setTheme(selectedTheme);
    setState(() => isSaving = false);

    if (response['success']) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings updated successfully')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(response['error'] ?? 'Failed to update settings')),
      );
    }
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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ThemeColors.card(context),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
              title: Text('Change Password', style: AppTypography.sectionTitle(context)),
              content: SizedBox(
                width: Responsive.maxDialogWidth(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: hideCurrentPassword,
                      style: AppTypography.body(context),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(hideCurrentPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => hideCurrentPassword = !hideCurrentPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newPasswordController,
                      obscureText: hideNewPassword,
                      style: AppTypography.body(context),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(hideNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => hideNewPassword = !hideNewPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: hideConfirmPassword,
                      style: AppTypography.body(context),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(hideConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => hideConfirmPassword = !hideConfirmPassword),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (currentPasswordController.text.isEmpty ||
                        newPasswordController.text.isEmpty ||
                        confirmPasswordController.text.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    if (newPasswordController.text != confirmPasswordController.text) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('New passwords do not match')),
                      );
                      return;
                    }
                    if (newPasswordController.text.length < 8) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Password must be at least 8 characters')),
                      );
                      return;
                    }

                    setDialogState(() => isChangingPassword = true);
                    final userId = await SessionService.getUserId();
                    final response = await ApiService.changePassword(
                      userId: userId,
                      currentPassword: currentPasswordController.text,
                      newPassword: newPasswordController.text,
                    );

                    if (!mounted) return;
                    Navigator.pop(dialogContext);

                    if (response['success']) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Password changed successfully')),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(response['error'] ?? 'Failed to change password')),
                      );
                    }
                  },
                  child: isChangingPassword
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadProfileData();
    loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/settings',
      title: 'Application Settings',
      userName: userName,
      userEmail: userEmail,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings & Preferences', style: AppTypography.pageTitle(context)),
            const SizedBox(height: 4),
            Text(
              'Configure appearance, notifications, backup preferences, and system storage.',
              style: AppTypography.body(context).copyWith(
                color: ThemeColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 24),

            // Account Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIconContainer(icon: Icons.person_outline, size: AppIconSize.md),
                      const SizedBox(width: 12),
                      Text('Account Details', style: AppTypography.sectionTitle(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Doctor Name', controller: nameController, enabled: false),
                  const SizedBox(height: 12),
                  CustomTextField(label: 'Email Address', controller: emailController, enabled: false),
                  const SizedBox(height: 12),
                  CustomTextField(label: 'Clinic / Hospital', controller: clinicController, enabled: false),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Theme Preferences
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIconContainer(icon: Icons.palette_outlined, size: AppIconSize.md),
                      const SizedBox(width: 12),
                      Text('Appearance & Theme', style: AppTypography.sectionTitle(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Responsive.isPhone(context)
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildThemeChip('System', Icons.settings_brightness_outlined),
                            _buildThemeChip('Light', Icons.light_mode_outlined),
                            _buildThemeChip('Dark', Icons.dark_mode_outlined),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildThemeChip('System', Icons.settings_brightness_outlined)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildThemeChip('Light', Icons.light_mode_outlined)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildThemeChip('Dark', Icons.dark_mode_outlined)),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Notifications & Workflow
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIconContainer(icon: Icons.notifications_none_outlined, size: AppIconSize.md),
                      const SizedBox(width: 12),
                      Text('Notifications & Workflow', style: AppTypography.sectionTitle(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Email Notifications', style: AppTypography.label(context)),
                    subtitle: Text('Receive email alerts when clinical analyses complete.', style: AppTypography.caption(context)),
                    value: emailNotifications,
                    activeTrackColor: ThemeColors.primary(context),
                    onChanged: (val) {
                      setState(() => emailNotifications = val);
                      updateSettings();
                    },
                  ),
                  const Divider(height: 16),
                  SwitchListTile(
                    title: Text('Automated Cloud Backup', style: AppTypography.label(context)),
                    subtitle: Text('Automatically sync generated PDF reports to cloud storage.', style: AppTypography.caption(context)),
                    value: autoBackupReports,
                    activeTrackColor: ThemeColors.primary(context),
                    onChanged: (val) {
                      setState(() => autoBackupReports = val);
                      updateSettings();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Data & Cache Management
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIconContainer(
                        icon: Icons.security_outlined,
                        size: Responsive.isPhone(context) ? AppIconSize.sm : AppIconSize.md,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Security & Storage Actions',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sectionTitle(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Responsive.isPhone(context)
                      ? Column(
                          children: [
                            PrimaryButton(
                              label: 'Change Password',
                              icon: Icons.lock_outline,
                              variant: PrimaryButtonVariant.outlined,
                              onPressed: _showChangePasswordDialog,
                            ),
                            const SizedBox(height: 10),
                            PrimaryButton(
                              label: 'Backup Reports',
                              icon: Icons.cloud_upload_outlined,
                              variant: PrimaryButtonVariant.outlined,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final userId = await SessionService.getUserId();
                                final result = await BackupService.backupReports(userId: userId);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(result['success'] ? (result['message'] ?? 'Backup completed') : (result['error'] ?? 'Backup failed')),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            PrimaryButton(
                              label: 'Clear Local Cache',
                              icon: Icons.cleaning_services_outlined,
                              variant: PrimaryButtonVariant.outlined,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogCtx) {
                                    return AlertDialog(
                                      backgroundColor: ThemeColors.card(context),
                                      title: const Text('Clear Local Cache'),
                                      content: const Text(
                                        'This will remove temporary files stored on this device.\n\nYour reports, account, and settings will not be affected.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogCtx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(dialogCtx, true),
                                          child: const Text('Clear'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm != true) return;
                                final result = await CacheService.clearCache();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(result['success'] ? (result['message'] ?? 'Cache cleared') : (result['error'] ?? 'Cache clear failed')),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Change Password',
                                icon: Icons.lock_outline,
                                variant: PrimaryButtonVariant.outlined,
                                onPressed: _showChangePasswordDialog,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Backup Reports',
                                icon: Icons.cloud_upload_outlined,
                                variant: PrimaryButtonVariant.outlined,
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final userId = await SessionService.getUserId();
                                  final result = await BackupService.backupReports(userId: userId);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(result['success'] ? (result['message'] ?? 'Backup completed') : (result['error'] ?? 'Backup failed')),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Clear Local Cache',
                                icon: Icons.cleaning_services_outlined,
                                variant: PrimaryButtonVariant.outlined,
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogCtx) {
                                      return AlertDialog(
                                        backgroundColor: ThemeColors.card(context),
                                        title: const Text('Clear Local Cache'),
                                        content: const Text(
                                          'This will remove temporary files stored on this device.\n\nYour reports, account, and settings will not be affected.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogCtx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(dialogCtx, true),
                                            child: const Text('Clear'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirm != true) return;
                                  final result = await CacheService.clearCache();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(result['success'] ? (result['message'] ?? 'Cache cleared') : (result['error'] ?? 'Cache clear failed')),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Settings Action Button
            PrimaryButton(
              label: 'Save Settings',
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: updateSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(String themeName, IconData icon) {
    final isSelected = selectedTheme == themeName;
    return AppChip(
      label: themeName,
      icon: icon,
      isSelected: isSelected,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () {
        setState(() => selectedTheme = themeName);
        updateSettings();
      },
    );
  }
}