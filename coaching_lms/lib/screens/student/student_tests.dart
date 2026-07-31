import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/test.dart';
import '../../widgets/common.dart';
import 'student_test_attempt.dart';
import 'student_test_result.dart';

class StudentTestsScreen extends StatefulWidget {
  const StudentTestsScreen({super.key});

  @override
  State<StudentTestsScreen> createState() => _StudentTestsScreenState();
}

class _StudentTestsScreenState extends State<StudentTestsScreen> {
  bool _loading = true;
  List<TestSummary> _tests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('student/test_list.php');
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _tests = (res['tests'] as List).map((e) => TestSummary.fromJson(e)).toList();
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tests')),
      body: _loading
          ? const LoadingBox()
          : _tests.isEmpty
              ? const EmptyState(icon: Icons.assignment_outlined, message: 'No tests available right now.')
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.violet500,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = _tests[i];
                      final submitted = t.attemptStatus == 'submitted';
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          if (submitted) {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentTestResultScreen(testId: t.id, testTitle: t.title)));
                          } else {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentTestAttemptScreen(testId: t.id, testTitle: t.title)));
                          }
                          _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                                  if (submitted) statusBadgeFor('completed') else statusBadgeFor('published'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${t.questionCount} questions · ${t.totalMarks} marks · ${t.durationMinutes} min'
                                '${t.negativeMarking > 0 ? ' · -${t.negativeMarking} negative' : ''}',
                                style: const TextStyle(fontSize: 12, color: AppColors.ink400),
                              ),
                              if (submitted && t.myScore != null) ...[
                                const SizedBox(height: 8),
                                Text('Your score: ${t.myScore!.toStringAsFixed(2)} / ${t.totalMarks}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emerald500)),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
