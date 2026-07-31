import 'user.dart';

class StudyMaterialItem {
  final int id;
  final int batchId;
  final String subject;
  final String? chapter;
  final String title;
  final String fileType; // pdf | doc | image | video
  final String filePath;
  final String uploadedAt;
  final String batchName;
  final String uploaderName;

  StudyMaterialItem({
    required this.id,
    required this.batchId,
    required this.subject,
    this.chapter,
    required this.title,
    required this.fileType,
    required this.filePath,
    required this.uploadedAt,
    required this.batchName,
    required this.uploaderName,
  });

  factory StudyMaterialItem.fromJson(Map<String, dynamic> json) {
    return StudyMaterialItem(
      id: toInt(json['id']),
      batchId: toInt(json['batch_id']),
      subject: json['subject']?.toString() ?? '',
      chapter: json['chapter']?.toString(),
      title: json['title']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'pdf',
      filePath: json['file_path']?.toString() ?? '',
      uploadedAt: json['uploaded_at']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      uploaderName: json['uploader_name']?.toString() ?? '',
    );
  }
}
