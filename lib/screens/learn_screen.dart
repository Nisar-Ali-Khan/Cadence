import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class LearnScreen extends StatefulWidget {
  final String condition;
  const LearnScreen({super.key, required this.condition});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late String _selectedCondition;
  final List<String> _allConditions = ['PCOS', 'Endometriosis', 'Fibromyalgia', 'Autoimmune condition'];

  @override
  void initState() {
    super.initState();
    _selectedCondition = widget.condition;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text('Learn', style: AppText.display(context: context, size: 24)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text('Bite-sized tips for health management', style: AppText.body(context: context, size: 13, color: AppColors.muted)),
        ),
        
        // Horizontal Sidebar/Selector
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _allConditions.length,
            itemBuilder: (context, index) {
              final c = _allConditions[index];
              final selected = _selectedCondition == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedCondition = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.plum : (isDark ? Colors.white10 : AppColors.white),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: selected ? AppColors.plum : (isDark ? Colors.white12 : AppColors.sandDeep)),
                  ),
                  child: Center(
                    child: Text(
                      c,
                      style: AppText.body(
                        context: context,
                        size: 12,
                        weight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? Colors.white : (isDark ? Colors.white70 : AppColors.ink),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: _buildTipsFor(context, _selectedCondition),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTipsFor(BuildContext context, String condition) {
    if (condition == 'Endometriosis') {
      return [
        _tipCard(
          context,
          title: 'Anti-Inflammatory Diet',
          description: 'Focus on omega-3 rich foods like salmon and flaxseeds to help reduce pelvic inflammation.',
          icon: Icons.restaurant_outlined,
          color: AppColors.plum,
        ),
        _tipCard(
          context,
          title: 'Gentle Movement',
          description: 'Pelvic floor physical therapy and restorative yoga can help ease chronic pain.',
          icon: Icons.self_improvement,
          color: AppColors.sage,
        ),
        _tipCard(
          context,
          title: 'Heat Therapy',
          description: 'A warm heating pad or warm bath can help relax pelvic muscles during a flare.',
          icon: Icons.hot_tub,
          color: AppColors.rose,
        ),
      ];
    } else if (condition == 'Fibromyalgia') {
      return [
        _tipCard(
          context,
          title: 'Pacing Yourself',
          description: 'Break tasks into smaller steps and rest before you feel exhausted to manage energy.',
          icon: Icons.timer_outlined,
          color: AppColors.amber,
        ),
        _tipCard(
          context,
          title: 'Sleep Hygiene',
          description: 'Consistent sleep routines are vital. Try a cool, dark room and no screens before bed.',
          icon: Icons.bedtime_outlined,
          color: AppColors.plum,
        ),
        _tipCard(
          context,
          title: 'Low-Impact Exercise',
          description: 'Swimming or water aerobics are excellent for movement without putting stress on joints.',
          icon: Icons.pool,
          color: AppColors.sage,
        ),
      ];
    } else if (condition == 'Autoimmune condition') {
      return [
        _tipCard(
          context,
          title: 'Stress & Flares',
          description: 'High stress can trigger autoimmune responses. Mindfulness can help keep flares at bay.',
          icon: Icons.psychology_outlined,
          color: AppColors.rose,
        ),
        _tipCard(
          context,
          title: 'Gut Health',
          description: 'Probiotic-rich foods like yogurt or kimchi can support your immune system from the gut.',
          icon: Icons.biotech_outlined,
          color: AppColors.sage,
        ),
      ];
    } else {
      // Default: PCOS
      return [
        _tipCard(
          context,
          title: 'Managing Insulin Resistance',
          description: 'Focus on complex carbs like oats and quinoa to keep your blood sugar stable.',
          icon: Icons.restaurant_outlined,
          color: AppColors.plum,
        ),
        _tipCard(
          context,
          title: 'Movement for PCOS',
          description: 'Strength training and low-impact cardio (like walking) are great for hormonal balance.',
          icon: Icons.directions_walk,
          color: AppColors.sage,
        ),
        _tipCard(
          context,
          title: 'Morning Routine',
          description: 'Start your day with a high-protein breakfast to reduce cravings later on.',
          icon: Icons.wb_sunny_outlined,
          color: AppColors.amber,
        ),
        _tipCard(
          context,
          title: 'Sleep & Hormones',
          description: 'Aim for 7-9 hours. Poor sleep can increase cortisol, which may worsen symptoms.',
          icon: Icons.bedtime_outlined,
          color: AppColors.rose,
        ),
      ];
    }
  }

  Widget _tipCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color}) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(context: context, size: 16, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description, style: AppText.body(context: context, size: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
