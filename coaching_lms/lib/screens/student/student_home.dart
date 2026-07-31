import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../models/live_class.dart';
import '../../models/attendance.dart';
import '../../widgets/common.dart';
import 'student_classes.dart';
import 'student_tests.dart';
import 'student_leave.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _loading = true;
  List<LiveClassItem> _liveClasses = [];
  AttendanceSummary? _attendanceSummary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('teacher/live_class.php'),
      ApiService.get('teacher/attendance.php'),
    ]);

    if (!mounted) return;

    final classesRes = results[0];
    final attRes = results[1];

    setState(() {
      if (classesRes['success'] == true) {
        _liveClasses = (classesRes['live_classes'] as List)
            .map((e) => LiveClassItem.fromJson(e))
            .where((c) => c.status != 'completed' && c.status != 'cancelled')
            .toList();
      }
      if (attRes['success'] == true && attRes['summary'] != null) {
        _attendanceSummary = AttendanceSummary.fromJson(attRes['summary']);
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
                        Text('Hi, ${user?.name.split(' ').first ?? 'there'} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink900)),
                        const SizedBox(height: 2),
                        const Text('Keep learning, keep growing!', style: TextStyle(fontSize: 13, color: AppColors.ink400)),
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

              if (!_loading && _liveClasses.isNotEmpty) _UpcomingClassCard(liveClass: _liveClasses.first),
              if (!_loading && _liveClasses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: const Row(
                    children: [
                      Icon(Icons.event_available_outlined, color: AppColors.ink400),
                      SizedBox(width: 10),
                      Expanded(child: Text('No upcoming live classes right now.', style: TextStyle(color: AppColors.ink400, fontSize: 13.5))),
                    ],
                  ),
                ),

              const SizedBox(height: 22),
              const Text('Quick access', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink900)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
                children: [
                  _QuickTile(icon: Icons.videocam_outlined, label: 'Live', color: AppColors.rose500, bg: AppColors.rose100,
                    onTap: () => _goToClasses(context, 0)),
                  _QuickTile(icon: Icons.play_circle_outline, label: 'Recorded', color: AppColors.amber500, bg: AppColors.amber100,
                    onTap: () => _goToClasses(context, 1)),
                  _QuickTile(icon: Icons.picture_as_pdf_outlined, label: 'Material', color: AppColors.sky500, bg: AppColors.sky100,
                    onTap: () => _goToClasses(context, 2)),
                  _QuickTile(icon: Icons.assignment_outlined, label: 'Tests', color: AppColors.indigo700, bg: AppColors.violet100,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentTestsScreen()))),
                  _QuickTile(icon: Icons.calendar_month_outlined, label: 'Attendance', color: AppColors.emerald500, bg: AppColors.emerald100,
                    onTap: () => _goToClasses(context, 0)),
                  _QuickTile(icon: Icons.event_busy_outlined, label: 'Leave', color: AppColors.rose500, bg: AppColors.rose100,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentLeaveScreen()))),
                ],
              ),

              const SizedBox(height: 22),
              const Text('Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink900)),
              const SizedBox(height: 12),
              if (_attendanceSummary != null)
                Row(
                  children: [
                    Expanded(child: _StatCard(value: '${_attendanceSummary!.percentage.toStringAsFixed(0)}%', label: 'Overall', color: AppColors.emerald500)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '${_attendanceSummary!.present}', label: 'Present days', color: AppColors.indigo700)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '${_attendanceSummary!.total}', label: 'Total marked', color: AppColors.sky500)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToClasses(BuildContext context, int tabIndex) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentClassesScreen(initialTab: tabIndex)));
  }
}

class _UpcomingClassCard extends StatelessWidget {
  const _UpcomingClassCard({required this.liveClass});
  final LiveClassItem liveClass;

  Future<void> _openMeet() async {
    final uri = Uri.tryParse(liveClass.meetLink);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isLive = liveClass.status == 'live';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.indigo600, AppColors.indigo900], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                child: Text(isLive ? 'LIVE NOW' : 'UPCOMING', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              ),
              if (isLive) ...[const SizedBox(width: 8), const LiveDot()],
            ],
          ),
          const SizedBox(height: 12),
          Text(liveClass.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${liveClass.subject} · By ${liveClass.teacherName}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('${fmtDate(liveClass.classDate)}, ${fmtTime(liveClass.startTime)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMeet,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Join Now'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.indigo900),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.color, required this.bg, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.ink400), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
