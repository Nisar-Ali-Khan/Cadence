import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import 'onboarding_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _agreedToTerms = false;
  String? _error;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(() => _error = 'Please agree to the Terms and Privacy Policy to continue.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _auth.signUp(_name.text, _email.text, _password.text);
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }

    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(backgroundColor: AppColors.sand, elevation: 0, iconTheme: const IconThemeData(color: AppColors.ink)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create your account', style: AppText.display(size: 26)),
                  const SizedBox(height: 6),
                  Text('Start tracking your patterns, privately', style: AppText.body(size: 13, color: AppColors.muted)),
                  const SizedBox(height: 28),
                  AuthTextField(
                    label: 'Full name',
                    controller: _name,
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  AuthTextField(
                    label: 'Confirm password',
                    controller: _confirm,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) => (v != _password.text) ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                          activeColor: AppColors.plum,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: RichText(
                            text: TextSpan(
                              style: AppText.body(size: 12.5, color: AppColors.muted),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.plum),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.plum),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: AppText.body(size: 12.5, color: AppColors.rose)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.plum, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)), elevation: 0),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : Text('Create account', style: AppText.body(size: 15, weight: FontWeight.w600, color: AppColors.white)),
                    ),
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