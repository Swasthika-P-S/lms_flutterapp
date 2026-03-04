import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini AI chatbot service for placement assistance
class ChatbotService {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _initialized = false;
  
  /// Initialize the chatbot with API key
  Future<void> initialize(String apiKey) async {
    if (_initialized) return;
    
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );
      
      // Start a new chat session with placement-focused system prompt
      _chat = _model.startChat(history: [
        Content.text(_getSystemPrompt()),
      ]);
      
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
You are a helpful AI assistant for a placement preparation portal. You help students prepare for technical interviews in:
- Data Structures & Algorithms (DSA)
- Database Management Systems (DBMS)
- Object-Oriented Programming (OOPs)
- C++ Programming
- Java Development

Your role is to:
1. Explain complex concepts in simple terms
2. Provide code examples when asked
3. Help debug code problems
4. Suggest problem-solving approaches
5. Give interview tips and best practices
6. Be encouraging and motivating

Guidelines:
- Keep explanations concise and clear
- Use code blocks for code examples with proper syntax highlighting
- Use bullet points for lists
- Be patient and supportive
- If you don't know something, admit it honestly
- Focus on practical, interview-relevant knowledge

Format your responses in Markdown for better readability.
''';
  }
  
  /// Send a message to the chatbot
  Future<String> sendMessage(String message, {String? context}) async {
    if (!_initialized) {
      throw Exception('Chatbot not initialized. Call initialize() first.');
    }
    
    try {
      // Add context if provided (e.g., current topic, problem details)
      String fullMessage = message;
      if (context != null && context.isNotEmpty) {
        fullMessage = 'Context: $context\n\nQuestion: $message';
      }
      
      final response = await _chat.sendMessage(Content.text(fullMessage));
      final text = response.text ?? 'Sorry, I could not generate a response.';
      
      print('💬 Bot response: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      return text;
      
    } catch (e) {
      print('❌ Chatbot error: $e');
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
      _chat = _model.startChat(history: [
        Content.text(_getSystemPrompt()),
      ]);
      print('🔄 Chat session reset');
    }
  }
}
