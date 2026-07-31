import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    final auth = context.read<AuthProvider>();
    await auth.restoreSession();
    if (!mounted) return;

    if (!auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    final role = auth.user!.role;
    if (role == 'teacher') {
      Navigator.of(context).pushReplacementNamed('/teacher/home');
    } else {
      // students (and any admin accounts opening the app) land on the student home;
      // admins are expected to use the web admin panel as their primary tool.
      Navigator.of(context).pushReplacementNamed('/student/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.4,
            colors: [AppColors.indigo600, AppColors.indigo900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: const Text('C', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.indigo900)),
              ),
              const SizedBox(height: 18),
              const Text('Coaching LMS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
