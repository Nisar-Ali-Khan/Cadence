import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

String phaseForDay(int day, int cycleLength) {
  final menstrualEnd = (cycleLength * 5 / 28).round();
  final follicularEnd = (cycleLength * 13 / 28).round();
  final ovulationEnd = (cycleLength * 16 / 28).round();

  if (day <= menstrualEnd) return 'Menstrual Phase';
  if (day <= follicularEnd) return 'Follicular Phase';
  if (day <= ovulationEnd) return 'Ovulation Window';
  return 'Luteal Phase';
}

class CycleRing extends StatelessWidget {
  final List<double> cycleData;
  final int currentDay;
  final int cycleLength;

  const CycleRing({
    super.key,
    required this.cycleData,
    required this.currentDay,
    required this.cycleLength,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(260, 260),
            painter: CycleRingPainter(cycleData: cycleData, currentDay: currentDay, isDark: Theme.of(context).brightness == Brightness.dark),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Day $currentDay', style: AppText.display(context: context, size: 28)),
              const SizedBox(height: 4),
              Text('of $cycleLength · ${phaseForDay(currentDay, cycleLength)}', style: AppText.body(context: context, size: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.sageLight : AppColors.plum)),
            ],
          ),
        ],
      ),
    );
  }
}

class CycleRingPainter extends CustomPainter {
  final List<double> cycleData;
  final int currentDay;

  CycleRingPainter({required this.cycleData, required this.currentDay, required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 36;

    final trackPaint = Paint()
      ..color = isDark ? Colors.white10 : AppColors.sandDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, trackPaint);

    if (cycleData.isEmpty) return;

    for (int i = 0; i < cycleData.length; i++) {
      final angle = (i / cycleData.length) * 2 * pi - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      final t = (cycleData[i] / 10).clamp(0.0, 1.0);
      final color = Color.lerp(AppColors.sageLight, AppColors.rose, t)!;
      final isToday = i == currentDay - 1;
      final r = isToday ? 9.0 : 5.0 + t * 3;

      if (isToday) {
        final glowPaint = Paint()
          ..color = AppColors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(x, y), r + 5, glowPaint);
      }

      final nodePaint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), r, nodePaint);

      if (isToday) {
        final borderPaint = Paint()
          ..color = AppColors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(x, y), r, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) {
    if (oldDelegate.currentDay != currentDay) return true;
    if (oldDelegate.cycleData.length != cycleData.length) return true;
    for (int i = 0; i < cycleData.length; i++) {
      if (oldDelegate.cycleData[i] != cycleData[i]) return true;
    }
    return false;
  }
}