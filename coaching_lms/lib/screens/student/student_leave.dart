import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/batch.dart';
import '../../models/attendance.dart';
import '../../widgets/common.dart';

class StudentLeaveScreen extends StatefulWidget {
  const StudentLeaveScreen({super.key});

  @override
  State<StudentLeaveScreen> createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends State<StudentLeaveScreen> {
  bool _loading = true;
  List<LeaveRequestItem> _leaves = [];
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('student/leave.php'),
      ApiService.get('admin/batches.php'),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0]['success'] == true) {
        _leaves = (results[0]['leaves'] as List).map((e) => LeaveRequestItem.fromJson(e)).toList();
      }
      if (results[1]['success'] == true) {
        _batches = (results[1]['batches'] as List).map((e) => Batch.fromJson(e)).toList();
      }
      _loading = false;
    });
  }

  void _openApplyForm() {
    if (_batches.isEmpty) {
      showAppSnackBar(context, 'You are not enrolled in any batch yet.', isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplyLeaveSheet(batches: _batches, onSubmitted: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApplyForm,
        backgroundColor: AppColors.indigo700,
        icon: const Icon(Icons.add),
        label: const Text('Apply'),
      ),
      body: _loading
          ? const LoadingBox()
          : _leaves.isEmpty
              ? const EmptyState(icon: Icons.event_busy_outlined, message: 'No leave requests yet. Tap Apply to request one.')
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.violet500,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _leaves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = _leaves[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(fmtDate(l.leaveDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                                statusBadgeFor(l.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(l.batchName, style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                            const SizedBox(height: 6),
                            Text(l.reason, style: const TextStyle(fontSize: 13, color: AppColors.ink600)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ApplyLeaveSheet extends StatefulWidget {
  const _ApplyLeaveSheet({required this.batches, required this.onSubmitted});
  final List<Batch> batches;
  final VoidCallback onSubmitted;

  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  late int _batchId;
  DateTime _date = DateTime.now();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _batchId = widget.batches.first.id;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter a reason', isError: true);
      return;
    }
    setState(() => _submitting = true);
    final res = await ApiService.post('student/leave.php', {
      'batch_id': _batchId,
      'leave_date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      'reason': _reasonCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Navigator.of(context).pop();
      widget.onSubmitted();
      if (mounted) showAppSnackBar(context, 'Leave request submitted');
    } else {
      showAppSnackBar(context, res['message'] ?? 'Failed to submit', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apply for leave', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          const Text('Batch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _batchId,
            items: widget.batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
            onChanged: (v) => setState(() => _batchId = v!),
          ),
          const SizedBox(height: 14),

          const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Text('${_date.day}/${_date.month}/${_date.year}'),
            ),
          ),
          const SizedBox(height: 14),

          const Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'e.g. Fever, unable to attend'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Submit request'),
            ),
          ),
        ],
      ),
    );
  }
}
