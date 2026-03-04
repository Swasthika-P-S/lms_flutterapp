import 'package:flutter/material.dart';
import '../data/assignment.dart';
import '../logic/assignment_service.dart';
import 'create_assignment_screen.dart';
import 'assignment_detail_screen.dart';
import '../core/app_colors.dart';

import 'package:provider/provider.dart';
import '../../providers/firebase_auth_provider.dart';

class AssignmentListScreen extends StatefulWidget {
  final String courseId;

  const AssignmentListScreen({super.key, required this.courseId});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  final AssignmentService _service = AssignmentService();
  late Stream<List<Assignment>> _assignmentsStream;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _assignmentsStream = _service.getAssignmentsByCourse(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: AppColors.getCard(context),
        foregroundColor: AppColors.getTextPrimary(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: _assignmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading assignments',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().contains('TimeoutException') 
                          ? 'Connection timed out. Please check your internet or if the server is running.'
                          : snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.getTextSecondary(context)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final assignments = snapshot.data ?? [];
          
          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No assignments yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first assignment',
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
            itemCount: assignments.length,
            padding: const EdgeInsets.all(AppConstants.spacing),
            itemBuilder: (context, i) => _buildAssignmentCard(
              context,
              assignments[i],
              isDarkMode,
            ),
          );
        },
      ),
      floatingActionButton: context.watch<FirebaseAuthProvider>().isAdmin ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateAssignmentScreen(courseId: widget.courseId),
            ),
          );
          _refresh();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    Assignment assignment,
    bool isDarkMode,
  ) {
    final isOverdue = assignment.isOverdue;
    final primaryColor = isOverdue ? AppColors.accent : AppColors.primary;
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentDetailScreen(assignment: assignment),
          ),
        );
        _refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left Accent Bar
                Container(
                  width: 6,
                  color: primaryColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isOverdue ? Icons.priority_high_rounded : Icons.assignment_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                assignment.title,
                                style: TextStyle(
                                  color: AppColors.getTextPrimary(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${assignment.maxScore} pts',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          assignment.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 15,
                              color: AppColors.getTextSecondary(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              assignment.formattedDeadline,
                              style: TextStyle(
                                color: AppColors.getTextSecondary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: (isOverdue ? AppColors.accent : AppColors.success).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOverdue ? 'Overdue' : 'Active',
                                style: TextStyle(
                                  color: isOverdue ? AppColors.accent : AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
