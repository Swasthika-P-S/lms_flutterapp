import 'dart:convert';
import 'package:http/http.dart' as http;

/// Groq AI chatbot service for LMS study assistance
/// Uses direct HTTP calls to Groq API (OpenAI-compatible)
class ChatbotService {
  String? _apiKey;
  bool _initialized = false;
  String _currentCourse = 'General';
  
  // Chat history for context (OpenAI format)
  final List<Map<String, String>> _chatHistory = [];
  
  /// Initialize the chatbot with API key
  Future<void> initialize(String apiKey) async {
    if (_initialized) return;
    
    _apiKey = apiKey;
    _chatHistory.clear();
    
    // Add system instruction
    _chatHistory.add({
      'role': 'system',
      'content': _getSystemPrompt(_currentCourse),
    });
    _chatHistory.add({
      'role': 'assistant',
      'content': 'Understood! I\'m LearnBot, your AI study assistant. I\'m ready to help you learn. Ask me anything about your courses!',
    });
    
    _initialized = true;
    print('✅ Chatbot initialized successfully');
  }
  
  /// Get system prompt tailored for the selected course
  String _getSystemPrompt(String course) {
    final courseContext = _getCourseContext(course);
    
    final isCourseLocked = (course != 'General');
    final restrictionRule = isCourseLocked ? '''

STRICT RULE — TOPIC RESTRICTION:
You are ONLY allowed to answer questions related to $course.
If a student asks about something NOT related to $course, you MUST:
1. Politely decline the question
2. Say: "This question is outside the $course section. Please switch to the correct course tab (General, DSA, C, or OOPs) to ask this question."
3. Do NOT answer the off-topic question at all, even partially
4. If unsure whether it's related to $course, err on the side of caution and decline

Examples of what to DECLINE in $course mode:
- General knowledge questions unrelated to $course
- Questions about other programming courses not covered by $course
- Personal or non-academic questions
''' : '''

IMPORTANT TOPIC RESTRICTION:
You are ONLY allowed to help with these three subjects:
1. Data Structures & Algorithms (DSA)
2. Object-Oriented Programming (OOPs)
3. C Programming

If a student asks about ANY topic outside of DSA, OOPs, or C Programming, you MUST:
1. Politely decline the question
2. Say: "I can only help with DSA, OOPs, and C Programming. Please ask a question related to one of these subjects."
3. Do NOT answer the off-topic question at all, even partially
4. This includes: web development, databases, Python, Java, networking, OS, or any other subject

You are in General mode but STILL restricted to DSA, OOPs, and C topics only.
''';

    return '''
You are LearnBot, an AI study assistant for a Learning Management System (LMS). 
You help students learn and master their courses effectively.

$courseContext
$restrictionRule

Your role as a study assistant:
1. Explain concepts clearly with examples and analogies
2. Provide well-commented code examples when relevant
3. Help students debug their code and understand errors
4. Suggest problem-solving approaches and study strategies
5. Quiz students to test their understanding when asked
6. Provide step-by-step solutions to problems
7. Recommend learning paths and resources
8. Be encouraging, patient, and supportive

Guidelines:
- Keep explanations clear, structured, and beginner-friendly
- Use code blocks with proper syntax highlighting for code examples
- Use bullet points and numbered lists for organized content
- Break complex topics into smaller, digestible parts
- If a student is struggling, try explaining from a different angle
- Always encourage practice and hands-on coding
- Use markdown formatting for better readability
- When giving code, always add inline comments explaining each step
''';
  }

  /// Get course-specific context for system prompt
  String _getCourseContext(String course) {
    switch (course) {
      case 'DSA':
        return '''
Current Course Focus: Data Structures & Algorithms (DSA)
Key Topics: Arrays, Linked Lists, Stacks, Queues, Trees, Graphs, 
Hash Tables, Sorting Algorithms, Searching Algorithms, Dynamic Programming, 
Greedy Algorithms, Recursion, Backtracking, Time & Space Complexity Analysis.

When helping with DSA:
- Always discuss time and space complexity (Big O notation)
- Show multiple approaches (brute force then optimized)
- Use visual representations when explaining data structures
- Relate problems to real-world scenarios
- Provide pseudocode before actual code when helpful
''';
      case 'C':
        return '''
Current Course Focus: C Programming
Key Topics: Variables & Data Types, Operators, Control Flow (if/else, switch, loops),
Functions, Pointers, Arrays, Strings, Structures, Unions, File I/O,
Memory Management (malloc, calloc, free), Preprocessor Directives, 
Bitwise Operations, Command Line Arguments.

When helping with C Programming:
- Emphasize memory management and pointer concepts
- Show how things work at the memory level
- Highlight common pitfalls (buffer overflow, dangling pointers, memory leaks)
- Use proper C syntax and conventions
- Explain compilation process when relevant
''';
      case 'OOPs':
        return '''
Current Course Focus: Object-Oriented Programming (OOPs)
Key Topics: Classes & Objects, Encapsulation, Inheritance, Polymorphism,
Abstraction, Constructors & Destructors, Access Modifiers, 
Interfaces, Abstract Classes, Method Overloading & Overriding,
Design Patterns, SOLID Principles, Composition vs Inheritance,
Virtual Functions, Friend Functions.

When helping with OOPs:
- Use real-world analogies to explain OOP concepts
- Show examples in C++ or Java as appropriate
- Compare procedural vs object-oriented approaches
- Discuss design principles and best practices
- Explain with UML diagrams descriptions when helpful
''';
      default:
        return '''
General Study Assistant Mode.
You can help with questions about DSA, C Programming, and OOPs ONLY.
Do NOT answer questions about any other subject.
''';
    }
  }
  
