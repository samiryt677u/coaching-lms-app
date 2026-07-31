import 'user.dart';

class Batch {
  final int id;
  final String name;
  final String? courseType;
  final String? description;
  final String? startDate;
  final String status;

  Batch({
    required this.id,
    required this.name,
    this.courseType,
    this.description,
    this.startDate,
    required this.status,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: toInt(json['id']),
      name: json['name']?.toString() ?? '',
      courseType: json['course_type']?.toString(),
      description: json['description']?.toString(),
      startDate: json['start_date']?.toString(),
      status: json['status']?.toString() ?? 'active',
    );
  }
}
