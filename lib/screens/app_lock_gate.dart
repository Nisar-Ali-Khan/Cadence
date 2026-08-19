import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'home_shell.dart';

/// Sits between successful Firebase sign-in and the actual app content.
/// If the user has enabled App Lock in Profile, this requires a successful
/// biometric check before HomeShell is shown.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();
  bool _checking = true;
  bool _lockEnabled = false;
  bool _unlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock whenever the app comes back from the background, if lock is on.
    if (state == AppLifecycleState.resumed && _lockEnabled && !_checking) {
      setState(() => _unlocked = false);
      _authenticate();
    }
  }

  Future<void> _init() async {
    final uid = AuthService().currentUser?.uid ?? 'guest';
    final enabled = await StorageService(uid).loadAppLockEnabled();
    if (!mounted) return;
    setState(() {
      _lockEnabled = enabled;
      _checking = false;
    });
    if (enabled) {
      _authenticate();
    } else {
      setState(() => _unlocked = true);
    }
  }

  Future<void> _authenticate() async {
    setState(() => _error = null);
    try {
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canCheck) {
        // No biometric hardware/enrollment on this device — don't block access.
        setState(() => _unlocked = true);
        return;
      }
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock Cadence to view your health data',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!mounted) return;
      setState(() => _unlocked = didAuthenticate);
      if (!didAuthenticate) {
        setState(() => _error = 'Authentication was cancelled.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _unlocked = true; // Fail open rather than permanently locking the user out on device error.
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.plum)),
      );
    }

    if (_unlocked) {
      return const HomeShell();
    }

    return Scaffold(
      backgroundColor: AppColors.plumDeep,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.amber, width: 2)),
                child: const Icon(Icons.fingerprint, size: 34, color: AppColors.amber),
              ),
              const SizedBox(height: 24),
              Text('Cadence is locked', style: AppText.display(context: context, size: 20, color: AppColors.white)),
              const SizedBox(height: 8),
              Text(
                'Unlock with your fingerprint or face to continue.',
                textAlign: TextAlign.center,
                style: AppText.body(context: context, size: 13, color: AppColors.sageLight),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: AppText.body(context: context, size: 12, color: AppColors.rose)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    elevation: 0,
                  ),
                  child: Text('Try again', style: AppText.body(context: context, size: 14, weight: FontWeight.w700, color: AppColors.plumDeep)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}