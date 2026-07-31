import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/common.dart';

class TeacherLeavesScreen extends StatefulWidget {
  const TeacherLeavesScreen({super.key});

  @override
  State<TeacherLeavesScreen> createState() => _TeacherLeavesScreenState();
}

class _TeacherLeavesScreenState extends State<TeacherLeavesScreen> {
  bool _loading = true;
  List<dynamic> _leaves = []; // raw maps (includes student_name from API)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('student/leave.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) _leaves = res['leaves'] as List;
      _loading = false;
    });
  }

  Future<void> _review(int id, String action) async {
    final res = await ApiService.put('student/leave.php', {'id': id, 'action': action});
    if (!mounted) return;
    if (res['success'] == true) { showAppSnackBar(context, res['message'] ?? 'Updated'); _load(); }
    else showAppSnackBar(context, res['message'] ?? 'Failed', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: _loading
          ? const LoadingBox()
          : _leaves.isEmpty
              ? const EmptyState(icon: Icons.event_busy_outlined, message: 'No leave requests from your students.')
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.violet500,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = _leaves[i] as Map<String, dynamic>;
                      final status = l['status']?.toString() ?? 'pending';
                      final id = (l['id'] as num).toInt();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(l['student_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                              statusBadgeFor(status),
                            ]),
                            const SizedBox(height: 3),
                            Text('${l['batch_name'] ?? ''} · ${fmtDate(l['leave_date']?.toString())}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                            const SizedBox(height: 6),
                            Text(l['reason']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: AppColors.ink600)),
                            if (status == 'pending') ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                ElevatedButton(onPressed: () => _review(id, 'approve'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), backgroundColor: AppColors.emerald500), child: const Text('Approve', style: TextStyle(fontSize: 12))),
                                const SizedBox(width: 8),
                                OutlinedButton(onPressed: () => _review(id, 'reject'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), side: const BorderSide(color: AppColors.rose500), foregroundColor: AppColors.rose500), child: const Text('Reject', style: TextStyle(fontSize: 12))),
                              ]),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
