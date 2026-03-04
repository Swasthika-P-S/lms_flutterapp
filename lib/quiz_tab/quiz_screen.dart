import 'package:flutter/material.dart';
import 'package:learnhub/models/question_model.dart';
import 'package:learnhub/services/mongo_service.dart';
import 'package:learnhub/quiz_tab/models.dart';
import 'package:learnhub/home_tab/utils/theme.dart';
import 'package:learnhub/quiz_tab/quiz_review_screen.dart';

class QuizScreen extends StatefulWidget {
  final Topic topic;
  final Course course;
  final String? questionTypeFilter; // null means all, 'quiz' or 'coding'

  const QuizScreen({
    Key? key,
    required this.topic,
    required this.course,
    this.questionTypeFilter,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _codeController = TextEditingController();
  
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int _score = 0;
  Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  bool _isFinished = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      var questions = await MongoService.getQuestions(widget.topic.id);
      
      // Apply filter if specified
      if (widget.questionTypeFilter != null) {
        questions = questions.where((q) => q.type == widget.questionTypeFilter).toList();
      }

      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
          if (_questions.isEmpty) {
            _errorMessage = widget.questionTypeFilter == 'coding' 
                ? 'No coding challenges available for this topic yet.' 
                : 'No quiz questions available for this topic yet.';
          } else {
            if (_questions.isNotEmpty && _questions[0].type == 'coding') {
              _codeController.text = _questions[0].starterCode ?? '';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection Error: Please ensure backend and database are running.';
          _isLoading = false;
        });
      }
    }
  }


  void _handleOptionSelect(int optionIndex) {
    if (_isFinished) return;
    
    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _nextPage();
    });
  }

  void _nextPage() {
    if (_questions[_currentIndex].type == 'coding') {
      if (_codeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write your solution before proceeding!'), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    int scoreCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (_selectedAnswers[i] == q.correctOptionIndex) {
        scoreCount++;
      }
    }
    
    final percentage = (_questions.isEmpty ? 0 : (scoreCount / _questions.length) * 100).toInt();
    
    MongoService.saveQuizResults(widget.topic.id, _selectedAnswers);

    // Navigate to detailed report
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizReviewScreen(
          questions: _questions,
          userAnswers: _selectedAnswers,
          course: widget.course,
          topic: widget.topic,
          score: percentage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: widget.course.gradientColors[0]),
        ),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic.name)),
        body: Center(
          child: Text(_errorMessage ?? "No questions available"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    if (_questions[index].type == 'coding') {
                      _codeController.text = _questions[index].starterCode ?? '';
                    }
                  });
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(_questions[index], isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.course.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentIndex + 1) / _questions.length,
      backgroundColor: Colors.white.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
      minHeight: 6,
    );
  }

  Widget _buildQuestionCard(QuestionModel question, bool isDark) {
    if (question.type == 'coding') {
      return _buildCodingCard(question, isDark);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            question.options.length,
            (index) => _buildOptionTile(index, question.options[index], isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCodingCard(QuestionModel question, bool isDark) {
    final accent = const Color(0xFF00D4FF);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problem badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code_rounded, size: 14, color: accent),
                const SizedBox(width: 6),
                Text('Coding Challenge', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Problem description
          Text(
            question.questionText,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, height: 1.4),
          ),
          if (question.constraints != null && question.constraints!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Constraints: ${question.constraints}', style: const TextStyle(fontSize: 12, color: Colors.orange))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Starter code block
          if (question.starterCode != null && question.starterCode!.isNotEmpty) ...[
            Text('Starter Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.grey[300] : Colors.grey[700])),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Text(
                question.starterCode!,
                style: const TextStyle(color: Color(0xFF00D4FF), fontFamily: 'monospace', fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // User code input
          Text('Your Solution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.grey[300] : Colors.grey[700])),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Write your code here...',
                hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Test cases
          if (question.testCases.isNotEmpty) ...[
            Text('Test Cases', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.grey[300] : Colors.grey[700])),
            const SizedBox(height: 8),
            ...question.testCases.map((tc) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Input: ${tc.input}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Text('Output: ${tc.output}', style: TextStyle(fontSize: 12, color: Colors.green[400], fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
          ],
          // Expected output hint
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(question.explanation!, style: TextStyle(fontSize: 12, color: isDark ? Colors.blue[200] : Colors.blue[800]))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Next / Finish button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextPage,
              icon: Icon(_currentIndex < _questions.length - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded),
              label: Text(_currentIndex < _questions.length - 1 ? 'Next Challenge' : 'Finish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionTile(int index, String text, bool isDark) {
    final isSelected = _selectedAnswers[_currentIndex] == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleOptionSelect(index),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? widget.course.gradientColors[0].withOpacity(0.1) : (isDark ? AppTheme.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? widget.course.gradientColors[0] : (isDark ? Colors.white10 : Colors.grey.shade300), width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? widget.course.gradientColors[0] : (isDark ? Colors.white24 : Colors.grey.shade100)),
                child: Center(
                  child: Text(String.fromCharCode(65 + index), style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87))),
            ],
          ),
        ),
      ),
    );
  }

}

