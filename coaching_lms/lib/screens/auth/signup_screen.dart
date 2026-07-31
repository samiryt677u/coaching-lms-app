import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../widgets/common.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'student';
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final res = await auth.signup(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] != true) {
      showAppSnackBar(context, res['message'] ?? 'Signup failed', isError: true);
      return;
    }

    // Teacher signups need admin approval — no token comes back, so route to login with a message.
    if (res['status'] == 'pending') {
      showAppSnackBar(context, res['message'] ?? 'Your account is pending admin approval.');
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    if (_role == 'teacher') {
      Navigator.of(context).pushNamedAndRemoveUntil('/teacher/home', (route) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/student/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('I am a…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _RoleCard(
                      label: 'Student', icon: Icons.school_outlined,
                      selected: _role == 'student',
                      onTap: () => setState(() => _role = 'student'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _RoleCard(
                      label: 'Teacher', icon: Icons.person_outline,
                      selected: _role == 'teacher',
                      onTap: () => setState(() => _role = 'teacher'),
                    )),
                  ],
                ),
                if (_role == 'teacher') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Teacher accounts need admin approval before you can log in.',
                    style: TextStyle(fontSize: 12, color: AppColors.amber500, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 20),

                const Text('Full name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Your full name'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),

                const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),

                const Text('Phone number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '10-digit mobile number'),
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 14),

                const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.violet100 : AppColors.surface,
          border: Border.all(color: selected ? AppColors.violet500 : AppColors.border, width: selected ? 1.6 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.indigo700 : AppColors.ink400),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: selected ? AppColors.indigo700 : AppColors.ink600,
            )),
          ],
        ),
      ),
    );
  }
}
