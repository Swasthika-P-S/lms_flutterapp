import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/chatbot_service.dart';

/// Provider for Groq AI Chatbot with course-specific context
class ChatbotProvider extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String _selectedCourse = 'General';
  bool _isChatOpen = false;

  bool get isChatOpen => _isChatOpen;

  ChatbotProvider() {
    _initializeWithKey();
  }

  Future<void> _initializeWithKey() async {
    // Wait briefly for dotenv to ensure it's loaded if called very early
    // although main() handles it, this is safer for early provider access
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      await initialize(apiKey);
    } else {
      print('⚠️ ChatbotProvider: GROQ_API_KEY not found in .env');
      _errorMessage = 'AI API key not found in configuration.';
      notifyListeners();
    }
  }
  
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String get selectedCourse => _selectedCourse;
  
  /// Available courses
  static const List<String> courses = ['General', 'DSA', 'C', 'OOPs'];
  
  /// Quick prompts per course
  static const Map<String, List<String>> quickPrompts = {
    'General': [
      'How do I start learning programming?',
      'What topics should I focus on?',
      'Explain Big O notation',
      'Compare arrays vs linked lists',
    ],
    'DSA': [
      'Explain Binary Search with an example',
      'How does a Stack work?',
      'What is Dynamic Programming?',
      'Difference between BFS and DFS',
      'Explain time complexity of sorting',
      'What is a Hash Table?',
    ],
    'C': [
      'What are pointers in C?',
      'Explain malloc vs calloc',
      'How does a struct work?',
      'Difference between array and pointer',
      'What is a dangling pointer?',
      'Explain file I/O in C',
    ],
    'OOPs': [
      'Explain the 4 pillars of OOPs',
      'What is polymorphism?',
      'Difference between abstract class and interface',
      'Explain method overloading vs overriding',
      'What are SOLID principles?',
      'When to use inheritance vs composition?',
    ],
  };
  
  /// Get quick prompts for current course
  List<String> get currentQuickPrompts => 
      quickPrompts[_selectedCourse] ?? quickPrompts['General']!;
  
  /// Initialize chatbot with API key
  Future<void> initialize(String apiKey) async {
    if (_isInitialized) return;
    
    try {
      await _chatbotService.initialize(apiKey);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize chatbot: $e';
      notifyListeners();
    }
  }
  
  /// Switch course context
  void switchCourse(String course) {
    if (_selectedCourse == course) return;
    _selectedCourse = course;
    _chatbotService.switchCourse(course);
    _messages.clear();
    _messages.add(ChatMessage(
      text: _getWelcomeMessage(course),
      isUser: false,
      timestamp: DateTime.now(),
      isSystemMessage: true,
    ));
    notifyListeners();
  }

  String _getWelcomeMessage(String course) {
    switch (course) {
      case 'DSA':
        return '📊 **DSA Mode Active!**\n\nI\'m ready to help you with Data Structures & Algorithms. Ask me about arrays, trees, graphs, sorting, dynamic programming, and more!\n\nTry one of the quick prompts below to get started.';
      case 'C':
        return '⚙️ **C Programming Mode Active!**\n\nI\'m here to help you master C programming. Ask me about pointers, memory management, file handling, and more!\n\nTry one of the quick prompts below to get started.';
      case 'OOPs':
        return '🧩 **OOPs Mode Active!**\n\nLet\'s explore Object-Oriented Programming together. Ask me about classes, inheritance, polymorphism, design patterns, and more!\n\nTry one of the quick prompts below to get started.';
      default:
        return '👋 **Welcome to LearnBot!**\n\nI\'m your AI study assistant. Select a course above or ask me anything about programming!\n\nTry one of the quick prompts below to get started.';
    }
  }
  
  /// Send a message to the chatbot
  Future<void> sendMessage(String message, {String? context}) async {
    if (!_isInitialized) {
      _errorMessage = 'Chatbot not initialized';
      return;
    }
    
    // Add user message
    _messages.add(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _chatbotService.sendMessage(message, context: context);
      
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _errorMessage = 'Error getting response: $e';
      _messages.add(ChatMessage(
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Ask a coding question
  Future<void> askCodingQuestion(String question, String language) async {
    if (!_isInitialized) return;
    
    _messages.add(ChatMessage(
      text: question,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _chatbotService.askCodingQuestion(question, language);
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get explanation for a concept
  Future<void> explainConcept(String concept, String topic) async {
    if (!_isInitialized) return;
    
    final question = 'Explain $concept in $topic';
    _messages.add(ChatMessage(
      text: question,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _chatbotService.explainConcept(concept, topic);
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Toggle chatbot panel open/closed
  void toggleChat() {
    _isChatOpen = !_isChatOpen;
    notifyListeners();
  }

  /// Open chatbot panel
  void openChat() {
    _isChatOpen = true;
    notifyListeners();
  }

  /// Voice shortcut: open the chatbot and immediately send a message
  Future<void> openAndSendMessage(String message) async {
    openChat();
    await sendMessage(message);
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _chatbotService.resetChat();
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool isSystemMessage;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.isSystemMessage = false,
  });
}
