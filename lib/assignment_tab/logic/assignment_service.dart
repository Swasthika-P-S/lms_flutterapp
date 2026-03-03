import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/assignment.dart';
import '../data/submission.dart';
import 'notification_service.dart';

class AssignmentService {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;
  AssignmentService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications = NotificationService();

  // Helper to convert Assignment to Map
  Map<String, dynamic> _asgToMap(Assignment a) => {
    'courseId': a.courseId,
    'title': a.title,
    'description': a.description,
    'deadline': Timestamp.fromDate(a.deadline),
    'maxScore': a.maxScore,
    'createdAt': Timestamp.fromDate(a.createdAt),
    'createdBy': a.createdBy,
  };

  // Helper to convert Submission to Map
  Map<String, dynamic> _subToMap(Submission s) => {
    'assignmentId': s.assignmentId,
    'studentId': s.studentId,
    'studentName': s.studentName,
    'content': s.content,
    'submittedAt': Timestamp.fromDate(s.submittedAt),
    'score': s.score,
    'feedback': s.feedback,
    'status': s.status,
  };

  // CREATE
  Future<String> createAssignment(Assignment assignment) async {
    final doc = await _db.collection('assignments').add(_asgToMap(assignment));
    _notifications.sendInApp(
      'New Assignment: ${assignment.title}',
      'Due: ${assignment.formattedDeadline}',
    );
    return doc.id;
  }

  // READ
  Stream<List<Assignment>> getAssignmentsByCourse(String courseId) {
    return _db
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return Assignment(
                id: doc.id,
                courseId: data['courseId'],
                title: data['title'],
                description: data['description'],
                deadline: (data['deadline'] as Timestamp).toDate(),
                maxScore: data['maxScore'],
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                createdBy: data['createdBy'],
              );
            }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline)));
  }

  Future<Assignment?> getAssignment(String assignmentId) async {
    final doc = await _db.collection('assignments').doc(assignmentId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Assignment(
      id: doc.id,
      courseId: data['courseId'],
      title: data['title'],
      description: data['description'],
      deadline: (data['deadline'] as Timestamp).toDate(),
      maxScore: data['maxScore'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
    );
  }

  // UPDATE
  Future<void> updateAssignment(String id, Map<String, dynamic> updates) async {
    if (updates.containsKey('deadline') && updates['deadline'] is DateTime) {
      updates['deadline'] = Timestamp.fromDate(updates['deadline']);
    }
    await _db.collection('assignments').doc(id).update(updates);
  }

  // DELETE
  Future<void> deleteAssignment(String id) async {
    await _db.collection('assignments').doc(id).delete();
    // Potentially delete related submissions too
    final subs = await _db.collection('submissions').where('assignmentId', isEqualTo: id).get();
    for (var doc in subs.docs) {
      await doc.reference.delete();
    }
  }

  // SUBMIT
  Future<String> submitAssignment(Submission submission) async {
    final doc = await _db.collection('submissions').add(_subToMap(submission));
    _notifications.sendInApp(
      'Submission received',
      '${submission.studentName} submitted an assignment',
    );
    return doc.id;
  }

  Stream<List<Submission>> getSubmissionsByAssignment(String assignmentId) {
    return _db
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return Submission(
                id: doc.id,
                assignmentId: data['assignmentId'],
                studentId: data['studentId'],
                studentName: data['studentName'],
                content: data['content'],
                submittedAt: (data['submittedAt'] as Timestamp).toDate(),
                score: data['score'],
                feedback: data['feedback'],
                status: data['status'],
              );
            }).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt)));
  }

  Future<void> gradeSubmission(String submissionId, int score, String feedback) async {
    await _db.collection('submissions').doc(submissionId).update({
      'score': score,
      'feedback': feedback,
      'status': 'graded',
    });
    final doc = await _db.collection('submissions').doc(submissionId).get();
    final name = doc.data()?['studentName'] ?? 'Student';
    _notifications.sendInApp('Submission graded', '$name scored $score');
  }

  // DEADLINES
  Stream<List<Assignment>> getUpcomingDeadlines(String courseId) {
    final now = DateTime.now();
    final inAWeek = now.add(const Duration(days: 7));
    return _db
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .where('deadline', isGreaterThan: Timestamp.fromDate(now))
        .where('deadline', isLessThan: Timestamp.fromDate(inAWeek))
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return Assignment(
                id: doc.id,
                courseId: data['courseId'],
                title: data['title'],
                description: data['description'],
                deadline: (data['deadline'] as Timestamp).toDate(),
                maxScore: data['maxScore'],
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                createdBy: data['createdBy'],
              );
            }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline)));
  }
}