  /// Switch to a different course context
  void switchCourse(String course) {
    _currentCourse = course;
    if (_initialized) {
      _chatHistory.clear();
      _chatHistory.add({
        'role': 'system',
        'content': _getSystemPrompt(course),
      });
      _chatHistory.add({
        'role': 'assistant',
        'content': 'Understood! I\'m now focused on $course. Ask me anything!',
      });
      print('🔄 Switched to $course context');
    }
  }
  
  /// Send a message to the chatbot via direct HTTP API call
  Future<String> sendMessage(String message, {String? context}) async {
    if (!_initialized || _apiKey == null) {
      throw Exception('Chatbot not initialized. Call initialize() first.');
    }
    
    try {
      String fullMessage = message;
      if (context != null && context.isNotEmpty) {
        fullMessage = 'Context: $context\n\nQuestion: $message';
      }
      
      // Add user message to history
      _chatHistory.add({
        'role': 'user',
        'content': fullMessage,
      });
      
      // Call Groq API (OpenAI-compatible)
      final url = Uri.parse(
        'https://api.groq.com/openai/v1/chat/completions'
      );
      
      print('🔑 API Key starts with: ${_apiKey?.substring(0, 10)}... length: ${_apiKey?.length}');
      
      final body = jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': _chatHistory,
        'temperature': 0.7,
        'top_p': 0.95,
        'max_tokens': 2048,
      });
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] ?? 
            'Sorry, I could not generate a response.';
        
        // Add bot response to history
        _chatHistory.add({
          'role': 'assistant',
          'content': text,
        });
        
        // Keep history manageable (last 20 exchanges)
        if (_chatHistory.length > 42) {
          // Keep first 2 (system prompt + ack) and last 40
          final systemPart = _chatHistory.sublist(0, 2);
          final recentPart = _chatHistory.sublist(_chatHistory.length - 40);
          _chatHistory.clear();
          _chatHistory.addAll(systemPart);
          _chatHistory.addAll(recentPart);
        }
        
        return text;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Unknown API error';
        print('❌ Groq API error (${response.statusCode}): $errorMsg');
        
        // Remove the failed user message from history
        if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
          _chatHistory.removeLast();
        }
        
        return 'Sorry, I couldn\'t process that request. Error: $errorMsg';
      }
    } catch (e) {
      print('❌ Chatbot error: $e');
      
      // Remove the failed user message from history
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      
      return 'Sorry, I encountered a connection error. Please check your internet and try again.';
    }
  }
  
  /// Ask a specific coding question
  Future<String> askCodingQuestion(String question, String language) async {
    final enhancedQuestion = '''
I need help with a $language programming question:

$question

Please provide:
1. Explanation of the concept
2. Code example in $language with comments
3. Time and space complexity (if applicable)
4. Common mistakes to avoid
''';
    
    return await sendMessage(enhancedQuestion);
  }
  
  /// Get explanation for a concept
  Future<String> explainConcept(String concept, String topic) async {
    final question = '''
Explain "$concept" in the context of $topic.

Please provide:
1. Simple definition
2. Real-world analogy
3. Code example (if relevant) with comments
4. Key points to remember
''';
    
    return await sendMessage(question);
  }
  
  /// Get hints for a problem
  Future<String> getHint(String problemDescription) async {
    final question = '''
I'm stuck on this problem:

$problemDescription

Give me a hint to help me solve it. Don't give the complete solution — just guide me in the right direction with a step-by-step thinking approach.
''';
    
    return await sendMessage(question);
  }
  
  /// Review code and provide feedback
  Future<String> reviewCode(String code, String language) async {
    final question = '''
Review this $language code and provide feedback:

```$language
$code
```

Please check for:
1. Correctness
2. Time/space complexity
3. Code quality and best practices
4. Potential edge cases
5. Suggestions for improvement
''';
    
    return await sendMessage(question);
  }
  
  /// Generate a practice question
  Future<String> generatePracticeQuestion(String topic, String difficulty) async {
    final question = '''
Generate a $difficulty level practice question on "$topic" for the $_currentCourse course.

Include:
1. The problem statement
2. Sample input/output (if applicable)
3. Hints
''';
    
    return await sendMessage(question);
  }
  
  /// Start a new chat session (reset history)
  void resetChat() {
    if (_initialized) {
      _chatHistory.clear();
      _chatHistory.add({
        'role': 'system',
        'content': _getSystemPrompt(_currentCourse),
      });
      _chatHistory.add({
        'role': 'assistant',
        'content': 'Chat reset! I\'m ready to help you again. Ask me anything!',
      });
      print('🔄 Chat session reset');
    }
  }
}
