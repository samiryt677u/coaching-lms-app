import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/test.dart';
import '../../widgets/common.dart';

class StudentTestAttemptScreen extends StatefulWidget {
  const StudentTestAttemptScreen({super.key, required this.testId, required this.testTitle});
  final int testId;
  final String testTitle;

  @override
  State<StudentTestAttemptScreen> createState() => _StudentTestAttemptScreenState();
}

class _StudentTestAttemptScreenState extends State<StudentTestAttemptScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  int? _attemptId;
  List<TestQuestion> _questions = [];
  final Map<int, String> _answers = {}; // question_id -> a/b/c/d
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() { _loading = true; _errorMessage = null; });

    final res = await ApiService.post('student/test_start.php', {'test_id': widget.testId});

    if (!mounted) return;

    if (res['success'] != true) {
      setState(() { _loading = false; _errorMessage = res['message'] ?? 'Could not start test'; });
      return;
    }

    final questions = (res['questions'] as List).map((e) => TestQuestion.fromJson(e)).toList();
    final durationMinutes = res['test']['duration_minutes'] ?? 60;

    setState(() {
      _attemptId = res['attempt_id'];
      _questions = questions;
      _secondsLeft = durationMinutes * 60;
      _loading = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _submit(auto: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timeLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _submit({bool auto = false}) async {
    if (_attemptId == null || _submitting) return;

    if (!auto) {
      final unanswered = _questions.length - _answers.length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit test?'),
          content: Text(unanswered > 0
              ? 'You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}. Submit anyway?'
              : 'Are you sure you want to submit?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Submit')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _submitting = true);
    _timer?.cancel();

    final answersPayload = _answers.entries.map((e) => {'question_id': e.key, 'selected_option': e.value}).toList();

    final res = await ApiService.post('student/test_submit.php', {
      'attempt_id': _attemptId,
      'answers': answersPayload,
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Test submitted 🎉'),
          content: Text('Your score: ${res['score']} / ${res['total_marks']}'),
          actions: [
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      showAppSnackBar(context, res['message'] ?? 'Submission failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave test?'),
            content: const Text('Your answers so far are not saved until you submit. Leave anyway?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Stay')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Leave')),
            ],
          ),
        );
        return leave == true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.testTitle, overflow: TextOverflow.ellipsis),
          actions: [
            if (!_loading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _secondsLeft < 60 ? AppColors.rose100 : AppColors.violet100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(_timeLabel, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13,
                      color: _secondsLeft < 60 ? AppColors.rose500 : AppColors.indigo700,
                    )),
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const LoadingBox()
            : _errorMessage != null
                ? EmptyState(icon: Icons.error_outline, message: _errorMessage!)
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          itemBuilder: (context, i) => _QuestionCard(
                            index: i + 1,
                            question: _questions[i],
                            selected: _answers[_questions[i].id],
                            onSelect: (opt) => setState(() => _answers[_questions[i].id] = opt),
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : () => _submit(),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald500),
                              child: _submitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                  : Text('Submit (${_answers.length}/${_questions.length} answered)'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.index, required this.question, required this.selected, required this.onSelect});
  final int index;
  final TestQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = {'a': question.optionA, 'b': question.optionB, 'c': question.optionC, 'd': question.optionD};

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q$index.', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.indigo700)),
              const SizedBox(width: 6),
              Expanded(child: Text(question.questionText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5))),
              Text('${question.marks}m', style: const TextStyle(fontSize: 11.5, color: AppColors.ink400)),
            ],
          ),
          const SizedBox(height: 8),
          ...options.entries.map((e) => RadioListTile<String>(
                value: e.key,
                groupValue: selected,
                onChanged: (v) => onSelect(v!),
                title: Text(e.value, style: const TextStyle(fontSize: 13.5)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.indigo700,
              )),
        ],
      ),
    );
  }
}
