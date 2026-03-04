import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/assignment.dart';
import '../data/submission.dart';
import '../logic/assignment_service.dart';
import 'submit_assignment_screen.dart';
import 'submissions_list_screen.dart';
import '../core/app_colors.dart';
import '../../providers/firebase_auth_provider.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final Assignment assignment;
  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<FirebaseAuthProvider>();
    final isAdmin = auth.isAdmin;
    final currentUserId = auth.user?.email ?? '';
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                assignment.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.assignment_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Deadlines
                  _buildHeaderInfo(context, isDarkMode),
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getCard(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Text(
                      assignment.description,
                      style: TextStyle(
                        color: AppColors.getTextSecondary(context),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Section
                  if (!isAdmin) 
                    _buildStudentSection(context, currentUserId)
                  else
                    _buildAdminSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(
            context,
            Icons.calendar_month_rounded,
            'Deadline',
            DateFormat('MMM dd').format(assignment.deadline),
            AppColors.primary,
          ),
          _infoItem(
            context,
            Icons.score_rounded,
            'Points',
            '${assignment.maxScore}',
            AppColors.success,
          ),
          _infoItem(
            context,
            Icons.timer_rounded,
            'Status',
            assignment.isOverdue ? 'Overdue' : 'Active',
            assignment.isOverdue ? AppColors.accent : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSection(BuildContext context, String userId) {
    return StreamBuilder<List<Submission>>(
      stream: AssignmentService().getSubmissionsByAssignment(assignment.id),
      builder: (context, snapshot) {
        final submissions = snapshot.data ?? [];
        final mySubmission = submissions.firstWhere(
          (s) => s.studentId == userId,
          orElse: () => Submission(
            id: '',
            assignmentId: '',
            studentId: '',
            studentName: '',
            content: '',
            submittedAt: DateTime.now(),
            status: 'none',
          ),
        );

        final hasSubmitted = mySubmission.id.isNotEmpty;

        return Column(
          children: [
            if (hasSubmitted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Submitted Successfully',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted on ${DateFormat('MMM dd, HH:mm').format(mySubmission.submittedAt)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (mySubmission.status == 'graded') ...[
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grade:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${mySubmission.score} / ${assignment.maxScore}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (mySubmission.feedback != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Feedback: ${mySubmission.feedback}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSubmitted ? Colors.grey : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(hasSubmitted ? Icons.replay_rounded : Icons.upload_rounded),
                label: Text(
                  hasSubmitted ? 'Re-submit Assignment' : 'Submit Assignment',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmitAssignmentScreen(assignment: assignment),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.people_rounded),
        label: const Text(
          'View Submissions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubmissionsListScreen(assignmentId: assignment.id),
          ),
        ),
      ),
    );
  }
}