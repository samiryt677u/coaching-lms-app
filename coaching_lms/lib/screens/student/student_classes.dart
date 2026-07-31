import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/live_class.dart';
import '../../models/recorded_class.dart';
import '../../models/study_material.dart';
import '../../widgets/common.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.indigo700,
          unselectedLabelColor: AppColors.ink400,
          indicatorColor: AppColors.violet500,
          tabs: const [Tab(text: 'Live'), Tab(text: 'Recorded'), Tab(text: 'Material')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_LiveTab(), _RecordedTab(), _MaterialTab()],
      ),
    );
  }
}

// ---------------- Live ----------------
class _LiveTab extends StatefulWidget {
  const _LiveTab();
  @override
  State<_LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<_LiveTab> {
  bool _loading = true;
  List<LiveClassItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('teacher/live_class.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _items = (res['live_classes'] as List).map((e) => LiveClassItem.fromJson(e)).toList();
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_items.isEmpty) return const EmptyState(icon: Icons.videocam_off_outlined, message: 'No live classes scheduled yet.');

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.violet500,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = _items[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (c.status == 'live') const Padding(padding: EdgeInsets.only(right: 6), child: LiveDot()),
                        Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
                      ]),
                      const SizedBox(height: 3),
                      Text('${c.subject} · ${c.batchName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                      const SizedBox(height: 3),
                      Text('${fmtDate(c.classDate)}, ${fmtTime(c.startTime)} · By ${c.teacherName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (c.status != 'completed' && c.status != 'cancelled')
                  ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.tryParse(c.meetLink);
                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    child: const Text('Join', style: TextStyle(fontSize: 12.5)),
                  )
                else
                  statusBadgeFor(c.status),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Recorded ----------------
class _RecordedTab extends StatefulWidget {
  const _RecordedTab();
  @override
  State<_RecordedTab> createState() => _RecordedTabState();
}

class _RecordedTabState extends State<_RecordedTab> {
  bool _loading = true;
  List<RecordedClassItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('teacher/recorded_class.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _items = (res['recorded_classes'] as List).map((e) => RecordedClassItem.fromJson(e)).toList();
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_items.isEmpty) return const EmptyState(icon: Icons.play_circle_outline, message: 'No recorded classes yet.');

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.violet500,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final r = _items[i];
          return InkWell(
            onTap: () async {
              final uri = Uri.tryParse(r.videoUrl);
              if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.amber100, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.amber500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text('${r.subject}${r.chapter != null ? ' · ${r.chapter}' : ''} · ${r.batchName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.ink400),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Material ----------------
class _MaterialTab extends StatefulWidget {
  const _MaterialTab();
  @override
  State<_MaterialTab> createState() => _MaterialTabState();
}

class _MaterialTabState extends State<_MaterialTab> {
  bool _loading = true;
  List<StudyMaterialItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('teacher/study_material.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _items = (res['materials'] as List).map((e) => StudyMaterialItem.fromJson(e)).toList();
      }
      _loading = false;
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'doc': return Icons.description_outlined;
      case 'image': return Icons.image_outlined;
      case 'video': return Icons.movie_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_items.isEmpty) return const EmptyState(icon: Icons.picture_as_pdf_outlined, message: 'No study material uploaded yet.');

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.violet500,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = _items[i];
          final fileUrl = '${ApiConfig.baseUrl.replaceFirst('/api', '')}/${m.filePath}';
          return InkWell(
            onTap: () async {
              final uri = Uri.tryParse(fileUrl);
              if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.sky100, borderRadius: BorderRadius.circular(12)),
                    child: Icon(_iconFor(m.fileType), color: AppColors.sky500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text('${m.subject}${m.chapter != null ? ' · ${m.chapter}' : ''} · ${m.batchName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                      ],
                    ),
                  ),
                  const Icon(Icons.download_outlined, color: AppColors.ink400, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
