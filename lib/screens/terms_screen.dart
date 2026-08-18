import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
        title: Text('Terms of Service', style: AppText.display(context: context, size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Last updated: August 2026', style: AppText.body(context: context, size: 12, color: AppColors.muted)),
          const SizedBox(height: 20),
          _section(context, 'Using Cadence', 'Cadence helps you log and understand your own symptom patterns. It is intended for personal wellness tracking, not clinical use.'),
          _section(context, 'Not a medical device', 'Cadence does not diagnose, treat, or prevent any medical condition. Insights shown in the app are observations based on your own self-reported logs.'),
          _section(context, 'Your account', 'You are responsible for keeping your login credentials secure. You may delete your account at any time from the Profile tab.'),
          _section(context, 'Acceptable use', 'Please use Cadence only for its intended purpose of personal health tracking, and do not attempt to misuse, reverse-engineer, or disrupt the service.'),
          _section(context, 'Changes to these terms', 'We may update these terms as the app evolves. Continued use of the app after changes means you accept the updated terms.'),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.display(context: context, size: 15)),
          const SizedBox(height: 6),
          Text(body, style: AppText.body(context: context, size: 13.5, color: isDark ? Colors.white70 : AppColors.ink).copyWith(height: 1.5)),
        ],
      ),
    );
  }
}