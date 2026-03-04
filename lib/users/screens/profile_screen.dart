import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/firebase_auth_provider.dart';
import '../../home_tab/screens/providers/theme_provider.dart';
import '../../home_tab/screens/settings/settings_screen.dart';

/// Professional student profile screen with real Firebase Auth data.
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<FirebaseAuthProvider>();
    final user = auth.userModel;
    final fbUser = auth.user;

    final name = user?.displayName ?? fbUser?.displayName ?? 'Student';
    final email = user?.email ?? fbUser?.email ?? '';
    final uid = fbUser?.uid ?? '';
    final initials = name.split(' ').length > 1
        ? '${name.split(' ')[0][0]}${name.split(' ').last[0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : 'S');

    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── CURVED HEADER ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeroHeader(context, name, email, initials, uid, isDark),
          ),

          // ── STATS ROW ───────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStats(context, isDark)),

          // ── SKILLS ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSkills(context, isDark)),

          // ── ACCOUNT ACTIONS ─────────────────────────────────────────
          SliverToBoxAdapter(child: _buildActions(context, isDark, auth)),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String name, String email,
      String initials, String uid, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: const Text(
                'STUDENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // UID copy row
            if (uid.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UID copied to clipboard')),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fingerprint, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          uid,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Curved bottom
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F4FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _statCard('5', 'Courses', Icons.book_rounded, const Color(0xFF6C63FF), cardBg, isDark),
          const SizedBox(width: 12),
          _statCard('12h', 'Hours', Icons.access_time_rounded, const Color(0xFF4ECDC4), cardBg, isDark),
          const SizedBox(width: 12),
          _statCard('85%', 'Score', Icons.trending_up_rounded, const Color(0xFFFFAA00), cardBg, isDark),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color,
      Color bg, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSkills(BuildContext context, bool isDark) {
    final skills = ['Flutter', 'Dart', 'DSA', 'OOPs', 'Java', 'C++', 'DBMS', 'Firebase'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (s) => Chip(
                    label: Text(s,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    backgroundColor:
                        const Color(0xFF6C63FF).withOpacity(isDark ? 0.2 : 0.08),
                    side: BorderSide(
                        color: const Color(0xFF6C63FF).withOpacity(0.4)),
                    labelStyle: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF6C63FF)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, bool isDark, FirebaseAuthProvider auth) {
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _actionTile(Icons.settings_rounded, 'Settings', 'Themes, Notifications', isDark, cardBg,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(showBackButton: true)))),
          const SizedBox(height: 8),
          _actionTile(Icons.logout_rounded, 'Sign Out', 'Log out of your account', isDark, cardBg,
              color: Colors.redAccent,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await auth.signOut();
                }
              }),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, bool isDark,
      Color bg, {VoidCallback? onTap, Color? color}) {
    color ??= const Color(0xFF6C63FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
