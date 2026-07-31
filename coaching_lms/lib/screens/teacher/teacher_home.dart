import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../models/live_class.dart';
import '../../models/batch.dart';
import '../../widgets/common.dart';
import 'teacher_classes.dart';
import 'teacher_attendance.dart';
import 'teacher_tests.dart';
import 'teacher_leaves.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  bool _loading = true;
  List<LiveClassItem> _todayClasses = [];
  List<Batch> _batches = [];
  int _pendingLeaves = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('teacher/live_class.php'),
      ApiService.get('admin/batches.php'),
      ApiService.get('student/leave.php'),
    ]);
    if (!mounted) return;

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    setState(() {
      if (results[0]['success'] == true) {
        _todayClasses = (results[0]['live_classes'] as List)
            .map((e) => LiveClassItem.fromJson(e))
            .where((c) => c.classDate == todayStr && c.status != 'cancelled')
            .toList();
      }
      if (results[1]['success'] == true) {
        _batches = (results[1]['batches'] as List).map((e) => Batch.fromJson(e)).toList();
      }
      if (results[2]['success'] == true) {
        _pendingLeaves = (results[2]['leaves'] as List).where((l) => l['status'] == 'pending').length;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.violet500,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${user?.name.split(' ').first ?? 'there'} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${_batches.length} batch${_batches.length == 1 ? '' : 'es'} assigned to you', style: const TextStyle(fontSize: 13, color: AppColors.ink400)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.violet500,
                    child: Text(user?.initials ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_loading) const LoadingBox(),

              if (!_loading) ...[
                const Text("Today's classes", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (_todayClasses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: const Row(children: [
                      Icon(Icons.event_available_outlined, color: AppColors.ink400),
                      SizedBox(width: 10),
                      Expanded(child: Text('No classes scheduled today.', style: TextStyle(color: AppColors.ink400, fontSize: 13.5))),
                    ]),
                  )
                else
                  ..._todayClasses.map((c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: [
                            if (c.status == 'live') const Padding(padding: EdgeInsets.only(right: 8), child: LiveDot()),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.8)),
                                  Text('${fmtTime(c.startTime)} · ${c.batchName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final uri = Uri.tryParse(c.meetLink);
                                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              child: const Text('Start', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )),

                const SizedBox(height: 22),
                const Text('Quick actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                  children: [
                    _QuickTile(icon: Icons.videocam_outlined, label: 'Schedule', color: AppColors.rose500, bg: AppColors.rose100,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherClassesScreen(initialTab: 0)))),
                    _QuickTile(icon: Icons.how_to_reg_outlined, label: 'Attendance', color: AppColors.emerald500, bg: AppColors.emerald100,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherAttendanceScreen()))),
                    _QuickTile(icon: Icons.assignment_outlined, label: 'Create test', color: AppColors.indigo700, bg: AppColors.violet100,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherTestsScreen()))),
                    _QuickTile(icon: Icons.event_busy_outlined, label: 'Leaves', color: AppColors.amber500, bg: AppColors.amber100,
                      badge: _pendingLeaves > 0 ? _pendingLeaves : null,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherLeavesScreen()))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.color, required this.bg, required this.onTap, this.badge});
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              if (badge != null)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.rose500, borderRadius: BorderRadius.circular(999)),
                    child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
