import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../auth/login_screen.dart';
import 'package:learnhub/providers/locale_provider.dart';
import '../../../../providers/firebase_auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  final bool showBackButton;
  const SettingsScreen({super.key, this.showBackButton = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Sign out from Firebase — this triggers the auth stream
      // and automatically navigates to LoginScreen via main.dart
      await context.read<FirebaseAuthProvider>().signOut();

      // Also clear local providers
      if (mounted) {
        context.read<AuthProvider>().logout();
        context.read<UserProvider>().clearUser();
      }
    }
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF6C63FF)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF6C63FF), size: 20),
      ),
      title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          )),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500]))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final loc = context.watch<LocaleProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final auth = context.watch<FirebaseAuthProvider>();
    final email = auth.user?.email ?? '';
    final name = auth.userModel?.displayName ?? auth.user?.displayName ?? 'User';

    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF13132A) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton 
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User card ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),

            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),


          // ── App Preferences ────────────────────────────────────────
          _sectionLabel(loc.t('app_preferences'), isDark),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                // 🌍 Language Toggle (Added from multilanguagesupport)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language_rounded, color: Colors.blue, size: 20),
                  ),
                  title: Text(loc.t('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    loc.isHindi ? loc.t('language_hindi') : loc.t('language_english'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  trailing: DropdownButton<String>(
                    value: loc.locale,
                    underline: const SizedBox(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('\u0939\u093f\u0902\u0926\u0940')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        loc.switchLocale(value);
                      }
                    },
                  ),
                ),
                const Divider(height: 1, indent: 60),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: const Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                  title: Text(loc.t('dark_mode'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isDark ? loc.t('switch_to_light') : loc.t('switch_to_dark'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  value: isDark,
                  activeColor: const Color(0xFF6C63FF),
                  onChanged: (v) =>
                      themeProvider.themeMode = v ? ThemeMode.dark : ThemeMode.light,
                ),
                const Divider(height: 1, indent: 60),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Color(0xFF4ECDC4), size: 20),
                  ),
                  title: Text(loc.t('notifications'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(notificationsEnabled ? loc.t('enabled') : loc.t('disabled'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  value: notificationsEnabled,
                  activeColor: const Color(0xFF4ECDC4),
                  onChanged: (v) => setState(() => notificationsEnabled = v),
                ),
              ],
            ),
          ),


          const SizedBox(height: 20),

          // ── Account ────────────────────────────────────────────────
          _sectionLabel(loc.t('account'), isDark),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.person_rounded,
                  title: loc.t('edit_profile'),
                  subtitle: loc.t('update_personal_info'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.t('feature_coming_soon')))),
                ),
                const Divider(height: 1, indent: 60),
                _tile(
                  icon: Icons.lock_rounded,
                  title: loc.t('change_password'),
                  subtitle: loc.t('update_password'),
                  iconColor: const Color(0xFFFFAA00),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.t('feature_coming_soon')))),
                ),
              ],
            ),
          ),


          const SizedBox(height: 20),

          // ── Learning ───────────────────────────────────────────────
          _sectionLabel(loc.t('learning'), isDark),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.school_rounded,
                  title: loc.t('study_goals'),
                  subtitle: loc.t('set_daily_targets'),
                  iconColor: const Color(0xFF4ECDC4),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.t('feature_coming_soon')))),
                ),
                const Divider(height: 1, indent: 60),
                _tile(
                  icon: Icons.trending_up_rounded,
                  title: loc.t('progress_tracking'),
                  subtitle: loc.t('view_analytics'),
                  iconColor: const Color(0xFFFF6B6B),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.t('feature_coming_soon')))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),


          // ── About ──────────────────────────────────────────────────
          _sectionLabel(loc.t('about'), isDark),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.info_rounded,
                  title: loc.t('learnhub_lms'),
                  subtitle: 'Version 1.0.0 • Build 2026.01',
                  trailing: const SizedBox.shrink(),
                  iconColor: Colors.blueGrey,
                ),
                const Divider(height: 1, indent: 60),
                _tile(
                  icon: Icons.privacy_tip_rounded,
                  title: loc.t('privacy_policy'),
                  iconColor: Colors.blueGrey,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60),
                _tile(
                  icon: Icons.description_rounded,
                  title: loc.t('terms_of_service'),
                  iconColor: Colors.blueGrey,
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SIGN OUT BUTTON ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                loc.t('logout'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }


  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[500] : Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
