import 'dart:convert';
import 'package:http/http.dart' as http;

/// Groq AI chatbot service for placement assistance
class ChatbotService {
  String? _apiKey;
  bool _initialized = false;
  
  // Chat history in OpenAI format
  final List<Map<String, String>> _chatHistory = [];
  
  /// Initialize the chatbot with API key
  Future<void> initialize(String apiKey) async {
    if (_initialized) return;
    
    try {
      _apiKey = apiKey;
      _chatHistory.clear();
      
      // Add system prompt
      _chatHistory.add({
        'role': 'system',
        'content': _getSystemPrompt(),
      });
      
      _initialized = true;
      print('✅ Chatbot initialized successfully');
    } catch (e) {
      print('❌ Chatbot initialization error: $e');
      rethrow;
    }
  }
  
  /// Get system prompt for placement assistant
  String _getSystemPrompt() {
    return '''
You are a helpful AI study assistant. You ONLY help students with these three subjects:
1. Data Structures & Algorithms (DSA)
2. Object-Oriented Programming (OOPs)
3. C Programming

STRICT RULE: If a student asks about ANY topic outside of DSA, OOPs, or C Programming, you MUST:
- Politely decline and say: "I can only help with DSA, OOPs, and C Programming. Please ask a question related to one of these subjects."
- Do NOT answer the off-topic question at all, even partially
- This includes: web development, databases, DBMS, Python, Java, networking, OS, or any other subject

Your role is to:
1. Explain DSA, OOPs, and C concepts in simple terms
2. Provide code examples in C or C++ when asked
3. Help debug C code problems
4. Suggest problem-solving approaches for DSA
5. Be encouraging and motivating

Guidelines:
- Keep explanations concise and clear
- Use code blocks for code examples with proper syntax highlighting
- Use bullet points for lists
- Be patient and supportive
- If you don't know something, admit it honestly

Format your responses in Markdown for better readability.
''';
  }
  
  /// Send a message via Groq API
  Future<String> _callGroq(String userMessage) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': _chatHistory,
      'temperature': 0.7,
      'top_p': 0.95,
      'max_tokens': 1024,
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
      
      // Add assistant response to history
      _chatHistory.add({
        'role': 'assistant',
        'content': text,
      });
      
      // Keep history manageable
      if (_chatHistory.length > 42) {
        final systemPart = _chatHistory.sublist(0, 1);
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
      
      return 'Sorry, I encountered an error. Please try again.';
    }
  }
  
  /// Send a message to the chatbot
  Future<String> sendMessage(String message, {String? context}) async {
    if (!_initialized || _apiKey == null) {
      throw Exception('Chatbot not initialized. Call initialize() first.');
    }
    
    try {
      String fullMessage = message;
      if (context != null && context.isNotEmpty) {
        fullMessage = 'Context: $context\n\nQuestion: $message';
      }
      
      _chatHistory.add({
        'role': 'user',
        'content': fullMessage,
      });
      
      final text = await _callGroq(fullMessage);
      print('💬 Bot response: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      return text;
      
    } catch (e) {
      print('❌ Chatbot error: $e');
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      return 'Sorry, I encountered an error. Please try again.';
    }
  }
  
  /// Ask a specific coding question
  Future<String> askCodingQuestion(String question, String language) async {
    final enhancedQuestion = '''
I need help with a $language programming question:

$question

Please provide:
1. Explanation of the concept
2. Code example in $language
3. Time and space complexity (if applicable)
4. Common pitfalls to avoid
''';
    
    return await sendMessage(enhancedQuestion);
  }
  
  /// Get explanation for a concept
  Future<String> explainConcept(String concept, String topic) async {
    final question = '''
Can you explain the concept of "$concept" in the context of $topic?

Please provide:
1. Simple definition
2. Real-world analogy
3. Example (with code if relevant)
4. Why it's important for interviews
''';
    
    return await sendMessage(question);
  }
  
  /// Get hints for a problem without giving away the full solution
  Future<String> getHint(String problemDescription) async {
    final question = '''
I'm stuck on this problem:

$problemDescription

Can you give me a hint to help me solve it? Please don't give me the complete solution, just guide me in the right direction.
''';
    
    return await sendMessage(question);
  }
  
  /// Review code and provide feedback
  Future<String> reviewCode(String code, String language) async {
    final question = '''
Can you review this $language code and provide feedback?

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
  
  /// Get interview tips for a specific topic
  Future<String> getInterviewTips(String topic) async {
    final question = '''
What are the most important things to know about $topic for technical interviews?

Please provide:
1. Key concepts to master
2. Common interview questions
3. Problem-solving patterns
4. Tips for answering confidently
''';
    
    return await sendMessage(question);
  }
  
  /// Start a new chat session (reset history)
  void resetChat() {
    if (_initialized) {
      _chatHistory.clear();
      _chatHistory.add({
        'role': 'system',
        'content': _getSystemPrompt(),
      });
      print('🔄 Chat session reset');
    }
  }
}
