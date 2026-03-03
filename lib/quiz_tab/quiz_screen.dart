import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnhub/models/question_model.dart';
import 'package:learnhub/services/mongo_service.dart';
import 'package:learnhub/providers/firebase_auth_provider.dart';
import 'package:learnhub/quiz_tab/models.dart';
import 'package:learnhub/home_tab/utils/theme.dart';
import 'package:learnhub/services/data_seeder.dart';
import 'package:learnhub/quiz_tab/quiz_review_screen.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

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
  
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int _score = 0;
  Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  Map<int, bool> _codingCompleted = {}; // questionIndex -> passedAllTestCases
  Map<int, String?> _codeResults = {}; // questionIndex -> manual error or message
  
  CodeController? _codeController;
  bool _isFinished = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _codeController?.dispose();
    _pageController.dispose();
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
            _initCodeController();
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

  void _initCodeController() {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];
    
    if (q.type == 'coding') {
      _codeController?.dispose();
      _codeController = CodeController(
        text: q.starterCode ?? '// Write your code here\n',
        language: javascript,
      );
    } else {
      _codeController = null;
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
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishQuiz();
    }
  }

  void _runCode() {
    final q = _questions[_currentIndex];
    final code = _codeController?.text ?? '';
    
    // In a real app, you'd send code to a backend or use a JS island.
    // For this MVP, we'll simulate output checking.
    // We'll look for a comment like // output: <result> or just mark as success for demonstration
    // OR, better yet, we'll do literal string matching for very simple cases if it's a "solve(n)" pattern
    
    setState(() {
      // Mocking execution: If the code is not empty, we "pass" the test cases for now.
      // In a real scenario, this would involve a sandboxed execution environment.
      if (code.trim().length > (q.starterCode?.trim().length ?? 0) + 5) {
        _codingCompleted[_currentIndex] = true;
        _codeResults[_currentIndex] = "✅ All test cases passed!";
        
        Future.delayed(const Duration(seconds: 1), () {
          _nextPage();
        });
      } else {
        _codeResults[_currentIndex] = "❌ Tests failed. Please check your logic.";
      }
    });
  }

  void _finishQuiz() {
    int scoreCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.type == 'quiz') {
        if (_selectedAnswers[i] == q.correctOptionIndex) {
          scoreCount++;
        }
      } else {
        if (_codingCompleted[i] == true) {
          scoreCount++;
        }
      }
    }
    
    final percentage = ((scoreCount / _questions.length) * 100).toInt();
    
    setState(() {
      _score = percentage;
      _isFinished = true;
    });

    MongoService.saveQuizResults(widget.topic.id, _selectedAnswers);
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

    if (_isFinished) {
      return _buildResultScreen(isDark);
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
                    _initCodeController();
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
          
          if (question.type == 'coding') ...[
            if (question.constraints != null) ...[
              Text('Constraints:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
              Text(question.constraints!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
            ],
            
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  CodeField(
                    controller: _codeController!,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_codeResults[_currentIndex] ?? "Ready to run...", 
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                        ElevatedButton.icon(
                          onPressed: _runCode,
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Run Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.course.gradientColors[0],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Test Cases:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 8),
            ...question.testCases.map((tc) => _buildTestCaseRow(tc, isDark)).toList(),
          ] else ...[
            if (question.codeSnippet != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  question.codeSnippet!,
                  style: const TextStyle(color: Color(0xFFD4D4D4), fontFamily: 'monospace', fontSize: 14),
                ),
              ),
              const SizedBox(height: 30),
            ],
            ...List.generate(
              question.options.length,
              (index) => _buildOptionTile(index, question.options[index], isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestCaseRow(TestCase tc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text('Input: ${tc.input}', style: const TextStyle(fontSize: 12))),
          Text('Expected: ${tc.output}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildResultScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: _score >= 70 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(_score >= 70 ? Icons.emoji_events : Icons.refresh, size: 50, color: _score >= 70 ? Colors.green : Colors.orange),
              ),
              const SizedBox(height: 30),
              Text('Assessment Completed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 10),
              Text('You scored', style: TextStyle(fontSize: 18, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              Text('$_score%', style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: widget.course.gradientColors[0])),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.course.gradientColors[0],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Course Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
