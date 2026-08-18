import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SymptomSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final double value;
  final String lowLabel;
  final String highLabel;
  final ValueChanged<double> onChanged;

  const SymptomSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.value,
    required this.lowLabel,
    required this.highLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text(label, style: AppText.body(context: context, size: 13.5, weight: FontWeight.w600)),
                ],
              ),
              Text('${value.round()}/10', style: AppText.mono(context: context, size: 12)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: isDark ? Colors.white12 : AppColors.sandDeep,
              thumbColor: accent,
              overlayColor: accent.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel, style: AppText.body(context: context, size: 11, color: AppColors.muted)),
              Text(highLabel, style: AppText.body(context: context, size: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
