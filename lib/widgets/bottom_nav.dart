import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class CadenceBottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  static const items = [
    NavItem(Icons.favorite_border, 'Today'),
    NavItem(Icons.trending_up, 'Trends'),
    NavItem(Icons.lightbulb_outline, 'Learn'),
    NavItem(Icons.description_outlined, 'Reports'),
    NavItem(Icons.person_outline, 'You'),
  ];

  const CadenceBottomNav({super.key, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.sandDeep)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == activeIndex;
          final color = active ? AppColors.plum : AppColors.muted;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(items[i].label, style: AppText.body(size: 10, weight: FontWeight.w600, color: color)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
