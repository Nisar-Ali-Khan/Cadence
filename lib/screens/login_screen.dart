import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'auth_gate.dart';
import 'home_shell.dart';

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
  bool _googleLoading = false;
  bool _obscure = true;
  bool _keepMeSignedIn = true;
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

  Future<void> _googleLogin() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    
    final error = await _auth.signInWithGoogle();
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
      return;
    }

    setState(() {
      _googleLoading = false;
      _error = error;
    });
  }

  Future<void> _guestLogin() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7EFE7),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.4,
            child: Container(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFEBD8),
              child: Center(
                child: Opacity(
                  opacity: 0.8,
                  child: Image.asset(
                    'assets/images/cadence.png',
                    width: 160,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.spa_rounded, size: 100, color: AppColors.plum.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome Back', style: AppText.display(context: context, size: 28, weight: FontWeight.w700)),
                          const SizedBox(height: 24),
                          
                          _buildRoundedField(
                            controller: _email,
                            hint: 'Email Address',
                            icon: Icons.mail_outline_rounded,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildRoundedField(
                            controller: _password,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscure: _obscure,
                            onToggleObscure: () => setState(() => _obscure = !_obscure),
                            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                          ),
                          
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _keepMeSignedIn,
                                      onChanged: (v) => setState(() => _keepMeSignedIn = v ?? true),
                                      activeColor: AppColors.amber,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Keep me signed in', style: AppText.body(context: context, size: 13, color: AppColors.muted)),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                ),
                                child: Text('Forgot Password?', style: AppText.body(context: context, size: 13, weight: FontWeight.w600, color: AppColors.amber)),
                              ),
                            ],
                          ),
                          
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(_error!, style: AppText.body(context: context, size: 12.5, color: AppColors.rose)),
                          ],
                          
                          const SizedBox(height: 28),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (_loading || _googleLoading) ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amber,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : Text('Log In', style: AppText.body(context: context, size: 16, weight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Colors.black12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Or Continue With', style: AppText.body(context: context, size: 12, color: AppColors.muted)),
                              ),
                              const Expanded(child: Divider(color: Colors.black12)),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Center(
                            child: SizedBox(
                              width: size.width * 0.6,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: (_loading || _googleLoading) ? null : _googleLogin,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.black12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: _googleLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.plum))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Image.network(
                                            'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => 
                                              const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 24),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('Google', style: AppText.body(context: context, size: 15, weight: FontWeight.w600)),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have any account? ", style: AppText.body(context: context, size: 14, color: AppColors.muted)),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                                child: Text('Sign Up', style: AppText.body(context: context, size: 14, weight: FontWeight.w700, color: AppColors.plum)),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Center(
                            child: TextButton.icon(
                              onPressed: (_loading || _googleLoading) ? null : _guestLogin,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: Text('Quick Track as Guest', style: AppText.body(context: context, size: 15, weight: FontWeight.w700, color: AppColors.amber)),
                              style: TextButton.styleFrom(iconColor: AppColors.amber),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: AppText.body(context: context, size: 15, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(context: context, size: 14, color: AppColors.muted),
        prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.muted),
          onPressed: onToggleObscure,
        ) : null,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFFBFBFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
        errorStyle: const TextStyle(height: 0.8),
      ),
    );
  }
}
