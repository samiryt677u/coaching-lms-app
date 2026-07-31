import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../models/batch.dart';
import '../../models/live_class.dart';
import '../../models/recorded_class.dart';
import '../../models/study_material.dart';
import '../../widgets/common.dart';
import 'package:provider/provider.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    final res = await ApiService.get('admin/batches.php');
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => _batches = (res['batches'] as List).map((e) => Batch.fromJson(e)).toList());
    }
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
        children: [
          _LiveManageTab(batches: _batches),
          _RecordedManageTab(batches: _batches),
          _MaterialManageTab(batches: _batches),
        ],
      ),
    );
  }
}

// ================= LIVE =================
class _LiveManageTab extends StatefulWidget {
  const _LiveManageTab({required this.batches});
  final List<Batch> batches;

  @override
  State<_LiveManageTab> createState() => _LiveManageTabState();
}

class _LiveManageTabState extends State<_LiveManageTab> {
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
      if (res['success'] == true) _items = (res['live_classes'] as List).map((e) => LiveClassItem.fromJson(e)).toList();
      _loading = false;
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    final res = await ApiService.put('teacher/live_class.php', {'id': id, 'status': status});
    if (!mounted) return;
    if (res['success'] == true) { showAppSnackBar(context, 'Status updated'); _load(); }
    else showAppSnackBar(context, res['message'] ?? 'Failed', isError: true);
  }

  void _openScheduleSheet() {
    if (widget.batches.isEmpty) { showAppSnackBar(context, 'No batches assigned to you yet.', isError: true); return; }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleClassSheet(batches: widget.batches, onDone: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScheduleSheet, backgroundColor: AppColors.indigo700,
        icon: const Icon(Icons.add), label: const Text('Schedule'),
      ),
      body: _loading
          ? const LoadingBox()
          : _items.isEmpty
              ? const EmptyState(icon: Icons.videocam_off_outlined, message: 'No live classes scheduled yet.')
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.violet500,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = _items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
                              statusBadgeFor(c.status),
                            ]),
                            const SizedBox(height: 3),
                            Text('${c.subject} · ${c.batchName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                            Text('${fmtDate(c.classDate)}, ${fmtTime(c.startTime)}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                            const SizedBox(height: 10),
                            Row(children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.tryParse(c.meetLink);
                                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('Meet', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                              ),
                              const SizedBox(width: 8),
                              if (c.status == 'scheduled')
                                TextButton(onPressed: () => _updateStatus(c.id, 'live'), child: const Text('Mark Live', style: TextStyle(fontSize: 12))),
                              if (c.status == 'live')
                                TextButton(onPressed: () => _updateStatus(c.id, 'completed'), child: const Text('Mark Done', style: TextStyle(fontSize: 12))),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ScheduleClassSheet extends StatefulWidget {
  const _ScheduleClassSheet({required this.batches, required this.onDone});
  final List<Batch> batches;
  final VoidCallback onDone;

  @override
  State<_ScheduleClassSheet> createState() => _ScheduleClassSheetState();
}

class _ScheduleClassSheetState extends State<_ScheduleClassSheet> {
  late int _batchId;
  final _subjectCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  int _duration = 60;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _batchId = widget.batches.first.id;
  }

  @override
  void dispose() {
    _subjectCtrl.dispose(); _titleCtrl.dispose(); _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _titleCtrl.text.trim().isEmpty || _linkCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please fill all fields', isError: true); return;
    }
    if (!_linkCtrl.text.contains('meet.google.com')) {
      showAppSnackBar(context, 'Enter a valid Google Meet link', isError: true); return;
    }

    setState(() => _submitting = true);
    final teacherId = context.read<AuthProvider>().user?.id;
    final dateStr = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00';

    final res = await ApiService.post('teacher/live_class.php', {
      'batch_id': _batchId,
      'teacher_id': teacherId,
      'subject': _subjectCtrl.text.trim(),
      'title': _titleCtrl.text.trim(),
      'meet_link': _linkCtrl.text.trim(),
      'class_date': dateStr,
      'start_time': timeStr,
      'duration_minutes': _duration,
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Navigator.of(context).pop();
      widget.onDone();
      if (mounted) showAppSnackBar(context, 'Class scheduled');
    } else {
      showAppSnackBar(context, res['message'] ?? 'Failed to schedule', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule live class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _label('Batch'),
            DropdownButtonFormField<int>(
              initialValue: _batchId,
              items: widget.batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
              onChanged: (v) => setState(() => _batchId = v!),
            ),
            const SizedBox(height: 12),
            _label('Subject'),
            TextField(controller: _subjectCtrl, decoration: const InputDecoration(hintText: 'e.g. Physics')),
            const SizedBox(height: 12),
            _label('Title'),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'e.g. Laws of Motion')),
            const SizedBox(height: 12),
            _label('Google Meet link'),
            TextField(controller: _linkCtrl, decoration: const InputDecoration(hintText: 'https://meet.google.com/xxx-xxxx-xxx')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Date'),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: InputDecorator(decoration: const InputDecoration(), child: Text('${_date.day}/${_date.month}/${_date.year}')),
                ),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Time'),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  child: InputDecorator(decoration: const InputDecoration(), child: Text(_time.format(context))),
                ),
              ])),
            ]),
            const SizedBox(height: 12),
            _label('Duration (minutes)'),
            TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _duration.toString()),
              onChanged: (v) => _duration = int.tryParse(v) ?? 60,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Schedule class'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
      );
}

