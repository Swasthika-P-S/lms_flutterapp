class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String? content;
  final String? fileName;
  final String? fileUrl;
  final DateTime submittedAt;
  final int? score;
  final String? feedback;
  final String status;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    this.content,
    this.fileName,
    this.fileUrl,
    required this.submittedAt,
    this.score,
    this.feedback,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'content': content,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'submittedAt': submittedAt.toIso8601String(),
      'score': score,
      'feedback': feedback,
      'status': status,
    };
  }

  factory Submission.fromMap(Map<String, dynamic> map, String id) {
    return Submission(
      id: id,
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      content: map['content'],
      fileName: map['fileName'],
      fileUrl: map['fileUrl'],
      submittedAt: map['submittedAt'] != null 
          ? DateTime.parse(map['submittedAt']) 
          : DateTime.now(),
      score: map['score'],
      feedback: map['feedback'],
      status: map['status'] ?? 'submitted',
    );
  }

  Submission copyWith({
    int? score,
    String? feedback,
    String? status,
  }) {
    return Submission(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      studentName: studentName,
      content: content,
      fileName: fileName,
      fileUrl: fileUrl,
      submittedAt: submittedAt,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      status: status ?? this.status,
    );
  }
}
