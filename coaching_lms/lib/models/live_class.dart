import 'user.dart';

class LiveClassItem {
  final int id;
  final int batchId;
  final int teacherId;
  final String subject;
  final String title;
  final String meetLink;
  final String classDate;
  final String startTime;
  final int durationMinutes;
  final String status;
  final String batchName;
  final String teacherName;

  LiveClassItem({
    required this.id,
    required this.batchId,
    required this.teacherId,
    required this.subject,
    required this.title,
    required this.meetLink,
    required this.classDate,
    required this.startTime,
    required this.durationMinutes,
    required this.status,
    required this.batchName,
    required this.teacherName,
  });

  factory LiveClassItem.fromJson(Map<String, dynamic> json) {
    return LiveClassItem(
      id: toInt(json['id']),
      batchId: toInt(json['batch_id']),
      teacherId: toInt(json['teacher_id']),
      subject: json['subject']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      meetLink: json['meet_link']?.toString() ?? '',
      classDate: json['class_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      durationMinutes: toInt(json['duration_minutes']),
      status: json['status']?.toString() ?? 'scheduled',
      batchName: json['batch_name']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
    );
  }
}
