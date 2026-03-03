import 'package:intl/intl.dart';

class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime deadline;
  final int maxScore;
  final DateTime createdAt;
  final String createdBy;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.maxScore,
    required this.createdAt,
    required this.createdBy,
  });

  bool get isOverdue => DateTime.now().isAfter(deadline);
  Duration get timeRemaining => deadline.difference(DateTime.now());
  String get formattedDeadline =>
      DateFormat('MMM dd, yyyy HH:mm').format(deadline);

  factory Assignment.fromMap(Map<String, dynamic> map, String id) {
    return Assignment(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: map['deadline'] != null 
          ? DateTime.parse(map['deadline'].toString()) 
          : DateTime.now(),
      maxScore: map['maxScore'] ?? 100,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'].toString()) 
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'maxScore': maxScore,
      'createdBy': createdBy,
    };
  }
}
