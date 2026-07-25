import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import 'hover_icon_button.dart';
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
  String? hoveredRoute;
  List<dynamic> notifications = [];

  bool isLoadingNotifications = false;
  int userId = 0;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _searchResults = [];
  bool _isSearching = false;

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

  static const List<_NavItem> navItems = [
    _NavItem('Dashboard', Icons.grid_view_rounded, '/dashboard'),
    _NavItem('Cases', Icons.folder_open_outlined, '/cases'),
    _NavItem('Analysis', Icons.analytics_outlined, '/analysis'),
    _NavItem('Reports', Icons.description_outlined, '/reports'),
    _NavItem('Settings', Icons.settings_outlined, '/settings'),
    _NavItem('Profile', Icons.person_outline, '/profile'),
    _NavItem('Help', Icons.help_outline, '/help'),
  ];
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
            offset: const Offset(0, 56),
            child: Material(
              elevation: 20,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 250,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.card(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeColors.border(context),
                  ),
                ),
                child: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
                    : _searchResults.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text("No patients found"),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final patient = _searchResults[index];

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(
                        patient["patient_name"] ?? "Unknown",
                      ),
                      subtitle: Text(
                        patient["created_at"] ?? "",
                      ),
                      onTap: () async {

                        _removeOverlay();
                        _searchController.clear();

                        final report = await ApiService.getReportById(
                          patient["id"],
                        );

                        if (!mounted) return;

                        Navigator.of(this.context).pushNamed(
                          "/reports",
                          arguments: {
                            "analysisData": report,
                          },
                        );
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: ThemeColors.background(context),

      drawer: isMobile ? _buildDrawer() : null,

      body: Row(
        children: [
          if (!isMobile && sidebarOpen)
            _buildDesktopSidebar(),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),

                Expanded(
                  child: SelectionArea(
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _loadNotifications() async {

    userId = await SessionService.getUserId();

    final result = await ApiService.getNotifications(
      userId: userId,
    );

    if (!mounted) return;

    if (result['success'] == true) {

      setState(() {
        notifications = result['notifications'];
      });

    }

  }
  Widget _buildNotificationIcon(String type) {

    switch (type) {

      case 'success':
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 22,
          ),
        );

      case 'warning':
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 22,
          ),
        );

      case 'error':
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFFFEBEE),
          child: Icon(
            Icons.error,
            color: Colors.red,
            size: 22,
          ),
        );

      default:
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE3F2FD),
          child: Icon(
            Icons.info,
            color: Color(0xFF2563EB),
            size: 22,
          ),
        );

    }

  }
  int get unreadNotificationCount {

    return notifications.where((notification) {

      return notification['is_read'] == false;

    }).length;

  }

  Widget _buildTopBar(bool isMobile) {
    return
      Container(
        constraints: BoxConstraints(
          minHeight: Responsive.topBarHeight(context),
        ),
        decoration:  BoxDecoration(
          color: ThemeColors.card(context),
          border: Border(
            bottom: BorderSide(
              color: ThemeColors.border(context),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: Icon(
                      Icons.menu,
                      size: 30,
                      color: ThemeColors.text(context),
                    ),
                    onPressed: () {
                      if (isMobile) {
                        Scaffold.of(context).openDrawer();
                      } else {
                        setState(() {
                          sidebarOpen = !sidebarOpen;
                        });
                      }
                    },
                  );
                },
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.appTitleFont(context),
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.text(context),
                  ),
                ),
              ),


              if (!isMobile) ...[
                CompositedTransformTarget(
                  link: _layerLink,
                  child: SizedBox(
                    width: Responsive.searchWidth(context),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ThemeColors.inputFill(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ThemeColors.border(context),
                            ),
                          ),
                          child:
                          TextField(
                            controller: _searchController,

                            style: TextStyle(
                              color: ThemeColors.text(context),
                            ),

                            onChanged: (value) async {
                              if (!widget.enableSearch) return;

                              if (value.trim().isEmpty) {
                                setState(() {
                                  _searchResults = [];
                                  _isSearching = false;
                                });
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
                            },
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(
                                color: ThemeColors.secondaryText(context),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: ThemeColors.secondaryText(context),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),



                        ],
                    ),   // Stack
                  ),     // SizedBox
                ),       // CompositedTransformTarget

                const SizedBox(width: 20),
              ],

              HoverIconButton(
                onTap: () async {

                  await _loadNotifications();
                  await ApiService.markNotificationsAsRead(
                    userId: userId,
                  );
                  await _loadNotifications();
                  if (!mounted) return;

                  showDialog(

                    context: context,

                    builder: (context) {

                      return AlertDialog(
                        backgroundColor: ThemeColors.card(context),

                        insetPadding: const EdgeInsets.all(24),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),

                        title: Row(
                          children: [

                            const Icon(
                              Icons.notifications,
                              color: Color(0xFF2563EB),
                              size: 26,
                            ),

                            const SizedBox(width: 10),

                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                notifications.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            IconButton(
                              icon: const Icon(Icons.close),
                              splashRadius: 20,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),

                          ],
                        ),

                        content: SizedBox(
                          width: 420,
                          child: notifications.isEmpty
                              ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No notifications yet.',
                              ),
                            ),
                          )
                              : SizedBox(
                            height: 350,
                            child: ListView.separated(

                              itemCount: notifications.length,

                              separatorBuilder: (context, index) =>
                              const Divider(height: 24),

                              itemBuilder: (context, index) {

                                final notification =
                                notifications[index];

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.card(context),
                                    borderRadius: BorderRadius.circular(16),

                                    border: Border.all(
                                      color: ThemeColors.border(context),
                                    ),

                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      _buildNotificationIcon(
                                        notification['type'] ?? 'info',
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [

                                            Text(
                                              notification['title'],
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: ThemeColors.text(context),
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              notification['message'],
                                              style: TextStyle(
                                                color: ThemeColors.secondaryText(context),
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            Row(
                                              children: [

                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: ThemeColors.secondaryText(context),
                                                ),

                                                const SizedBox(width: 5),

                                                Text(
                                                  notification['created_at'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: ThemeColors.secondaryText(context),
                                                  ),
                                                ),

                                              ],
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeColors.card(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ThemeColors.border(context),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Color(0xFF2563EB),
                      ),
                    ),

                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
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
              const SizedBox(width: 20),

              InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/profile',
                    );
                  },
                  child:
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: isMobile
                        ? CircleAvatar(
                      radius: Responsive.profileAvatarRadius(context),
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0]
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: Responsive.profileAvatarRadius(context),
                            backgroundColor: const Color(0xFF2563EB),
                            child: Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0]
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.userName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.userEmail,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeColors.secondaryText(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Orthodontist',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeColors.secondaryText(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
              ),
            ],
          ),),
      );
  }


  Widget _buildDrawer() {
    return Drawer(
      child: _buildSidebarContent(
        collapsed: false,
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 250,
      ),
      curve: Curves.easeInOut,
      width: sidebarOpen
          ? Responsive.sidebarWidth(context)
          : 0,
      child: Container(
        color: ThemeColors.card(context),
        child: Column(
          children: [
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),

                  const Expanded(
                    child: Text(
                      'SmileSync',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _buildSidebarContent(
                collapsed: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarContent({
    required bool collapsed,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      children: navItems.map((item) {
        final selected =
            widget.currentRoute == item.route;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,

            onEnter: (_) {
              setState(() {
                hoveredRoute = item.route;
              });
            },

            onExit: (_) {
              setState(() {
                hoveredRoute = null;
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFEAF1FF)
                    : hoveredRoute == item.route
                    ? ThemeColors.inputFill(context)
                    : Colors.transparent,

                borderRadius: BorderRadius.circular(14),
              ),

              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),


                leading: Icon(
                  item.icon,
                  size: Responsive.sidebarIconSize(context),
                  color: selected
                      ? const Color(0xFF2563EB)
                      : ThemeColors.secondaryText(context),
                ),


                title: collapsed
                    ? null
                    : Text(
                  item.label,
                  style: TextStyle(
                    fontSize: Responsive.sidebarFont(context),
                    fontWeight:
                    selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF2563EB)
                        : ThemeColors.text(context),
                  ),
                ),

                onTap: () {
                  if (widget.currentRoute ==
                      item.route) {
                    return;
                  }

                  Navigator.pushReplacementNamed(
                    context,
                    item.route,
                  );
                },
              ),),),
        );
      }).toList(),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavItem(
      this.label,
      this.icon,
      this.route,
      );
}