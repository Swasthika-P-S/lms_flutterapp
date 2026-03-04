import 'package:flutter/material.dart';
import 'package:learnhub/models/question_model.dart';
import 'package:learnhub/quiz_tab/models.dart';
import 'package:learnhub/home_tab/utils/theme.dart';

class QuizReviewScreen extends StatelessWidget {
  final List<QuestionModel> questions;
  final Map<int, int> userAnswers;
  final Course course;
  final Topic topic;
  final int score; // percentage score

  const QuizReviewScreen({
    Key? key,
    required this.questions,
    required this.userAnswers,
    required this.course,
    required this.topic,
    this.score = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final correctCount = questions.where((q) {
      final idx = questions.indexOf(q);
      return userAnswers[idx] == q.correctOptionIndex;
    }).length;
    final isPassing = score >= 70;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quiz Report'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: course.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Score Summary Card ──────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: course.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: course.gradientColors[0].withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isPassing ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                  color: Colors.white,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  isPassing ? 'Great Job! 🎉' : 'Keep Practicing!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$score%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$correctCount / ${questions.length} correct',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPassing ? '✅ Passed' : '❌ Not Passed (need 70%)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // ── Divider ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Detailed Breakdown',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          // ── Question Cards ───────────────────────────────────────
          ...List.generate(questions.length, (index) {
            final question = questions[index];
            final userAnswer = userAnswers[index];
            final isCorrect = userAnswer == question.correctOptionIndex;
            return _buildQuestionReviewCard(question, userAnswer, isCorrect, index, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(
    QuestionModel question,
    int? userAnswer,
    bool isCorrect,
    int index,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isCorrect ? Colors.green : Colors.red,
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (question.codeSnippet != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.codeSnippet!,
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...List.generate(
            question.options.length,
            (optIdx) => _buildOptionView(
              optIdx,
              question.options[optIdx],
              optIdx == question.correctOptionIndex,
              optIdx == userAnswer,
              isDark,
            ),
          ),
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.blue[200] : Colors.blue[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionView(
    int index,
    String text,
    bool isCorrect,
    bool isSelected,
    bool isDark,
  ) {
    Color? bgColor;
    Color? borderColor;
    IconData? icon;

    if (isCorrect) {
      bgColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isSelected && !isCorrect) {
      bgColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '${String.fromCharCode(65 + index)}.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          if (icon != null)
            Icon(icon, size: 18, color: borderColor),
        ],
      ),
    );
  }
}
