import 'user.dart';

class AttendanceRecord {
  final int id;
  final int batchId;
  final int studentId;
  final String attendanceDate;
  final String status; // present | absent | leave

  AttendanceRecord({
    required this.id,
    required this.batchId,
    required this.studentId,
    required this.attendanceDate,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: toInt(json['id']),
      batchId: toInt(json['batch_id']),
      studentId: toInt(json['student_id']),
      attendanceDate: json['attendance_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'absent',
    );
  }
}

class AttendanceSummary {
  final int total;
  final int present;
  final double percentage;

  AttendanceSummary({required this.total, required this.present, required this.percentage});

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      total: toInt(json['total']),
      present: toInt(json['present']),
      percentage: toDouble(json['percentage']),
    );
  }
}

class LeaveRequestItem {
  final int id;
  final int batchId;
  final String leaveDate;
  final String reason;
  final String status; // pending | approved | rejected
  final String batchName;
  final String createdAt;

  LeaveRequestItem({
    required this.id,
    required this.batchId,
    required this.leaveDate,
    required this.reason,
    required this.status,
    required this.batchName,
    required this.createdAt,
  });

  factory LeaveRequestItem.fromJson(Map<String, dynamic> json) {
    return LeaveRequestItem(
      id: toInt(json['id']),
      batchId: toInt(json['batch_id']),
      leaveDate: json['leave_date']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      batchName: json['batch_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
