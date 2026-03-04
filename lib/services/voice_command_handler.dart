import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chatbot_provider.dart';

/// Parses natural language voice commands and acts on them.
/// Supports:
///   Navigation  : "go to home / courses / quizzes / tasks / profile / coding"
///   Chatbot     : "ask [something]" / "search [something]" / "chatbot [something]"
class VoiceCommandHandler {
  static void handleCommand(
    String command,
    BuildContext context,
    Function(int) navigateToTab,
  ) {
    final lc = command.toLowerCase().trim();

    // ── 1. Chatbot search / ask ──────────────────────────────────────────────
    // Patterns: "ask ...", "search ...", "chatbot ...", "hey chatbot ...",
    //           "tell chatbot ...", "ask chatbot ..."
    final chatbotPrefixes = [
      RegExp(r'^(ask chatbot|ask the chatbot)\s+(.+)', caseSensitive: false),
      RegExp(r'^ask\s+(.+)', caseSensitive: false),
      RegExp(r'^search\s+(.+)', caseSensitive: false),
      RegExp(r'^(chatbot|hey chatbot|tell chatbot)\s+(.+)', caseSensitive: false),
      RegExp(r'^(explain|what is|what are|how to|how does|define)\s+(.+)', caseSensitive: false),
    ];

    for (final pattern in chatbotPrefixes) {
      final match = pattern.firstMatch(command);
      if (match != null) {
        // Extract the query — last captured group contains the actual question
        final query = (match.groupCount >= 2
            ? match.group(match.groupCount)
            : match.group(1)) ?? command;

        if (query.trim().isNotEmpty) {
          final chatbot = Provider.of<ChatbotProvider>(context, listen: false);
          chatbot.openAndSendMessage(query.trim());
          return;
        }
      }
    }

    // ── 2. Navigation ────────────────────────────────────────────────────────
    // Tab index matches StudentShell: Home=0 Courses=1 Coding=2 Quizzes=3 Tasks=4 Profile=5

    if (lc.contains('home') || lc.contains('होम') || lc.contains('dashboard')) {
      navigateToTab(0);
    } else if (lc.contains('course') || lc.contains('कोर्स')) {
      navigateToTab(1);
    } else if (lc.contains('coding') || lc.contains('code') || lc.contains('challenge')) {
      navigateToTab(2);
    } else if (lc.contains('quiz') || lc.contains('quizzes') || lc.contains('क्विज')) {
      navigateToTab(3);
    } else if (lc.contains('task') || lc.contains('assignment') || lc.contains('टास्क')) {
      navigateToTab(4);
    } else if (lc.contains('profile') || lc.contains('प्रोफाइल')) {
      navigateToTab(5);
    } else if (lc.contains('setting') || lc.contains('सेटिंग')) {
      // Settings screen — if you have a tab for it add the index, else open settings
      navigateToTab(5); // falls back to profile for now
    } else {
      // Unknown command — treat the whole thing as a chatbot question
      final chatbot = Provider.of<ChatbotProvider>(context, listen: false);
      chatbot.openAndSendMessage(command.trim());
    }
  }
}
