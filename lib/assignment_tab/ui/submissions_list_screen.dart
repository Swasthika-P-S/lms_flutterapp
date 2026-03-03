import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/submission.dart';
import '../logic/assignment_service.dart';
import '../core/app_colors.dart';
import '../../services/mongo_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmissionsListScreen extends StatelessWidget {
  final String assignmentId;
  final AssignmentService _service = AssignmentService();

  SubmissionsListScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text('Submissions'),
        backgroundColor: AppColors.getCard(context),
        foregroundColor: AppColors.getTextPrimary(context),
        elevation: 0,
      ),
      body: StreamBuilder<List<Submission>>(
        stream: _service.getSubmissionsByAssignment(assignmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }
          
          final submissions = snapshot.data ?? [];
          
          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 80,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No submissions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submissions will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: submissions.length,
            padding: const EdgeInsets.all(AppConstants.spacing),
            itemBuilder: (context, i) => _buildCard(
              context,
              submissions[i],
              isDarkMode,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, Submission sub, bool isDarkMode) {
    Color chipColor;
    IconData statusIcon;
    
    switch (sub.status) {
      case 'late':
        chipColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      case 'graded':
        chipColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      default:
        chipColor = AppColors.primary;
        statusIcon = Icons.pending;
    }
    
    return GestureDetector(
      onTap: () => _showGradeDialog(context, sub, isDarkMode),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacing),
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
            // Student Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  sub.studentName[0].toUpperCase(),
                  style: TextStyle(
                    color: chipColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.studentName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: AppColors.getTextSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Submitted ${DateFormat('MMM dd, HH:mm').format(sub.submittedAt)}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 13,
                          color: AppColors.getTextSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sub.feedback!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (sub.fileName != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openFile(sub.fileUrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                sub.fileName!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Status/Score Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: chipColor),
                  const SizedBox(width: 4),
                  Text(
                    sub.score != null ? '${sub.score} pts' : sub.status,
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            
            // Chevron
            Icon(
              Icons.chevron_right,
              color: AppColors.getTextSecondary(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGradeDialog(
    BuildContext context,
    Submission sub,
    bool isDarkMode,
  ) async {
    final scoreCtrl = TextEditingController(
      text: sub.score?.toString() ?? '100',
    );
    final feedbackCtrl = TextEditingController(text: sub.feedback ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.getCard(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Text(
          'Grade Submission',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          sub.studentName[0].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.studentName,
                            style: TextStyle(
                              color: AppColors.getTextPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(sub.submittedAt),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Score Field
              TextField(
                controller: scoreCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(context)),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Score',
                  labelStyle: TextStyle(
                    color: AppColors.getTextSecondary(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 16),
              
              // Feedback Field
              TextField(
                controller: feedbackCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(context)),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Feedback',
                  labelStyle: TextStyle(
                    color: AppColors.getTextSecondary(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextSecondary(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final score = int.tryParse(scoreCtrl.text) ?? 100;
      await AssignmentService().gradeSubmission(
        sub.id,
        score,
        feedbackCtrl.text,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Graded ${sub.studentName}\'s submission'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    scoreCtrl.dispose();
    feedbackCtrl.dispose();
  }

  void _openFile(String? fileUrl) async {
    if (fileUrl == null) return;
    final url = Uri.parse('${MongoService.serverUrl}$fileUrl');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
    }
  }
}