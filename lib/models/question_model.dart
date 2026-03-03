/// Model for quiz questions (both MCQ and Coding)
class QuestionModel {
  final String id;
  final String topicId;
  final String courseId;
  final String questionText;
  final String type; // 'quiz' or 'coding'
  final String? codeSnippet; // For quiz type
  final List<String> options; // For quiz type
  final int? correctOptionIndex; // For quiz type
  final String? explanation;
  
  // Coding specific fields
  final String? starterCode;
  final String? constraints;
  final String? difficulty;
  final List<TestCase> testCases;

  QuestionModel({
    required this.id,
    required this.topicId,
    this.courseId = '',
    required this.questionText,
    this.type = 'quiz',
    this.codeSnippet,
    this.options = const [],
    this.correctOptionIndex,
    this.explanation,
    this.starterCode,
    this.constraints,
    this.difficulty,
    this.testCases = const [],
  });

  factory QuestionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return QuestionModel(
      id: id,
      topicId: data['topicId'] ?? '',
      courseId: data['courseId'] ?? '',
      questionText: data['questionText'] ?? '',
      type: data['type'] ?? 'quiz',
      codeSnippet: data['codeSnippet'],
      options: List<String>.from(data['options'] ?? []),
      correctOptionIndex: data['correctOptionIndex'],
      explanation: data['explanation'],
      starterCode: data['starterCode'],
      constraints: data['constraints'],
      difficulty: data['difficulty'],
      testCases: (data['testCases'] as List? ?? [])
          .map((t) => TestCase.fromMap(t))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'courseId': courseId,
      'questionText': questionText,
      'type': type,
      'codeSnippet': codeSnippet,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'starterCode': starterCode,
      'constraints': constraints,
      'difficulty': difficulty,
      'testCases': testCases.map((t) => t.toMap()).toList(),
    };
  }
}

class TestCase {
  final String input;
  final String output;
  final bool isHidden;

  TestCase({
    required this.input,
    required this.output,
    this.isHidden = false,
  });

  factory TestCase.fromMap(Map<String, dynamic> map) {
    return TestCase(
      input: map['input'] ?? '',
      output: map['output'] ?? '',
      isHidden: map['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'input': input,
      'output': output,
      'isHidden': isHidden,
    };
  }
}
