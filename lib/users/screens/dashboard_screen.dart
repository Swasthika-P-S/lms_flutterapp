import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/firebase_auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/mongo_service.dart';
import '../../models/course_model.dart';

/// Premium student home dashboard with greeting, stats, and quick access.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  List<CourseModel> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courses = await MongoService.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load courses: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<FirebaseAuthProvider>();
    final user = auth.userModel;
    final firebaseUser = auth.user;
    final name = user?.displayName ?? firebaseUser?.displayName ?? 'Student';
    final email = user?.email ?? firebaseUser?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    final bg1 = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F4FF);
    final bg2 = isDark ? const Color(0xFF12122A) : const Color(0xFFEBF3FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F4FF),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg1, bg2],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── GREETING HEADER ──────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader(context, name, email, initials, isDark)),

                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // ── PROGRESS BANNER ─────────────────────────────────────
                  SliverToBoxAdapter(child: _buildProgressBanner(context, isDark)),

                  // ── QUICK STATS ─────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildStats(context, isDark)),

                  // ── QUICK ACCESS CARDS ──────────────────────────────────
                  SliverToBoxAdapter(child: _buildQuickAccess(context, isDark)),

                  // ── TODAY'S TIP ─────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildDailyTip(context, isDark)),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String name, String email,
      String initials, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(context),
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.split(' ').first,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.transparent,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  Widget _buildProgressBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Keep it up! 🔥',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.read<LocaleProvider>().t('overall_progress'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.62,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '62% ${context.read<LocaleProvider>().t('complete_semester')}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context, bool isDark) {
    final cardColor =
        isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200;

    final totalTopics = _courses.fold<int>(0, (sum, item) => sum + item.topics.length);

    final stats = [
      _Stat(context.read<LocaleProvider>().t('nav_courses'), _courses.length.toString(), Icons.school_rounded, const Color(0xFF6C63FF)),
      _Stat(context.read<LocaleProvider>().t('nav_quizzes'), totalTopics.toString(), Icons.quiz_rounded, const Color(0xFF4ECDC4)),
      _Stat('Streak', '7d', Icons.local_fire_department_rounded, const Color(0xFFFF6B6B)),
      _Stat('Score', '85%', Icons.trending_up_rounded, const Color(0xFFFFAA00)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: stats
            .map(
              (s) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(s.icon, color: s.color, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        s.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  Widget _buildQuickAccess(BuildContext context, bool isDark) {
    if (_courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            context.read<LocaleProvider>().t('quick_access'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: _courses.length,
            itemBuilder: (context, i) => _buildQuickCard(context, _courses[i], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCard(BuildContext context, CourseModel course, bool isDark) {
    final color = _getCourseColor(course.color);
    return GestureDetector(
      onTap: () {
        // Navigate to quizzes tab or specific course if routing is set up
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course: ${course.title} selected')),
        );
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getIconData(course.icon), color: color, size: 20),
            ),
            const Spacer(),
            Text(
              course.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              course.description,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCourseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      return const Color(0xFF6C63FF);
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  IconData _getIconData(String iconStr) {
    switch (iconStr) {
      case '📚': return Icons.menu_book_rounded;
      case '🌳': return Icons.account_tree_rounded;
      case '🎯': return Icons.track_changes_rounded;
      case '⚡': return Icons.bolt_rounded;
      case '☕': return Icons.coffee_rounded;
      case '🗄️': return Icons.storage_rounded;
      case '🌐': return Icons.public_rounded;
      default: return Icons.school_rounded;
    }
  }

  // ──────────────────────────────────────────────────────────────
  Widget _buildDailyTip(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        border: Border.all(
          color: const Color(0xFFFFAA00).withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAA00).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFFFAA00),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.read<LocaleProvider>().t('todays_tip'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.read<LocaleProvider>().t('practice_dsa_daily'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final hour = DateTime.now().hour;
    if (hour < 12) return localeProvider.t('good_morning');
    if (hour < 17) return localeProvider.t('good_afternoon');
    return localeProvider.t('good_evening');
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}
