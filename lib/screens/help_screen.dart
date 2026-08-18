import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    ['How does the Cycle Ring work?', 'Each dot represents a day of your cycle. Colors shift from soft green to rose as your logged severity increases. Today\'s day is highlighted in amber.'],
    ['Can I edit a past log?', 'Right now you can only edit today\'s log. Editing past days is planned for a future update.'],
    ['Are my insights a diagnosis?', 'No. Everything in "Patterns in your logs" and Trends is based purely on your own entries — always share them with your doctor rather than treating them as a diagnosis.'],
    ['How do I change my cycle length?', 'Go to Profile → tap your profile card → update your cycle settings there.'],
    ['Can I get my data out of the app?', 'Yes — Profile → Export my data will generate a file you can save or share.'],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
        title: Text('Help & FAQ', style: AppText.display(context: context, size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _faqs
            .map((f) => SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f[0], style: AppText.body(context: context, size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(f[1], style: AppText.body(context: context, size: 13, color: AppColors.muted).copyWith(height: 1.5)),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }
}