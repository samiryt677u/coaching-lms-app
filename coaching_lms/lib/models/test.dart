import 'user.dart';

class TestSummary {
  final int id;
  final String title;
  final String? subject;
  final int durationMinutes;
  final int totalMarks;
  final double negativeMarking;
  final int questionCount;
  final String status;
  final String? attemptStatus; // null | in_progress | submitted (student view only)
  final double? myScore;

  TestSummary({
    required this.id,
    required this.title,
    this.subject,
    required this.durationMinutes,
    required this.totalMarks,
    required this.negativeMarking,
    required this.questionCount,
    required this.status,
    this.attemptStatus,
    this.myScore,
  });

  factory TestSummary.fromJson(Map<String, dynamic> json) {
    return TestSummary(
      id: toInt(json['id']),
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString(),
      durationMinutes: toInt(json['duration_minutes']),
      totalMarks: toInt(json['total_marks']),
      negativeMarking: toDouble(json['negative_marking']),
      questionCount: toInt(json['question_count']),
      status: json['status']?.toString() ?? 'draft',
      attemptStatus: json['attempt_status']?.toString(),
      myScore: json['my_score'] != null ? toDouble(json['my_score']) : null,
    );
  }
}

class TestQuestion {
  final int id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int marks;

  TestQuestion({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.marks,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: toInt(json['id']),
      questionText: json['question_text']?.toString() ?? '',
      optionA: json['option_a']?.toString() ?? '',
      optionB: json['option_b']?.toString() ?? '',
      optionC: json['option_c']?.toString() ?? '',
      optionD: json['option_d']?.toString() ?? '',
      marks: toInt(json['marks']),
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final int studentId;
  final String studentName;
  final double score;
  final String submittedAt;

  LeaderboardEntry({
    required this.rank,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.submittedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: toInt(json['rank']),
      studentId: toInt(json['student_id']),
      studentName: json['student_name']?.toString() ?? '',
      score: toDouble(json['score']),
      submittedAt: json['submitted_at']?.toString() ?? '',
    );
  }
}
