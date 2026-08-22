import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class TrendsScreen extends StatelessWidget {
  final Map<int, Map<String, double>> dailyLogs;
  final Map<int, double> weightLog;
  final String weightUnit;
  final int cycleLength;

  const TrendsScreen({
    super.key,
    required this.dailyLogs,
    required this.weightLog,
    required this.weightUnit,
    required this.cycleLength,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDays = dailyLogs.keys.toList()..sort();
    final weightDays = weightLog.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Trends', style: AppText.body(context: context, size: 24, weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Built from your own logged data', style: AppText.body(context: context, size: 13, color: AppColors.muted)),
        const SizedBox(height: 16),
        
        if (sortedDays.length < 2)
          _buildEmptyState(context)
        else ...[
          _buildChartCard(context, sortedDays),
          if (weightDays.length >= 2) ...[
            const SizedBox(height: 16),
            _buildWeightChartCard(context, weightDays),
          ],
          _buildInsightsCard(context, sortedDays),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.show_chart, size: 38, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('Not enough logs yet', style: AppText.display(context: context, size: 16)),
          const SizedBox(height: 6),
          Text(
            'Log at least 2 days from the Today tab and your trends will start showing up here.',
            textAlign: TextAlign.center,
            style: AppText.body(context: context, size: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<int> sortedDays) {
    List<FlSpot> spotsFor(String key) => List.generate(
      sortedDays.length,
      (i) => FlSpot(i.toDouble(), dailyLogs[sortedDays[i]]![key] ?? 0),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Symptom intensity', style: AppText.body(context: context, size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Last ${sortedDays.length} logged days', style: AppText.body(context: context, size: 11, color: AppColors.muted)),
          const SizedBox(height: 20),
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
                  getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white10 : AppColors.sandDeep, strokeWidth: 1),
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
                          Text(value.toInt().toString(), style: AppText.body(context: context, size: 10, color: AppColors.muted)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= sortedDays.length) return const SizedBox.shrink();
                        return Text('D${sortedDays[i]}', style: AppText.body(context: context, size: 10, color: AppColors.muted));
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendDot(context, 'Pain', AppColors.rose),
              _legendDot(context, 'Fatigue', AppColors.amber),
              _legendDot(context, 'Mood', AppColors.sage),
              _legendDot(context, 'Bloating', AppColors.plum),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChartCard(BuildContext context, List<int> weightDays) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    double convert(double kg) => weightUnit == 'kg' ? kg : kg * 2.20462;
    
    final spots = List.generate(
      weightDays.length,
      (i) => FlSpot(i.toDouble(), convert(weightLog[weightDays[i]]!)),
    );

    final values = weightDays.map((d) => convert(weightLog[d]!)).toList();
    final minW = (values.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxW = (values.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weight progress ($weightUnit)', style: AppText.body(context: context, size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Based on your latest ${weightDays.length} readings', style: AppText.body(context: context, size: 11, color: AppColors.muted)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minW,
                maxY: maxW,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white10 : AppColors.sandDeep, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toInt().toString(), style: AppText.body(context: context, size: 10, color: AppColors.muted)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= weightDays.length) return const SizedBox.shrink();
                        return Text('D${weightDays[i]}', style: AppText.body(context: context, size: 10, color: AppColors.muted));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.sage,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.sage.withOpacity(0.1),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, List<int> sortedDays) {
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

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What stands out', style: AppText.display(context: context, size: 16)),
          const SizedBox(height: 10),
          _bullet(context, 'You\'ve logged ${sortedDays.length} of $cycleLength days this cycle.'),
          _bullet(context, 'Your average ${topSymptom.key} level is ${topSymptom.value.toStringAsFixed(1)}/10.'),
          _bullet(context, 'Average mood across logged days: ${avgMood.toStringAsFixed(1)}/10.'),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppText.body(context: context, size: 11, color: AppColors.muted)),
      ],
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: AppText.body(context: context, size: 13.5)),
          Expanded(child: Text(text, style: AppText.body(context: context, size: 13.5))),
        ],
      ),
    );
  }
}
