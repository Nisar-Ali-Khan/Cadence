import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const AuthGate()),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.plumDeep,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.amber, width: 2.5)),
                  child: Center(
                    child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Cadence', style: AppText.display(context: context, size: 30, weight: FontWeight.w600, color: AppColors.white)),
                const SizedBox(height: 6),
                Text(
                  'PCOS CARE COMPANION',
                  style: AppText.body(context: context, size: 11, weight: FontWeight.w600, color: AppColors.sageLight).copyWith(letterSpacing: 2.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}