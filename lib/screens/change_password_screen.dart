import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _success = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _auth.changePassword(currentPassword: _current.text, newPassword: _newPass.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (error == null) {
        _success = true;
      } else {
        _error = error;
      }
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.sand,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text('Change password', style: AppText.display(size: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _success ? _buildSuccessState() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Text(
            'Enter your current password, then choose a new one.',
            style: AppText.body(size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          AuthTextField(
            label: 'Current password',
            controller: _current,
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'New password',
            controller: _newPass,
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            label: 'Confirm new password',
            controller: _confirm,
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (v) => (v != _newPass.text) ? 'Passwords do not match' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppText.body(size: 12.5, color: AppColors.rose)),
          ],
          const SizedBox(height: 22),
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
                  : Text('Update password', style: AppText.body(size: 15, weight: FontWeight.w600, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.sage.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 32, color: AppColors.sage),
          ),
          const SizedBox(height: 20),
          Text('Password updated', style: AppText.display(size: 20)),
          const SizedBox(height: 8),
          Text('Use your new password next time you sign in.', style: AppText.body(size: 13, color: AppColors.muted)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.plum,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 0,
              ),
              child: Text('Done', style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}