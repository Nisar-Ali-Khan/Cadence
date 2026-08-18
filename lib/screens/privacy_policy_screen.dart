import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.sand,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text('Privacy Policy', style: AppText.display(size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Last updated: August 2026', style: AppText.body(size: 12, color: AppColors.muted)),
          const SizedBox(height: 20),
          _section('What we collect', 'The symptoms, dates, and notes you log, along with your account email and display name.'),
          _section('How your data is used', 'Your logs are used only to show you your own patterns and to generate the reports you choose to create. We do not sell your data or use it for advertising.'),
          _section('Where your data lives', 'Your logs are currently stored locally on your device. If cloud sync is enabled in a future update, logs will also be stored securely in your account.'),
          _section('Your control', 'You can export all of your data at any time from the Profile tab, and you can permanently delete your account and all associated data from the same screen.'),
          _section('Medical disclaimer', 'Cadence is a self-tracking tool. Patterns shown in the app are based on your own logs and are not a medical diagnosis. Always consult a qualified doctor about your symptoms and treatment.')
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.display(size: 15)),
          const SizedBox(height: 6),
          Text(body, style: AppText.body(size: 13.5, color: AppColors.ink).copyWith(height: 1.5)),
        ],
      ),
    );
  }
}