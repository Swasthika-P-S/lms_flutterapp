import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../logic/assignment_service.dart';
import '../logic/notification_service.dart';
import '../data/assignment.dart';
import 'assignment_list_screen.dart';
import 'qr_generator_screen.dart';
import 'qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String courseId;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.courseId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final NotificationService _notificationService = NotificationService();

  String? _lastNotificationTitle;
  String? _lastNotificationBody;

  @override
  void initState() {
    super.initState();
    _notificationService.register(_onNotification);
  }

  void _onNotification(String title, String body) {
    if (!mounted) return;
    setState(() {
      _lastNotificationTitle = title;
      _lastNotificationBody = body;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title • $body')));
  }

  @override
  void dispose() {
    _notificationService.unregister(_onNotification);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getCard(context),
        foregroundColor: AppColors.getTextPrimary(context),
        title: Text('${AppConstants.appName} - ${widget.userName}'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacing),
        children: [
          _quickActions(context, isDarkMode),
          const SizedBox(height: AppConstants.spacing),
          if (_lastNotificationTitle != null) _notificationCard(context, isDarkMode),
          const SizedBox(height: AppConstants.spacing),
          _deadlines(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _actionTile(
              context,
              isDarkMode,
              Icons.assignment_rounded,
              AppColors.primary,
              'Assignments',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignmentListScreen(courseId: widget.courseId),
                  ),
                );
              },
            ),
            _actionTile(
              context,
              isDarkMode,
              Icons.history_edu_rounded,
              AppColors.success,
              'Submissions',
              () {
                // For direct access to submissions list
                // We'll show a course-wide submissions view or just list assignments again
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignmentListScreen(courseId: widget.courseId),
                  ),
                );
              },
            ),
            _actionTile(
              context,
              isDarkMode,
              Icons.qr_code_rounded,
              Colors.orange,
              'Generate QR',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRGeneratorScreen(courseId: widget.courseId),
                  ),
                );
              },
            ),
            _actionTile(
              context,
              isDarkMode,
              Icons.qr_code_scanner_rounded,
              AppColors.accent,
              'Join via QR',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRScannerScreen(
                      expectedCourseId: widget.courseId,
                      userId: 'currentUser',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionTile(
    BuildContext context,
    bool isDarkMode,
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppColors.success.withOpacity(isDarkMode ? 0.25 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastNotificationTitle ?? '',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastNotificationBody ?? '',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deadlines(BuildContext context, bool isDarkMode) {
    return StreamBuilder<List<Assignment>>(
      stream: _assignmentService.getUpcomingDeadlines(widget.courseId),
      builder: (context, snap) {
        final items = snap.data ?? [];
        
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.cardPadding * 1.5),
            decoration: BoxDecoration(
              color: AppColors.getCard(context),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.getTextSecondary(context),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'No upcoming deadlines',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                'Upcoming Deadlines',
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...items.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.getCard(context),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (a.isOverdue
                              ? AppColors.accent
                              : AppColors.primary)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: a.isOverdue ? AppColors.accent : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.formattedDeadline,
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${a.maxScore} pts',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        );
      },
    );
  }
}