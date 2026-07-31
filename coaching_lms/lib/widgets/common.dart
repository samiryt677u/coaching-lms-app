import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Signature "live" indicator — pulsing dot, used wherever something is happening right now.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.size = 8});
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 3,
      height: widget.size * 3,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0) * 0.6,
                child: Container(
                  width: widget.size + (widget.size * 2.4 * t),
                  height: widget.size + (widget.size * 2.4 * t),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.rose500),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.rose500),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11.5),
      ),
    );
  }
}

/// Maps common status strings across the app to a consistent color pair.
StatusBadge statusBadgeFor(String status) {
  final map = <String, List<Color>>{
    'scheduled': [AppColors.sky500, AppColors.sky100],
    'live': [AppColors.rose500, AppColors.rose100],
    'completed': [AppColors.emerald500, AppColors.emerald100],
    'cancelled': [AppColors.ink400, AppColors.border],
    'draft': [AppColors.ink400, AppColors.border],
    'published': [AppColors.emerald500, AppColors.emerald100],
    'closed': [AppColors.rose500, AppColors.rose100],
    'pending': [AppColors.amber500, AppColors.amber100],
    'approved': [AppColors.emerald500, AppColors.emerald100],
    'rejected': [AppColors.rose500, AppColors.rose100],
    'present': [AppColors.emerald500, AppColors.emerald100],
    'absent': [AppColors.rose500, AppColors.rose100],
    'leave': [AppColors.amber500, AppColors.amber100],
    'paid': [AppColors.emerald500, AppColors.emerald100],
  };
  final pair = map[status] ?? [AppColors.ink400, AppColors.border];
  return StatusBadge(status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '), color: pair[0], bg: pair[1]);
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.ink400.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.ink400, fontSize: 13.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator(color: AppColors.violet500)),
    );
  }
}

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.rose500 : AppColors.emerald500,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
    ),
  );
}

String fmtDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '—';
  try {
    final d = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  } catch (_) {
    return dateStr;
  }
}

String fmtTime(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return '—';
  final parts = timeStr.split(':');
  if (parts.length < 2) return timeStr;
  int hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final period = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '$hour:$minute $period';
}
