import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

/// Provider for Groq AI Chatbot
class ChatbotProvider extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  
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
    
    // Start loading
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _chatbotService.sendMessage(message, context: context);
      
      // Add bot response
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
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _chatbotService.askCodingQuestion(question, language);
      
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      
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
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
