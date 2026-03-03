import 'dart:async';
import '../data/assignment.dart';
import '../data/submission.dart';
import 'notification_service.dart';
import '../../services/mongo_service.dart';

class AssignmentService {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;
  AssignmentService._internal();

  final Map<String, Assignment> _assignments = {};
  final Map<String, Submission> _submissions = {};

  final StreamController<List<Assignment>> _assignmentsStream =
      StreamController<List<Assignment>>.broadcast();
  final StreamController<List<Submission>> _submissionsStream =
      StreamController<List<Submission>>.broadcast();

  final NotificationService _notifications = NotificationService();

  // CREATE
  Future<String> createAssignment(Assignment assignment) async {
    try {
      await MongoService.createAssignment(assignment.toMap());
      _notifications.sendInApp(
        'New Assignment: ${assignment.title}',
        'Due: ${assignment.formattedDeadline}',
      );
      return "created"; // Backend generates ID
    } catch (e) {
      print('❌ Error in createAssignment: $e');
      rethrow;
    }
  }

  // READ
  Stream<List<Assignment>> getAssignmentsByCourse(String courseId) {
    // Return a stream that polls the backend or just a Future-based fetch converted to stream
    return Stream.fromFuture(MongoService.getAssignments(courseId)).map((list) {
      final assignments = list.map((item) => Assignment.fromMap(item, item['_id'] ?? '')).toList();
      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));
      return assignments;
    });
  }

  Future<Assignment?> getAssignment(String assignmentId) async {
    return _assignments[assignmentId];
  }

  // UPDATE
  Future<void> updateAssignment(String id, Map<String, dynamic> updates) async {
    final existing = _assignments[id];
    if (existing == null) return;
    final updated = Assignment(
      id: existing.id,
      courseId: existing.courseId,
      title: (updates['title'] as String?) ?? existing.title,
      description: (updates['description'] as String?) ?? existing.description,
      deadline: (updates['deadline'] as DateTime?) ?? existing.deadline,
      maxScore: (updates['maxScore'] as int?) ?? existing.maxScore,
      createdAt: existing.createdAt,
      createdBy: existing.createdBy,
    );
    _assignments[id] = updated;
    _emitAssignments();
  }

  // DELETE
  Future<void> deleteAssignment(String id) async {
    _assignments.remove(id);
    _submissions.removeWhere((_, s) => s.assignmentId == id);
    _emitAssignments();
    _emitSubmissions();
  }

  // SUBMIT
  Future<String> submitAssignment(Submission submission) async {
    final id = _generateId('sub');
    final isLate = (_assignments[submission.assignmentId]?.isOverdue ?? false);
    final newSub = Submission(
      id: id,
      assignmentId: submission.assignmentId,
      studentId: submission.studentId,
      studentName: submission.studentName,
      content: submission.content,
      submittedAt: submission.submittedAt,
      score: submission.score,
      feedback: submission.feedback,
      status: isLate ? 'late' : submission.status,
    );
    _submissions[id] = newSub;
    _emitSubmissions();
    _notifications.sendInApp(
      'Submission received',
      '${submission.studentName} submitted an assignment',
    );
    return id;
  }

  Stream<List<Submission>> getSubmissionsByAssignment(String assignmentId) {
    Future.microtask(_emitSubmissions);
    return _submissionsStream.stream.map((list) {
      final filtered = list.where((s) => s.assignmentId == assignmentId).toList();
      filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return filtered;
    });
  }

  Future<void> gradeSubmission(String submissionId, int score, String feedback) async {
    final existing = _submissions[submissionId];
    if (existing == null) return;
    final graded = existing.copyWith(
      score: score,
      feedback: feedback,
      status: 'graded',
    );
    _submissions[submissionId] = graded;
    _emitSubmissions();
    _notifications.sendInApp('Submission graded', '${existing.studentName} scored $score');
  }

  // DEADLINES
  Stream<List<Assignment>> getUpcomingDeadlines(String courseId) {
    Future.microtask(_emitAssignments);
    return _assignmentsStream.stream.map((list) {
      final now = DateTime.now();
      final inAWeek = now.add(const Duration(days: 7));
      final upcoming = list.where((a) =>
          a.courseId == courseId && a.deadline.isAfter(now) && a.deadline.isBefore(inAWeek)).toList();
      upcoming.sort((a, b) => a.deadline.compareTo(b.deadline));
      return upcoming;
    });
  }

  // Emitters
  void _emitAssignments() {
    _assignmentsStream.add(_assignments.values.toList());
  }

  void _emitSubmissions() {
    _submissionsStream.add(_submissions.values.toList());
  }

  // ID generator (fixed)
  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
