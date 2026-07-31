import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/batch.dart';
import '../../models/test.dart';
import '../../widgets/common.dart';
import '../student/student_test_result.dart';

class TeacherTestsScreen extends StatefulWidget {
  const TeacherTestsScreen({super.key});

  @override
  State<TeacherTestsScreen> createState() => _TeacherTestsScreenState();
}

class _TeacherTestsScreenState extends State<TeacherTestsScreen> {
  bool _loading = true;
  List<TestSummary> _tests = [];
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('student/test_list.php'),
      ApiService.get('admin/batches.php'),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0]['success'] == true) {
        _tests = (results[0]['tests'] as List).map((e) => TestSummary.fromJson(e)).toList();
      }
      if (results[1]['success'] == true) {
        _batches = (results[1]['batches'] as List).map((e) => Batch.fromJson(e)).toList();
      }
      _loading = false;
    });
  }

  Future<void> _setStatus(int id, String status) async {
    final res = await ApiService.put('teacher/test_create.php', {'id': id, 'status': status});
    if (!mounted) return;
    if (res['success'] == true) { showAppSnackBar(context, 'Test $status'); _load(); }
    else showAppSnackBar(context, res['message'] ?? 'Failed', isError: true);
  }

  void _openCreateSheet() {
    if (_batches.isEmpty) { showAppSnackBar(context, 'No batches assigned to you yet.', isError: true); return; }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateTestScreen(batches: _batches))).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet, backgroundColor: AppColors.indigo700,
        icon: const Icon(Icons.add), label: const Text('Create'),
      ),
      body: _loading
          ? const LoadingBox()
          : _tests.isEmpty
              ? const EmptyState(icon: Icons.assignment_outlined, message: 'No tests created yet.')
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.violet500,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _tests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = _tests[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
                              statusBadgeFor(t.status),
                            ]),
                            const SizedBox(height: 4),
                            Text('${t.questionCount} questions · ${t.totalMarks} marks', style: const TextStyle(fontSize: 12, color: AppColors.ink400)),
                            const SizedBox(height: 10),
                            Row(children: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentTestResultScreen(testId: t.id, testTitle: t.title))),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                child: const Text('Results', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              if (t.status == 'draft')
                                TextButton(onPressed: () => _setStatus(t.id, 'published'), child: const Text('Publish', style: TextStyle(fontSize: 12))),
                              if (t.status == 'published')
                                TextButton(onPressed: () => _setStatus(t.id, 'closed'), child: const Text('Close', style: TextStyle(fontSize: 12))),
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

// ================= Create Test =================
class _QuestionDraft {
  final textCtrl = TextEditingController();
  final aCtrl = TextEditingController();
  final bCtrl = TextEditingController();
  final cCtrl = TextEditingController();
  final dCtrl = TextEditingController();
  final marksCtrl = TextEditingController(text: '1');
  String? correct;

  void dispose() {
    textCtrl.dispose(); aCtrl.dispose(); bCtrl.dispose(); cCtrl.dispose(); dCtrl.dispose(); marksCtrl.dispose();
  }
}

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key, required this.batches});
  final List<Batch> batches;

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  late int _batchId;
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _negativeCtrl = TextEditingController(text: '0');
  final List<_QuestionDraft> _questions = [_QuestionDraft()];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _batchId = widget.batches.first.id;
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _subjectCtrl.dispose(); _durationCtrl.dispose(); _negativeCtrl.dispose();
    for (final q in _questions) { q.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) { showAppSnackBar(context, 'Enter a test title', isError: true); return; }

    final questionsPayload = <Map<String, dynamic>>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.textCtrl.text.trim().isEmpty || q.aCtrl.text.trim().isEmpty || q.bCtrl.text.trim().isEmpty ||
          q.cCtrl.text.trim().isEmpty || q.dCtrl.text.trim().isEmpty || q.correct == null) {
        showAppSnackBar(context, 'Complete question ${i + 1} — all fields and correct option are required', isError: true);
        return;
      }
      questionsPayload.add({
        'question_text': q.textCtrl.text.trim(),
        'option_a': q.aCtrl.text.trim(), 'option_b': q.bCtrl.text.trim(),
        'option_c': q.cCtrl.text.trim(), 'option_d': q.dCtrl.text.trim(),
        'correct_option': q.correct,
        'marks': int.tryParse(q.marksCtrl.text) ?? 1,
      });
    }

    setState(() => _submitting = true);
    final res = await ApiService.post('teacher/test_create.php', {
      'batch_id': _batchId,
      'title': _titleCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'duration_minutes': int.tryParse(_durationCtrl.text) ?? 60,
      'negative_marking': double.tryParse(_negativeCtrl.text) ?? 0,
      'questions': questionsPayload,
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      showAppSnackBar(context, res['message'] ?? 'Test created');
      Navigator.of(context).pop();
    } else {
      showAppSnackBar(context, res['message'] ?? 'Failed to create test', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create test')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _batchId,
            items: widget.batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
            onChanged: (v) => setState(() => _batchId = v!),
            decoration: const InputDecoration(labelText: 'Batch'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Test title')),
          const SizedBox(height: 12),
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject (optional)')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (min)'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _negativeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Negative marking'))),
          ]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Questions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => setState(() => _questions.add(_QuestionDraft())),
                icon: const Icon(Icons.add, size: 18), label: const Text('Add question'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_questions.length, (i) => _QuestionForm(
                index: i,
                draft: _questions[i],
                onRemove: _questions.length > 1 ? () => setState(() { _questions[i].dispose(); _questions.removeAt(i); }) : null,
              )),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Create test'),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionForm extends StatefulWidget {
  const _QuestionForm({required this.index, required this.draft, required this.onRemove});
  final int index;
  final _QuestionDraft draft;
  final VoidCallback? onRemove;

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              if (widget.onRemove != null)
                IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.close, size: 18, color: AppColors.rose500), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: d.textCtrl, decoration: const InputDecoration(hintText: 'Question text'), maxLines: 2),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: d.aCtrl, decoration: const InputDecoration(hintText: 'Option A'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: d.bCtrl, decoration: const InputDecoration(hintText: 'Option B'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: d.cCtrl, decoration: const InputDecoration(hintText: 'Option C'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: d.dCtrl, decoration: const InputDecoration(hintText: 'Option D'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: d.correct,
                items: const [
                  DropdownMenuItem(value: 'a', child: Text('Correct: A')),
                  DropdownMenuItem(value: 'b', child: Text('Correct: B')),
                  DropdownMenuItem(value: 'c', child: Text('Correct: C')),
                  DropdownMenuItem(value: 'd', child: Text('Correct: D')),
                ],
                onChanged: (v) => setState(() => d.correct = v),
                decoration: const InputDecoration(isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: TextField(controller: d.marksCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Marks', isDense: true)),
            ),
          ]),
        ],
      ),
    );
  }
}