// ================= RECORDED =================
class _RecordedManageTab extends StatefulWidget {
  const _RecordedManageTab({required this.batches});
  final List<Batch> batches;
  @override
  State<_RecordedManageTab> createState() => _RecordedManageTabState();
}

class _RecordedManageTabState extends State<_RecordedManageTab> {
  bool _loading = true;
  List<RecordedClassItem> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('teacher/recorded_class.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) _items = (res['recorded_classes'] as List).map((e) => RecordedClassItem.fromJson(e)).toList();
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    final res = await ApiService.delete('teacher/recorded_class.php', {'id': id});
    if (!mounted) return;
    if (res['success'] == true) { showAppSnackBar(context, 'Deleted'); _load(); }
    else showAppSnackBar(context, res['message'] ?? 'Failed', isError: true);
  }

  void _openAddSheet() {
    if (widget.batches.isEmpty) { showAppSnackBar(context, 'No batches assigned to you yet.', isError: true); return; }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddRecordedSheet(batches: widget.batches, onDone: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet, backgroundColor: AppColors.indigo700,
        icon: const Icon(Icons.add), label: const Text('Add'),
      ),
      body: _loading
          ? const LoadingBox()
          : _items.isEmpty
              ? const EmptyState(icon: Icons.play_circle_outline, message: 'No recorded classes yet.')
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.violet500,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = _items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${r.subject} · ${r.batchName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                            ],
                          )),
                          IconButton(onPressed: () => _delete(r.id), icon: const Icon(Icons.delete_outline, color: AppColors.rose500, size: 20)),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AddRecordedSheet extends StatefulWidget {
  const _AddRecordedSheet({required this.batches, required this.onDone});
  final List<Batch> batches;
  final VoidCallback onDone;
  @override
  State<_AddRecordedSheet> createState() => _AddRecordedSheetState();
}

