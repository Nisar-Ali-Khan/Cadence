import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _auth.signIn(_email.text, _password.text);
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
      return;
    }

    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.plum, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Welcome back', textAlign: TextAlign.center, style: AppText.display(size: 26)),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue tracking your cycle',
                    textAlign: TextAlign.center,
                    style: AppText.body(size: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    label: 'Email',
                    controller: _email,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    label: 'Password',
                    controller: _password,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: Text('Forgot password?', style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.plum)),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(_error!, style: AppText.body(size: 12.5, color: AppColors.rose)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.plum,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : Text('Sign in', style: AppText.body(size: 15, weight: FontWeight.w600, color: AppColors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: AppText.body(size: 13, color: AppColors.muted)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: Text('Sign up', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.plum)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}