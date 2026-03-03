import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../models/question_model.dart';

/// Service for interacting with the Node.js/MongoDB backend
class MongoService {
  // Use 10.0.2.2 for Android emulator, localhost for Web/iOS
  static const String _baseUrl = kIsWeb 
      ? 'http://localhost:5000/api' 
      : 'http://10.12.252.182:5000/api';

  static String get serverUrl => _baseUrl.replaceAll('/api', '');

  // Session-based cache for quiz results (topicId -> (questionIndex -> selectedOptionIndex))
  static final Map<String, Map<int, int>> _lastAnswersCache = {};

  static void saveQuizResults(String topicId, Map<int, int> answers) {
    _lastAnswersCache[topicId] = Map.from(answers);
  }

  static Map<int, int> getQuizResults(String topicId) {
    return _lastAnswersCache[topicId] ?? {};
  }

  /// Get all courses from MongoDB
  static Future<List<CourseModel>> getCourses() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CourseModel.fromFirestore(json, json['courseId'] ?? json['_id'] ?? '')).toList();
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      print('❌ MongoService Error (getCourses): $e');
      rethrow;
    }
  }

  /// Get topics for a specific course
  static Future<List<Topic>> getTopics(String courseId) async {
    try {
      final url = '$_baseUrl/topics/$courseId';
      print('🌐 MongoService: GET $url');
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ MongoService: Found ${data.length} topics');
        return data.map((json) => Topic.fromMap({...json, 'id': json['_id']} ?? {})).toList();
      } else {
        print('❌ MongoService Error: Status ${response.statusCode}');
        throw Exception('Failed to load topics');
      }
    } catch (e) {
      print('❌ MongoService Error (getTopics): $e');
      rethrow;
    }
  }

  /// Get questions for a specific topic
  static Future<List<QuestionModel>> getQuestions(String topicId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/questions/$topicId'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => QuestionModel.fromFirestore(json, json['_id'])).toList();
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      print('❌ MongoService Error (getQuestions): $e');
      rethrow;
    }
  }

  /// Get assignments for a specific course
  static Future<List<dynamic>> getAssignments(String courseId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/assignments/$courseId'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load assignments');
      }
    } catch (e) {
      print('❌ MongoService Error (getAssignments): $e');
      rethrow;
    }
  }

  /// Create a new assignment
  static Future<void> createAssignment(Map<String, dynamic> assignmentData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/assignments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(assignmentData),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode != 201) {
        throw Exception('Failed to create assignment: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (createAssignment): $e');
      rethrow;
    }
  }

  /// Add a new topic
  static Future<void> addTopic(String courseId, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/topics'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'courseId': courseId,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode != 201) {
        throw Exception('Failed to create topic: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (addTopic): $e');
      rethrow;
    }
  }

  /// Delete a topic (and its questions)
  static Future<void> deleteTopic(String topicId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/topics/$topicId'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete topic: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (deleteTopic): $e');
      rethrow;
    }
  }

  /// Save or update a question
  static Future<void> saveQuestion(QuestionModel question) async {
    try {
      final url = question.id.isEmpty 
          ? '$_baseUrl/questions' 
          : '$_baseUrl/questions/${question.id}';
      
      final method = question.id.isEmpty ? http.post : http.put;
      
      final response = await method(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(question.toMap()),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save question: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (saveQuestion): $e');
      rethrow;
    }
  }

  /// Delete a question
  static Future<void> deleteQuestion(String questionId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/questions/$questionId'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete question: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (deleteQuestion): $e');
      rethrow;
    }
  }

  /// Seed the database with initial data
  static Future<void> seedDatabase() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/seed'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Failed to seed database: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (seedDatabase): $e');
      rethrow;
    }
  }

  /// Submit an assignment (text-only)
  static Future<Map<String, dynamic>> submitAssignment(Map<String, dynamic> data) async {
    try {
      print('📤 Submitting to: $_baseUrl/submissions');
      final response = await http.post(
        Uri.parse('$_baseUrl/submissions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(const Duration(seconds: 25));
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit assignment: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (submitAssignment): $e');
      rethrow;
    }
  }

  /// Get submissions for an assignment
  static Future<List<dynamic>> getSubmissions(String assignmentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/submissions/$assignmentId'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load submissions');
      }
    } catch (e) {
      print('❌ MongoService Error (getSubmissions): $e');
      rethrow;
    }
  }

  /// Grade a submission
  static Future<void> gradeSubmission(String submissionId, Map<String, dynamic> gradeData) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/submissions/$submissionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(gradeData),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw Exception('Failed to grade submission: ${response.body}');
      }
    } catch (e) {
      print('❌ MongoService Error (gradeSubmission): $e');
      rethrow;
    }
  }
}
