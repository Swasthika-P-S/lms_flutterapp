import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'package:learnhub/quiz_tab/courses_screen.dart';
import '../app_tab/screens/course_listing_screen.dart';
import '../assignment_tab/ui/course_selector_screen.dart';
import '../home_tab/screens/settings/settings_screen.dart';
import '../widgets/chatbot_widget.dart';
import '../providers/firebase_auth_provider.dart';
import '../providers/locale_provider.dart';
import '../home_tab/screens/providers/theme_provider.dart';
import '../config/api_keys.dart';
import '../providers/chatbot_provider.dart';
import '../services/voice_service.dart';
import '../services/voice_command_handler.dart';

/// ─────────────────────────────────────────────────────────────────
///  STUDENT PORTAL SHELL
///  Wraps all 5 student tabs with a floating AI chatbot.
///  Role guard: only non-admin users reach this widget.
/// ─────────────────────────────────────────────────────────────────
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Initialize chatbot with API key
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatbotProvider>().initialize(ApiKeys.groqApiKey);
    });
  }

  void _onVoiceButtonTapped() {
    final voiceService = context.read<VoiceService>();
    if (voiceService.isListening) {
      voiceService.stopListening();
    } else {
      voiceService.startListening((command) {
        VoiceCommandHandler.handleCommand(command, context, (tabIndex) {
          setState(() => _index = tabIndex);
        });
      });
    }
  }

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'nav_home'),
    _NavItem(icon: Icons.school_rounded, label: 'nav_courses'),
    _NavItem(icon: Icons.code_rounded, label: 'Coding'),
    _NavItem(icon: Icons.quiz_rounded, label: 'nav_quizzes'),
    _NavItem(icon: Icons.assignment_rounded, label: 'nav_tasks'),
    _NavItem(icon: Icons.person_rounded, label: 'nav_profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<FirebaseAuthProvider>();
    final userName = auth.userModel?.displayName ??
        auth.user?.displayName ??
        'Student';

    final pages = [
      const StudentDashboardScreen(),
      const CourseListingScreen(),
      const CoursesScreen(questionTypeFilter: 'coding'),
      const CoursesScreen(),
      const AssignmentCourseSelector(isAdmin: false),
      const StudentProfileScreen(),
    ];

    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F4FF);

    return Scaffold(
      extendBody: true,
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, themeProvider),
      body: Stack(
        children: [
          // Tab body fills entire screen (behind chatbot)
          pages[_index],
          // Persistent floating AI assistant
          const Positioned.fill(
            child: ChatbotWidget(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark, ThemeProvider themeProvider) {
    final localeProvider = context.watch<LocaleProvider>();
    final titles = [
      localeProvider.t('nav_home'),
      localeProvider.t('nav_courses'),
      'Coding Challenges',
      localeProvider.t('nav_quizzes'),
      localeProvider.t('nav_tasks'),
      localeProvider.t('nav_profile'),
    ];
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF13132A) : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        titles[_index],
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        // ── Voice mic button — only shown when Voice Search is enabled ──
        Consumer<VoiceService>(
          builder: (context, voiceService, _) {
            if (!voiceService.isVoiceEnabled) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AppBarButton(
                  icon: voiceService.isListening
                      ? Icons.mic
                      : Icons.mic_none_rounded,
                  onTap: _onVoiceButtonTapped,
                  isDark: isDark,
                  activeColor: voiceService.isListening ? Colors.red : null,
                ),
                const SizedBox(width: 4),
              ],
            );
          },
        ),
        _AppBarButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: themeProvider.toggleTheme,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── FLOATING BOTTOM NAV ──────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    final bg = isDark ? const Color(0xFF13132A) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _navItems.length,
            (i) => _HoverNavButton(
              item: _navItems[i],
              index: i,
              currentIndex: _index,
              isDark: isDark,
              onTap: () => setState(() => _index = i),
            ),
          ),
        ),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Animated nav button with hover scale + glow effect (Web-friendly)
class _HoverNavButton extends StatefulWidget {
  final _NavItem item;
  final int index;
  final int currentIndex;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverNavButton({
    required this.item,
    required this.index,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HoverNavButton> createState() => _HoverNavButtonState();
}

class _HoverNavButtonState extends State<_HoverNavButton>
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

  void _onEnter(_) {
    setState(() => _hovered = true);
    _ctrl.forward();
  }

  void _onExit(_) {
    setState(() => _hovered = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.currentIndex == widget.index;
    const primary = Color(0xFF6C63FF);
    final unselected =
        widget.isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor = selected ? primary : (_hovered ? primary.withOpacity(0.75) : unselected);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
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
                              color: primary.withOpacity(0.35),
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
                  context.read<LocaleProvider>().t(widget.item.label),
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

class _AppBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? activeColor;
  const _AppBarButton(
      {required this.icon, required this.onTap, required this.isDark, this.activeColor});

  @override
  State<_AppBarButton> createState() => _AppBarButtonState();
}

class _AppBarButtonState extends State<_AppBarButton>
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
    const primary = Color(0xFF6C63FF);
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered
                ? primary.withOpacity(0.15)
                : (widget.isDark
                    ? Colors.white.withOpacity(0.07)
                    : primary.withOpacity(0.07)),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(widget.icon, color: widget.activeColor ?? primary, size: 20),
          ),
        ),
      ),
    );
  }
}
