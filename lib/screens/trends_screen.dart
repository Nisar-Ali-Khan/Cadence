import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class TrendsScreen extends StatelessWidget {
  final Map<int, Map<String, double>> dailyLogs;
  final int cycleLength;

  const TrendsScreen({super.key, required this.dailyLogs, required this.cycleLength});

  @override
  Widget build(BuildContext context) {
    final sortedDays = dailyLogs.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Trends', style: AppText.display(size: 24)),
        const SizedBox(height: 4),
        Text('Built from your own logged days', style: AppText.body(size: 13, color: AppColors.muted)),
        const SizedBox(height: 16),
        if (sortedDays.length < 2)
          _buildEmptyState()
        else ...[
          _buildChartCard(sortedDays),
          _buildInsightsCard(sortedDays),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.show_chart, size: 38, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('Not enough logs yet', style: AppText.display(size: 16)),
          const SizedBox(height: 6),
          Text(
            'Log at least 2 days from the Today tab and your trends will start showing up here.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<int> sortedDays) {
    List<FlSpot> spotsFor(String key) => List.generate(
      sortedDays.length,
          (i) => FlSpot(i.toDouble(), dailyLogs[sortedDays[i]]![key] ?? 0),
    );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last ${sortedDays.length} logged day${sortedDays.length == 1 ? '' : 's'}',
              style: AppText.body(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (v) => const FlLine(color: AppColors.sandDeep, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 2,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toInt().toString(), style: AppText.body(size: 10, color: AppColors.muted)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= sortedDays.length) return const SizedBox.shrink();
                        return Text('D${sortedDays[i]}', style: AppText.body(size: 10, color: AppColors.muted));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(spots: spotsFor('pain'), isCurved: true, color: AppColors.rose, barWidth: 2, dotData: const FlDotData(show: true)),
                  LineChartBarData(spots: spotsFor('fatigue'), isCurved: true, color: AppColors.amber, barWidth: 2, dotData: const FlDotData(show: true)),
                  LineChartBarData(spots: spotsFor('mood'), isCurved: true, color: AppColors.sage, barWidth: 2, dotData: const FlDotData(show: true)),
                  LineChartBarData(spots: spotsFor('bloating'), isCurved: true, color: AppColors.plum, barWidth: 2, dotData: const FlDotData(show: true)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              _legendDot('Pain', AppColors.rose),
              _legendDot('Fatigue', AppColors.amber),
              _legendDot('Mood', AppColors.sage),
              _legendDot('Bloating', AppColors.plum),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(List<int> sortedDays) {
    double avg(String key) {
      final values = sortedDays.map((d) => dailyLogs[d]![key] ?? 0).toList();
      return values.reduce((a, b) => a + b) / values.length;
    }

    final avgPain = avg('pain');
    final avgFatigue = avg('fatigue');
    final avgMood = avg('mood');
    final avgBloating = avg('bloating');

    final ranked = [
      MapEntry('pain', avgPain),
      MapEntry('fatigue', avgFatigue),
      MapEntry('bloating', avgBloating),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final topSymptom = ranked.first;

    String trendNote = '';
    String phaseNote = '';
    
    if (sortedDays.length >= 4) {
      final half = sortedDays.length ~/ 2;
      final earlyDays = sortedDays.sublist(0, half);
      final laterDays = sortedDays.sublist(half);
      final earlyPain = earlyDays.map((d) => dailyLogs[d]!['pain'] ?? 0).reduce((a, b) => a + b) / earlyDays.length;
      final laterPain = laterDays.map((d) => dailyLogs[d]!['pain'] ?? 0).reduce((a, b) => a + b) / laterDays.length;

      if (laterPain - earlyPain >= 1.5) {
        trendNote = 'Pain has been trending upward across your logged days this cycle.';
      } else if (earlyPain - laterPain >= 1.5) {
        trendNote = 'Pain has eased compared to earlier in this cycle.';
      } else {
        trendNote = 'Pain has stayed fairly steady across your logged days.';
      }
      
      // Phase-based estimation (assuming 28-day cycle, day 14 is ovulation)
      final lutealLogs = sortedDays.where((d) => d > 14).toList();
      if (lutealLogs.isNotEmpty) {
        final lutealMood = lutealLogs.map((d) => dailyLogs[d]!['mood'] ?? 0).reduce((a, b) => a + b) / lutealLogs.length;
        if (lutealMood < 4) {
          phaseNote = 'Your mood logs tend to be lower during your luteal phase (after day 14).';
        }
      }
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What stands out', style: AppText.display(size: 16)),
          const SizedBox(height: 10),
          _bullet('You\'ve logged ${sortedDays.length} of $cycleLength days this cycle.'),
          _bullet('Your average ${topSymptom.key} level is ${topSymptom.value.toStringAsFixed(1)}/10 — the highest among what you track.'),
          _bullet('Average mood across logged days: ${avgMood.toStringAsFixed(1)}/10.'),
          if (trendNote.isNotEmpty) _bullet(trendNote),
          if (phaseNote.isNotEmpty) _bullet(phaseNote),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppText.body(size: 11, color: AppColors.muted)),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: AppText.body(size: 13.5)),
          Expanded(child: Text(text, style: AppText.body(size: 13.5))),
        ],
      ),
    );
  }
}