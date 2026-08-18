import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _auth.resetPassword(_email.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (error == null) {
        _sent = true;
      } else {
        _error = error;
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _sent ? _buildSentState(context) : _buildFormState(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.sageLight : AppColors.plum, width: 2)),
            child: Icon(Icons.lock_reset, size: 28, color: isDark ? AppColors.sageLight : AppColors.plum),
          ),
          const SizedBox(height: 20),
          Text('Reset your password', textAlign: TextAlign.center, style: AppText.display(context: context, size: 24)),
          const SizedBox(height: 8),
          Text(
            'Enter the email linked to your account and we\'ll send you a link to reset your password.',
            textAlign: TextAlign.center,
            style: AppText.body(context: context, size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          AuthTextField(
            label: 'Email',
            controller: _email,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: AppText.body(context: context, size: 12.5, color: AppColors.rose)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.plum,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : Text('Send reset link', style: AppText.body(context: context, size: 15, weight: FontWeight.w600, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.sage.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 32, color: AppColors.sage),
        ),
        const SizedBox(height: 22),
        Text('Check your email', textAlign: TextAlign.center, style: AppText.display(context: context, size: 22)),
        const SizedBox(height: 10),
        Text(
          'If an account exists for ${_email.text.trim()}, a password reset link is on its way. It may take a minute to arrive — check spam too.',
          textAlign: TextAlign.center,
          style: AppText.body(context: context, size: 13.5, color: AppColors.muted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? AppColors.sageLight : AppColors.plum),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            child: Text('Back to sign in', style: AppText.body(context: context, size: 14, weight: FontWeight.w600, color: isDark ? AppColors.sageLight : AppColors.plum)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _sent = false),
          child: Text("Didn't get it? Try again", style: AppText.body(context: context, size: 13, color: AppColors.muted)),
        ),
      ],
    );
  }
}