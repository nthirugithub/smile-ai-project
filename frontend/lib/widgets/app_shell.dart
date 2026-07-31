import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import 'hover_icon_button.dart';
import 'app_chip.dart';
import 'app_icon_container.dart';
import '../utils/responsive.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String title;
  final String userName;
  final String userEmail;
  final bool enableSearch;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.title,
    required this.userName,
    required this.userEmail,
    this.enableSearch = false,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool sidebarOpen = true;
  bool mobileSidebarOpen = false;
  String? hoveredRoute;
  List<dynamic> notifications = [];
  bool isLoadingNotifications = false;
  int userId = 0;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _mobileSearchOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final uId = await SessionService.getUserId();
      final fetched = await ApiService.getNotifications(userId: uId);
      if (!mounted) return;
      setState(() {
        userId = uId;
        notifications = (fetched['notifications'] as List<dynamic>?) ?? [];
      });
    } catch (e) {
      debugPrint("Notifications error: $e");
    }
  }

  static const List<_NavItem> navItems = [
    _NavItem('Dashboard', Icons.grid_view_rounded, '/dashboard'),
    _NavItem('Cases', Icons.folder_open_outlined, '/cases'),
    _NavItem('Analysis', Icons.analytics_outlined, '/analysis'),
    _NavItem('Reports', Icons.description_outlined, '/reports'),
    _NavItem('Settings', Icons.settings_outlined, '/settings'),
    _NavItem('Profile', Icons.person_outline, '/profile'),
    _NavItem('Help', Icons.help_outline, '/help'),
  ];

  Future<void> _handleSearchChanged(String value) async {
    if (!widget.enableSearch) return;
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }
    setState(() {
      _isSearching = true;
    });
    final results = await ApiService.searchPatients(value);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: Responsive.searchWidth(context),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: Material(
              elevation: 8,
              borderRadius: AppRadius.borderMd,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: ThemeColors.card(context),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: ThemeColors.border(context)),
                ),
                child: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : _searchResults.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No patient cases found.',
                    style: AppTypography.caption(context),
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: ThemeColors.border(context),
                  ),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item['patient_name'] ?? '',
                        style: AppTypography.label(context),
                      ),
                      subtitle: Text(
                        'ID: ${item['patient_id']} • Grade: ${item['grade'] ?? 'N/A'}',
                        style: AppTypography.caption(context),
                      ),
                      trailing: AppChip(
                        label: item['severity'] ?? 'Normal',
                        variant: _getSeverityVariant(item['severity']),
                      ),
                      onTap: () async {
                        _removeOverlay();
                        final navigator = Navigator.of(context);
                        try {
                          final reportId = item['id'];
                          if (reportId != null) {
                            final reportData = await ApiService.getReportById(reportId as int);
                            if (!mounted) return;
                            navigator.pushNamed(
                              '/reports',
                              arguments: {
                                'analysisData': reportData,
                              },
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          navigator.pushNamed(
                            '/reports',
                            arguments: {
                              'analysisData': item,
                            },
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  AppChipVariant _getSeverityVariant(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'severe':
        return AppChipVariant.error;
      case 'moderate':
        return AppChipVariant.warning;
      case 'mild':
      case 'normal':
        return AppChipVariant.success;
      default:
        return AppChipVariant.info;
    }
  }

  Widget _buildNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'analysis_complete':
      case 'success':
        return AppIconContainer(
          icon: Icons.check_circle_outline,
          size: AppIconSize.md,
          color: ThemeColors.success(context),
          backgroundColor: ThemeColors.successContainer(context),
        );
      case 'warning':
        return AppIconContainer(
          icon: Icons.warning_amber_outlined,
          size: AppIconSize.md,
          color: ThemeColors.warning(context),
          backgroundColor: ThemeColors.warningContainer(context),
        );
      case 'error':
        return AppIconContainer(
          icon: Icons.error_outline,
          size: AppIconSize.md,
          color: ThemeColors.error(context),
          backgroundColor: ThemeColors.errorContainer(context),
        );
      default:
        return AppIconContainer(
          icon: Icons.info_outline,
          size: AppIconSize.md,
          color: ThemeColors.info(context),
          backgroundColor: ThemeColors.infoContainer(context),
        );
    }
  }

  int get unreadNotificationCount {
    return notifications.where((notification) => notification['is_read'] == false).length;
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        Responsive.shellPadding(context),
        Responsive.shellPadding(context),
        Responsive.shellPadding(context),
        0,
      ),
      constraints: BoxConstraints(
        minHeight: Responsive.topBarHeight(context),
      ),
      decoration: BoxDecoration(
        color: ThemeColors.card(context),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: ThemeColors.border(context)),
        boxShadow: ThemeColors.shadowSm(context),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Menu Button OR Back Arrow (Mobile Search)
                if (isMobile && _mobileSearchOpen)
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.surfaceVariant(context),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: ThemeColors.border(context)),
                    ),
                    child: IconButton(
                      splashRadius: 20,
                      icon: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: ThemeColors.text(context),
                      ),
                      onPressed: () {
                        setState(() {
                          _mobileSearchOpen = false;
                          _searchController.clear();
                          _searchResults.clear();
                        });
                        _removeOverlay();
                      },
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.surfaceVariant(context),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: ThemeColors.border(context)),
                    ),
                    child: IconButton(
                      splashRadius: 20,
                      icon: Icon(
                        Icons.menu_rounded,
                        size: 20,
                        color: ThemeColors.text(context),
                      ),
                      onPressed: () {
                        if (isMobile) {
                          setState(() {
                            mobileSidebarOpen = !mobileSidebarOpen;
                          });
                        } else {
                          setState(() {
                            sidebarOpen = !sidebarOpen;
                          });
                        }
                      },
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isMobile && _mobileSearchOpen
                        ? CompositedTransformTarget(
                            key: const ValueKey('mobile-search-target'),
                            link: _layerLink,
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: AppTypography.body(context),
                              onChanged: _handleSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Search patients...',
                                hintStyle: AppTypography.caption(context),
                                border: InputBorder.none,
                              ),
                            ),
                          )
                        : Row(
                            key: const ValueKey('page-title-row'),
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  key: const ValueKey('app_shell_title_text'),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: AppTypography.sectionTitle(context),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (!isMobile) ...[
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: SizedBox(
                      width: Responsive.searchWidth(context) - 40,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: ThemeColors.inputFill(context),
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(color: ThemeColors.inputBorder(context)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTypography.body(context),
                          onChanged: _handleSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search patients, cases...',
                            hintStyle: AppTypography.caption(context),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: ThemeColors.secondaryText(context),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (isMobile && !_mobileSearchOpen)
                  HoverIconButton(
                    onTap: () {
                      setState(() {
                        _mobileSearchOpen = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ThemeColors.surfaceVariant(context),
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: ThemeColors.border(context)),
                      ),
                      child: Icon(
                        Icons.search,
                        size: 20,
                        color: ThemeColors.text(context),
                      ),
                    ),
                  ),

                if (isMobile && !_mobileSearchOpen) const SizedBox(width: 14),
                if (!(isMobile && _mobileSearchOpen))
                  HoverIconButton(
                    onTap: () async {
                      await _loadNotifications();
                      await ApiService.markNotificationsAsRead(userId: userId);
                      await _loadNotifications();
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: ThemeColors.card(context),
                            insetPadding: const EdgeInsets.all(24),
                            shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.notifications_none_outlined,
                                  color: ThemeColors.primary(context),
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Notifications',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.sectionTitle(context),
                                  ),
                                ),
                                AppChip(
                                  label: notifications.length.toString(),
                                  variant: AppChipVariant.info,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  splashRadius: 20,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            content: SizedBox(
                              width: Responsive.maxDialogWidth(context),
                              child: notifications.isEmpty
                                  ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No notifications yet.',
                                    style: AppTypography.body(context),
                                  ),
                                ),
                              )
                                  : SizedBox(
                                height: 350,
                                child: ListView.separated(
                                  itemCount: notifications.length,
                                  separatorBuilder: (context, index) => const Divider(height: 16),
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: ThemeColors.surfaceVariant(context),
                                        borderRadius: AppRadius.borderMd,
                                        border: Border.all(color: ThemeColors.border(context)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildNotificationIcon(notification['type'] ?? 'info'),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notification['title'] ?? '',
                                                  style: AppTypography.label(context),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notification['message'] ?? '',
                                                  style: AppTypography.caption(context),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  notification['created_at'] ?? '',
                                                  style: AppTypography.caption(context).copyWith(
                                                    color: ThemeColors.mutedText(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ThemeColors.surfaceVariant(context),
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: ThemeColors.border(context)),
                          ),
                          child: Icon(
                            Icons.notifications_none_outlined,
                            size: 20,
                            color: ThemeColors.text(context),
                          ),
                        ),
                        if (unreadNotificationCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: ThemeColors.error(context),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadNotificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (!(isMobile && _mobileSearchOpen))
                  const SizedBox(width: 14),

                // User Profile & Logout Popover
                if (!(isMobile && _mobileSearchOpen))
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'profile') {
                        Navigator.pushNamed(context, '/profile');
                      } else if (value == 'logout') {
                        await SessionService.logout();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18, color: ThemeColors.text(context)),
                            const SizedBox(width: 10),
                            Text('View Profile', style: AppTypography.body(context)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_outlined, size: 18, color: ThemeColors.error(context)),
                            const SizedBox(width: 10),
                            Text('Logout', style: AppTypography.body(context).copyWith(color: ThemeColors.error(context))),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ThemeColors.surfaceVariant(context),
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: ThemeColors.border(context)),
                      ),
                      child: isMobile
                          ? CircleAvatar(
                        radius: Responsive.profileAvatarRadius(context),
                        backgroundColor: ThemeColors.primary(context),
                        child: Text(
                          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: ThemeColors.primary(context),
                            child: Text(
                              widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.userName,
                                style: AppTypography.label(context),
                              ),
                              Text(
                                'Orthodontist',
                                style: AppTypography.caption(context),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_drop_down, color: ThemeColors.secondaryText(context), size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: sidebarOpen ? Responsive.sidebarWidth(context) : 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
        child: Container(
          decoration: BoxDecoration(
            color: ThemeColors.card(context),
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: ThemeColors.border(context)),
            boxShadow: ThemeColors.shadowSm(context),
          ),
          child: Column(
            children: [
              _buildSidebarHeader(),
              Expanded(
                child: _buildSidebarContent(collapsed: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconContainer(
                icon: Icons.health_and_safety_outlined,
                size: AppIconSize.md,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmileSync AI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ThemeColors.text(context),
                      ),
                    ),
                    Text(
                      'Clinical AI System',
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: ThemeColors.border(context),
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent({required bool collapsed}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        ...navItems.map((item) {
          final selected = widget.currentRoute == item.route;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => hoveredRoute = item.route),
              onExit: (_) => setState(() => hoveredRoute = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: selected
                      ? ThemeColors.primaryContainer(context)
                      : hoveredRoute == item.route
                      ? ThemeColors.surfaceVariant(context)
                      : Colors.transparent,
                  borderRadius: AppRadius.borderMd,
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                  leading: Icon(
                    item.icon,
                    size: 20,
                    color: selected
                        ? ThemeColors.primary(context)
                        : ThemeColors.secondaryText(context),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? ThemeColors.primary(context)
                          : ThemeColors.text(context),
                    ),
                  ),
                  onTap: () {
                    if (widget.currentRoute == item.route) return;
                    Navigator.pushReplacementNamed(context, item.route);
                  },
                ),
              ),
            ),
          );
        }),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1),
        ),
        ListTile(
          key: const ValueKey('logout_button_key'),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          leading: Icon(
            Icons.logout_outlined,
            size: 20,
            color: ThemeColors.error(context),
          ),
          title: Text(
            'Logout System',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeColors.error(context),
            ),
          ),
          onTap: () async {
            await SessionService.logout();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isPhone(context);

    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: Stack(
        children: [
          Row(
            children: [
              if (!isMobile) _buildDesktopSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isMobile),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(Responsive.shellInnerPadding(context)),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isMobile && mobileSidebarOpen) ...[
            GestureDetector(
              onTap: () => setState(() => mobileSidebarOpen = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            SafeArea(
              child: SizedBox(
                width: 280,
                child: Container(
                  color: ThemeColors.card(context),
                  child: Column(
                    children: [
                      _buildSidebarHeader(),
                      Expanded(
                        child: _buildSidebarContent(collapsed: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavItem(this.label, this.icon, this.route);
}