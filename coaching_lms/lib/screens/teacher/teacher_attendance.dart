import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/batch.dart';
import '../../widgets/common.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  List<Batch> _batches = [];
  int? _batchId;
  DateTime _date = DateTime.now();
  bool _loadingBatches = true;
  bool _loadingStudents = false;
  bool _saving = false;
  List<Map<String, dynamic>> _students = []; // {id, name}
  final Map<int, String> _statusMap = {}; // student_id -> present/absent/leave

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _loadingBatches = true);
    final res = await ApiService.get('admin/batches.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _batches = (res['batches'] as List).map((e) => Batch.fromJson(e)).toList();
        if (_batches.isNotEmpty) _batchId = _batches.first.id;
      }
      _loadingBatches = false;
    });
    if (_batchId != null) _loadStudents();
  }

  String get _dateStr => '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _loadStudents() async {
    if (_batchId == null) return;
    setState(() { _loadingStudents = true; _statusMap.clear(); });

    final results = await Future.wait([
      ApiService.get('admin/batch_detail.php', query: {'batch_id': _batchId.toString()}),
      ApiService.get('teacher/attendance.php', query: {'batch_id': _batchId.toString(), 'date': _dateStr}),
    ]);

    if (!mounted) return;

    final detailRes = results[0];
    final attRes = results[1];

    if (detailRes['success'] != true) {
      setState(() { _students = []; _loadingStudents = false; });
      if (mounted) showAppSnackBar(context, detailRes['message'] ?? 'Could not load students', isError: true);
      return;
    }

    final existing = <int, String>{};
    if (attRes['success'] == true) {
      for (final a in (attRes['attendance'] as List)) {
        existing[(a['student_id'] as num).toInt()] = a['status'];
      }
    }

    setState(() {
      _students = (detailRes['students'] as List).cast<Map<String, dynamic>>();
      for (final s in _students) {
        final id = (s['id'] as num).toInt();
        if (existing.containsKey(id)) _statusMap[id] = existing[id]!;
      }
      _loadingStudents = false;
    });
  }

  Future<void> _save() async {
    if (_batchId == null || _statusMap.isEmpty) {
      showAppSnackBar(context, 'Mark at least one student', isError: true);
      return;
    }
    setState(() => _saving = true);

    final records = _statusMap.entries.map((e) => {'student_id': e.key, 'status': e.value}).toList();
    final res = await ApiService.post('teacher/attendance.php', {
      'batch_id': _batchId,
      'attendance_date': _dateStr,
      'records': records,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      showAppSnackBar(context, res['message'] ?? 'Attendance saved');
    } else {
      showAppSnackBar(context, res['message'] ?? 'Failed to save', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: _loadingBatches
          ? const LoadingBox()
          : _batches.isEmpty
              ? const EmptyState(icon: Icons.people_outline, message: 'No batches assigned to you yet.')
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              initialValue: _batchId,
                              items: _batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) { setState(() => _batchId = v); _loadStudents(); },
                              decoration: const InputDecoration(labelText: 'Batch'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 60)), lastDate: DateTime.now());
                                if (picked != null) { setState(() => _date = picked); _loadStudents(); }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Date'),
                                child: Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _loadingStudents
                          ? const LoadingBox()
                          : _students.isEmpty
                              ? const EmptyState(icon: Icons.people_outline, message: 'No students enrolled in this batch.')
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: _students.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final s = _students[i];
                                    final id = (s['id'] as num).toInt();
                                    final current = _statusMap[id];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                                          _StatusChip(label: 'P', color: AppColors.emerald500, selected: current == 'present', onTap: () => setState(() => _statusMap[id] = 'present')),
                                          const SizedBox(width: 6),
                                          _StatusChip(label: 'A', color: AppColors.rose500, selected: current == 'absent', onTap: () => setState(() => _statusMap[id] = 'absent')),
                                          const SizedBox(width: 6),
                                          _StatusChip(label: 'L', color: AppColors.amber500, selected: current == 'leave', onTap: () => setState(() => _statusMap[id] = 'leave')),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_saving || _students.isEmpty) ? null : _save,
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                : const Text('Save attendance'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, required this.selected, required this.onTap});
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ),
    );
  }
}
