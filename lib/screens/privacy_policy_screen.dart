import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
        title: Text('Privacy Policy', style: AppText.display(context: context, size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Last updated: August 2026', style: AppText.body(context: context, size: 12, color: AppColors.muted)),
          const SizedBox(height: 20),
          _section(context, 'What we collect', 'The symptoms, dates, and notes you log, along with your account email and display name.'),
          _section(context, 'How your data is used', 'Your logs are used only to show you your own patterns and to generate the reports you choose to create. We do not sell your data or use it for advertising.'),
          _section(context, 'Where your data lives', 'Your logs are currently stored locally on your device. If cloud sync is enabled in a future update, logs will also be stored securely in your account.'),
          _section(context, 'Your control', 'You can export all of your data at any time from the Profile tab, and you can permanently delete your account and all associated data from the same screen.'),
          _section(context, 'Medical disclaimer', 'Cadence is a self-tracking tool. Patterns shown in the app are based on your own logs and are not a medical diagnosis. Always consult a qualified doctor about your symptoms and treatment.')
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