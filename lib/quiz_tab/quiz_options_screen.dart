import 'package:flutter/material.dart';
import 'package:learnhub/quiz_tab/models.dart';
import 'package:learnhub/quiz_tab/quiz_screen.dart';
import 'package:learnhub/quiz_tab/quiz_review_screen.dart';
import 'package:learnhub/services/mongo_service.dart';

class QuizOptionsScreen extends StatelessWidget {
  final Topic topic;
  final Course course;

  const QuizOptionsScreen({
    Key? key,
    required this.topic,
    required this.course,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0E27) : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Very Compact Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: course.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(course.icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          course.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Options
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Very Compact Stats
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? const Color(0xFF1A1F3A) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
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
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  context,
                                  Icons.quiz_rounded,
                                  '${topic.totalQuestions}',
                                  'Questions',
                                  isDarkMode,
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                                _buildStatItem(
                                  context,
                                  Icons.check_circle_rounded,
                                  '${topic.completedQuestions}',
                                  'Done',
                                  isDarkMode,
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                                _buildStatItem(
                                  context,
                                  Icons.school_rounded,
                                  topic.difficulty,
                                  'Level',
                                  isDarkMode,
                                ),
                              ],
                            ),
                            if (topic.quizTaken && topic.score != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      course.gradientColors[0].withOpacity(0.2),
                                      course.gradientColors[1].withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Best: ${topic.score}%',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Choose Option',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTinyOptionCard(
                        context,
                        icon: Icons.play_circle_rounded,
                        title: topic.quizTaken ? 'Retake Quiz' : 'Start Quiz',
                        gradient: LinearGradient(colors: course.gradientColors),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                topic: topic,
                                course: course,
                                questionTypeFilter: 'quiz',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildTinyOptionCard(
                        context,
                        icon: Icons.code_rounded,
                        title: 'Coding Challenges',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                topic: topic,
                                course: course,
                                questionTypeFilter: 'coding',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      if (topic.quizTaken)
                        _buildTinyOptionCard(
                          context,
                          icon: Icons.visibility_rounded,
                          title: 'Review Quiz',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          ),
                          onTap: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    SizedBox(width: 15),
                                    Text('Loading quiz results...'),
                                  ],
                                ),
                                duration: Duration(seconds: 1),
                                backgroundColor: Color(0xFF4CAF50),
                              ),
                            );

                            try {
                              final questions = await MongoService.getQuestions(topic.id);
                              final userAnswers = MongoService.getQuizResults(topic.id);

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizReviewScreen(
                                      questions: questions,
                                      userAnswers: userAnswers,
                                      course: course,
                                      topic: topic,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error loading review: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildTinyOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}