class _AddRecordedSheetState extends State<_AddRecordedSheet> {
  late int _batchId;
  final _subjectCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() { super.initState(); _batchId = widget.batches.first.id; }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _titleCtrl.text.trim().isEmpty || _urlCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please fill all required fields', isError: true); return;
    }
    setState(() => _submitting = true);
    final teacherId = context.read<AuthProvider>().user?.id;
    final res = await ApiService.post('teacher/recorded_class.php', {
      'batch_id': _batchId, 'teacher_id': teacherId,
      'subject': _subjectCtrl.text.trim(), 'chapter': _chapterCtrl.text.trim(),
      'title': _titleCtrl.text.trim(), 'video_url': _urlCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      Navigator.of(context).pop(); widget.onDone();
      if (mounted) showAppSnackBar(context, 'Recorded class added');
    } else {
      showAppSnackBar(context, res['message'] ?? 'Failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add recorded class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _batchId,
              items: widget.batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
              onChanged: (v) => setState(() => _batchId = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: 12),
            TextField(controller: _chapterCtrl, decoration: const InputDecoration(labelText: 'Chapter (optional)')),
            const SizedBox(height: 12),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Video URL (YouTube unlisted link)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= STUDY MATERIAL =================
class _MaterialManageTab extends StatefulWidget {
  const _MaterialManageTab({required this.batches});
  final List<Batch> batches;
  @override
  State<_MaterialManageTab> createState() => _MaterialManageTabState();
}

class _MaterialManageTabState extends State<_MaterialManageTab> {
  bool _loading = true;
  List<StudyMaterialItem> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('teacher/study_material.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) _items = (res['materials'] as List).map((e) => StudyMaterialItem.fromJson(e)).toList();
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    final res = await ApiService.delete('teacher/study_material.php', {'id': id});
    if (!mounted) return;
    if (res['success'] == true) { showAppSnackBar(context, 'Deleted'); _load(); }
    else showAppSnackBar(context, res['message'] ?? 'Failed', isError: true);
  }

  void _openUploadSheet() {
    if (widget.batches.isEmpty) { showAppSnackBar(context, 'No batches assigned to you yet.', isError: true); return; }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _UploadMaterialSheet(batches: widget.batches, onDone: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadSheet, backgroundColor: AppColors.indigo700,
        icon: const Icon(Icons.upload_file), label: const Text('Upload'),
      ),
      body: _loading
          ? const LoadingBox()
          : _items.isEmpty
              ? const EmptyState(icon: Icons.picture_as_pdf_outlined, message: 'No study material uploaded yet.')
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.violet500,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = _items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${m.subject} · ${m.batchName}', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                            ],
                          )),
                          IconButton(onPressed: () => _delete(m.id), icon: const Icon(Icons.delete_outline, color: AppColors.rose500, size: 20)),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}

class _UploadMaterialSheet extends StatefulWidget {
  const _UploadMaterialSheet({required this.batches, required this.onDone});
  final List<Batch> batches;
  final VoidCallback onDone;
  @override
  State<_UploadMaterialSheet> createState() => _UploadMaterialSheetState();
}

class _UploadMaterialSheetState extends State<_UploadMaterialSheet> {
  late int _batchId;
  final _subjectCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  bool _submitting = false;

  @override
  void initState() { super.initState(); _batchId = widget.batches.first.id; }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'mp4'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _titleCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please fill subject and title', isError: true); return;
    }
    if (_pickedFile == null || _pickedFile!.path == null) {
      showAppSnackBar(context, 'Please choose a file', isError: true); return;
    }

    setState(() => _submitting = true);
    final res = await ApiService.upload(
      'teacher/study_material.php',
      fields: {
        'batch_id': _batchId.toString(),
        'subject': _subjectCtrl.text.trim(),
        'chapter': _chapterCtrl.text.trim(),
        'title': _titleCtrl.text.trim(),
      },
      filePath: _pickedFile!.path!,
      fileFieldName: 'file',
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(); widget.onDone();
      if (mounted) showAppSnackBar(context, 'Material uploaded');
    } else {
      showAppSnackBar(context, res['message'] ?? 'Upload failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload study material', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _batchId,
              items: widget.batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
              onChanged: (v) => setState(() => _batchId = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: 12),
            TextField(controller: _chapterCtrl, decoration: const InputDecoration(labelText: 'Chapter (optional)')),
            const SizedBox(height: 12),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.attach_file, color: AppColors.indigo700),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_pickedFile?.name ?? 'Choose file (PDF, DOC, image, MP4)', style: const TextStyle(fontSize: 13.5))),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
