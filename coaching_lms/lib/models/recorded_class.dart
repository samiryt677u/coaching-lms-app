import 'user.dart';

class RecordedClassItem {
  final int id;
  final int batchId;
  final String subject;
  final String? chapter;
  final String title;
  final String videoUrl;
  final int? durationMinutes;
  final String uploadedAt;
  final String batchName;
  final String teacherName;

  RecordedClassItem({
    required this.id,
    required this.batchId,
    required this.subject,
    this.chapter,
    required this.title,
    required this.videoUrl,
    this.durationMinutes,
    required this.uploadedAt,
    required this.batchName,
    required this.teacherName,
  });

  factory RecordedClassItem.fromJson(Map<String, dynamic> json) {
    return RecordedClassItem(
      id: toInt(json['id']),
      batchId: toInt(json['batch_id']),
      subject: json['subject']?.toString() ?? '',
      chapter: json['chapter']?.toString(),
      title: json['title']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      durationMinutes: json['duration_minutes'] != null ? toInt(json['duration_minutes']) : null,
      uploadedAt: json['uploaded_at']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
    );
  }
}
