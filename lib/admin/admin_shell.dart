import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_questions_screen.dart';
import '../home_tab/screens/settings/settings_screen.dart';
import '../home_tab/screens/providers/theme_provider.dart';
import '../providers/firebase_auth_provider.dart';
import '../assignment_tab/ui/course_selector_screen.dart';

/// ─────────────────────────────────────────────────────────────────
///  ADMIN PORTAL SHELL
///  3 tabs: Dashboard · Questions · Settings
///  Only accessible to swasthikaponnusamy05@gmail.com
/// ─────────────────────────────────────────────────────────────────
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.code_rounded, label: 'Coding'),
    _NavItem(icon: Icons.quiz_rounded, label: 'Questions'),
    _NavItem(icon: Icons.assignment_rounded, label: 'Assignments'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<FirebaseAuthProvider>();
    final adminName = auth.userModel?.displayName ??
        auth.user?.displayName ??
        'Admin';

    final pages = [
      const AdminDashboardScreen(),
      const ManageQuestionsScreen(initialType: 'coding'),
      const ManageQuestionsScreen(),
      const AssignmentCourseSelector(isAdmin: true),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF0A0A1A) : const Color(0xFFF5F5FF),
      appBar: _buildAppBar(isDark, themeProvider, adminName),
      body: pages[_index],
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, ThemeProvider themeProvider, String adminName) {
    const titles = ['Dashboard', 'Coding Questions', 'Manage Questions', 'Assignments', 'Settings'];
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F0F2A) : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titles[_index],
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Logged in as $adminName',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _AdminAppBarButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: themeProvider.toggleTheme,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav(bool isDark) {
    const primary = Color(0xFFFF6B6B);
    final bg = isDark ? const Color(0xFF0F0F2A) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.10),
              blurRadius: 28,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (i) {
            return _AdminHoverNavButton(
              item: _navItems[i],
              index: i,
              currentIndex: _index,
              isDark: isDark,
              onTap: () => setState(() => _index = i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Admin nav button with hover scale + red glow
class _AdminHoverNavButton extends StatefulWidget {
  final _NavItem item;
  final int index;
  final int currentIndex;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminHoverNavButton({
    required this.item,
    required this.index,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AdminHoverNavButton> createState() => _AdminHoverNavButtonState();
}

class _AdminHoverNavButtonState extends State<_AdminHoverNavButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.currentIndex == widget.index;
    const primary = Color(0xFFFF6B6B);
    final unselected =
        widget.isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor =
        selected ? primary : (_hovered ? primary.withOpacity(0.75) : unselected);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 18 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? primary.withOpacity(0.12)
                : (_hovered ? primary.withOpacity(0.06) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _hovered || selected
                        ? [
                            BoxShadow(
                              color: primary.withOpacity(0.40),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(widget.item.icon, color: iconColor, size: 22),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(
                  widget.item.label,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Admin AppBar theme-toggle button with hover scale + red glow
class _AdminAppBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _AdminAppBarButton(
      {required this.icon, required this.onTap, required this.isDark});

  @override
  State<_AdminAppBarButton> createState() => _AdminAppBarButtonState();
}

class _AdminAppBarButtonState extends State<_AdminAppBarButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6B6B);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered
                ? accent.withOpacity(0.15)
                : (widget.isDark
                    ? Colors.white.withOpacity(0.07)
                    : accent.withOpacity(0.07)),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(widget.icon, color: accent, size: 20),
          ),
        ),
      ),
    );
  }
}
