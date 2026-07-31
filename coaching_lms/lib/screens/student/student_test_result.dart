import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../models/test.dart';
import '../../widgets/common.dart';
import 'package:provider/provider.dart';

class StudentTestResultScreen extends StatefulWidget {
  const StudentTestResultScreen({super.key, required this.testId, required this.testTitle});
  final int testId;
  final String testTitle;

  @override
  State<StudentTestResultScreen> createState() => _StudentTestResultScreenState();
}

class _StudentTestResultScreenState extends State<StudentTestResultScreen> {
  bool _loading = true;
  List<LeaderboardEntry> _leaderboard = [];
  int? _myRank;
  double? _myScore;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _errorMessage = null; });
    final res = await ApiService.get('student/test_result.php', query: {'test_id': widget.testId.toString()});
    if (!mounted) return;

    if (res['success'] != true) {
      setState(() { _loading = false; _errorMessage = res['message'] ?? 'Could not load results'; });
      return;
    }

    setState(() {
      _leaderboard = (res['leaderboard'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
      _myRank = res['my_rank'] != null ? (res['my_rank'] as num).toInt() : null;
      _myScore = res['my_score'] != null ? (res['my_score'] as num).toDouble() : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id;
    const medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Scaffold(
      appBar: AppBar(title: Text(widget.testTitle, overflow: TextOverflow.ellipsis)),
      body: _loading
          ? const LoadingBox()
          : _errorMessage != null
              ? EmptyState(icon: Icons.error_outline, message: _errorMessage!)
              : Column(
                  children: [
                    if (_myRank != null && _myScore != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.indigo600, AppColors.indigo900]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(children: [
                              Text('#$_myRank', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                              const Text('Your rank', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            ]),
                            Container(width: 1, height: 34, color: Colors.white24),
                            Column(children: [
                              Text(_myScore!.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                              const Text('Your score', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            ]),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _leaderboard.isEmpty
                          ? const EmptyState(icon: Icons.emoji_events_outlined, message: 'No submissions yet.')
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _leaderboard.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final e = _leaderboard[i];
                                final isMe = e.studentId == myId;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.violet100 : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isMe ? AppColors.violet500 : AppColors.border, width: isMe ? 1.4 : 1),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 34, child: Text(medals[e.rank] ?? '#${e.rank}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                      Expanded(child: Text(e.studentName, style: TextStyle(fontWeight: isMe ? FontWeight.w700 : FontWeight.w500, fontSize: 13.8))),
                                      Text(e.score.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.indigo700)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
