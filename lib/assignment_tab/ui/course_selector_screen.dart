import 'package:flutter/material.dart';
import './assignment_list_screen.dart';
import '../logic/assignment_service.dart';
import '../../services/mongo_service.dart';
import '../../models/course_model.dart';
import '../core/app_colors.dart';

class AssignmentCourseSelector extends StatefulWidget {
  final bool isAdmin;
  const AssignmentCourseSelector({super.key, this.isAdmin = false});

  @override
  State<AssignmentCourseSelector> createState() => _AssignmentCourseSelectorState();
}

class _AssignmentCourseSelectorState extends State<AssignmentCourseSelector> {
  bool _isLoading = true;
  List<CourseModel> _courses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
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

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: widget.isAdmin ? null : AppBar(
        title: const Text('Select Course'),
        backgroundColor: AppColors.getCard(context),
        foregroundColor: AppColors.getTextPrimary(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _courses.isEmpty
                  ? const Center(child: Text('No courses found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        return _buildCourseCard(context, course, isDark);
                      },
                    ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course, bool isDark) {
    final color = _getCourseColor(course.color);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentListScreen(courseId: course.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIconData(course.icon), color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              course.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
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
}
