import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../services/course_service.dart';
import '../services/download_service.dart';
import '../widgets/lesson_item.dart';
import '../../widgets/video_player_widget.dart';
import '../utils/colors.dart';
import 'content_viewer_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseService _courseService = CourseService();
  final DownloadService _downloadService = DownloadService();
  List<Lesson> lessons = [];
  bool isLoading = true;
  late Course currentCourse;
  Lesson? activeLesson;
  // removed _youtubeController

  @override
  void initState() {
    super.initState();
    currentCourse = widget.course;
    _loadLessons();
  }

  void _initializePlayer() {
    // No initialization needed for URL launcher
  }

  int _getStartAtInitial() {
    if (activeLesson == null) return 0;
    try {
      final uri = Uri.tryParse(activeLesson!.videoUrl);
      if (uri != null && uri.queryParameters.containsKey('start')) {
        return int.tryParse(uri.queryParameters['start']!) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  int? _getEndAtInitial() {
    if (activeLesson == null) return null;
    try {
      final uri = Uri.tryParse(activeLesson!.videoUrl);
      if (uri != null && uri.queryParameters.containsKey('end')) {
        return int.tryParse(uri.queryParameters['end']!);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadLessons() async {
    setState(() {
      isLoading = true;
    });

    // For demo purposes, using sample data
    lessons = _courseService.getSampleLessons(widget.course.id);
    
    // Set the first lesson as active by default if none is selected
    if (lessons.isNotEmpty && activeLesson == null) {
      activeLesson = lessons.first;
      _initializePlayer();
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _enrollInCourse() async {
    await _courseService.enrollInCourse('user123', widget.course.id);
    setState(() {
      currentCourse = currentCourse.copyWith(isEnrolled: true);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully enrolled in course!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleDownload(Lesson lesson) async {
    if (lesson.isDownloaded) {
      await _downloadService.removeDownload(lesson);
    } else {
      await _downloadService.downloadLesson(lesson);
    }
    _loadLessons();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getCard(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: AppColors.getTextPrimary(context),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.bookmark_border,
              color: AppColors.getTextPrimary(context),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800; // threshold for tablet/desktop
                  
                  if (isWide) {
                    // Wide Layout: Main content on left, list on right
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (activeLesson != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: VideoPlayerWidget(
                                        videoUrl: activeLesson?.videoUrl,
                                        autoPlay: false,
                                      ),
                                    ),
                                  ),
                                _buildCourseHeader(context, isDarkMode),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, color: isDarkMode ? Colors.white12 : Colors.black12),
                        Expanded(
                          flex: 1,
                          child: _buildLessonList(context),
                        ),
                      ],
                    );
                  } else {
                    // Narrow Layout: Stacked vertically
                    return Column(
                      children: [
                        if (activeLesson != null) ...[
                           VideoPlayerWidget(
                             videoUrl: activeLesson?.videoUrl,
                             autoPlay: false,
                           ),
                        ],
                        _buildCourseHeader(context, isDarkMode),
                        Expanded(
                          child: _buildLessonList(context),
                        ),
                      ],
                    );
                  }
                },
              ),
      ),
      bottomNavigationBar: _buildEnrollButton(context, isDarkMode),
    );
  }

  int _getStartAt() {
    if (activeLesson == null) return 0;
    try {
      final uri = Uri.tryParse(activeLesson!.videoUrl);
      if (uri != null && uri.queryParameters.containsKey('start')) {
        return int.tryParse(uri.queryParameters['start']!) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  int? _getEndAt() {
    if (activeLesson == null) return null;
    try {
      final uri = Uri.tryParse(activeLesson!.videoUrl);
      if (uri != null && uri.queryParameters.containsKey('end')) {
        return int.tryParse(uri.queryParameters['end']!);
      }
    } catch (_) {}
    return null;
  }

  Widget _buildCourseHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.getCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    currentCourse.thumbnail,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentCourse.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By ${currentCourse.instructor}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                context,
                Icons.play_circle_outline,
                '${currentCourse.totalLessons} Lessons',
              ),
              _buildInfoChip(
                context,
                Icons.access_time,
                currentCourse.duration,
              ),
              _buildInfoChip(
                context,
                Icons.signal_cellular_alt,
                'Intermediate',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppColors.background 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonList(BuildContext context) {
    return Container(
      color: AppColors.getBackground(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          final isActive = activeLesson?.id == lesson.id;
          
          return LessonItem(
            lesson: lesson,
            index: index,
            isActive: isActive,
            onTap: () {
              if (activeLesson?.id == lesson.id) return;

              setState(() {
                activeLesson = lesson;
              });

              // Player updates automatically via activeLesson state rebuilding the widget
            },
            onDownload: () => _handleDownload(lesson),
          );
        },
      ),
    );
  }

  Widget _buildEnrollButton(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: currentCourse.isEnrolled
              ? () {
                  if (lessons.isEmpty) return;
                  final firstIncompleteLesson = lessons.firstWhere(
                    (l) => !l.isCompleted,
                    orElse: () => lessons.first,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContentViewerScreen(
                        lesson: firstIncompleteLesson,
                        course: currentCourse,
                      ),
                    ),
                  );
                }
              : _enrollInCourse,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            currentCourse.isEnrolled ? 'Continue Learning' : 'Enroll Now',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}