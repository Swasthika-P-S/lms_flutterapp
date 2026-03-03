import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for API keys loaded from the .env file.
class ApiKeys {
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';
}
