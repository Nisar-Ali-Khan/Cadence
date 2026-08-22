import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/symptom_slider.dart';

class CalendarScreen extends StatefulWidget {
  final List<double> cycleData;
  final Map<int, Map<String, double>> dailyLogs;
  final int cycleLength;
  final int currentDay;
  final void Function(int day, Map<String, double> values) onSaveDay;

  const CalendarScreen({
    super.key,
    required this.cycleData,
    required this.dailyLogs,
    required this.cycleLength,
    required this.currentDay,
    required this.onSaveDay,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late List<double> _cycleData;
  late Map<int, Map<String, double>> _dailyLogs;

  @override
  void initState() {
    super.initState();
    _cycleData = List<double>.from(widget.cycleData);
    _dailyLogs = widget.dailyLogs.map((k, v) => MapEntry(k, Map<String, double>.from(v)));
  }

  Color _colorFor(double severity) {
    final t = (severity / 10).clamp(0.0, 1.0);
    return Color.lerp(AppColors.sageLight, AppColors.rose, t)!;
  }

  Future<void> _openDay(int day) async {
    final existing = _dailyLogs[day];
    final result = await showModalBottomSheet<Map<String, double>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DayEditSheet(
        day: day,
        isFuture: day > widget.currentDay,
        initial: existing ?? {'pain': 3, 'fatigue': 3, 'mood': 5, 'bloating': 3, 'acne': 1, 'sleep': 7},
      ),
    );

    if (result != null) {
      final severity = (result['pain']! + result['fatigue']! + (10 - result['mood']!) + result['bloating']! + (result['acne'] ?? 1) + (10 - (result['sleep'] ?? 7))) / 6;
      setState(() {
        _dailyLogs[day] = result;
        final idx = (day - 1).clamp(0, _cycleData.length - 1);
        _cycleData[idx] = double.parse(severity.toStringAsFixed(1));
      });
      widget.onSaveDay(day, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
        title: Text('Cycle calendar', style: AppText.display(context: context, size: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tap any past or current day to view or update its log.', style: AppText.body(context: context, size: 12.5, color: AppColors.muted)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: widget.cycleLength,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final hasLog = _dailyLogs.containsKey(day);
                  final severity = (day - 1) < _cycleData.length ? _cycleData[day - 1] : 0.0;
                  final isToday = day == widget.currentDay;
                  final isFuture = day > widget.currentDay;
                  
                  // Indicators
                  final bool isPeriodDay = day <= 5; // Simplified prediction
                  final bool isHighFlare = hasLog && severity >= 6;

                  return GestureDetector(
                    onTap: isFuture ? null : () => _openDay(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasLog
                            ? _colorFor(severity)
                            : (isFuture ? (isDark ? Colors.white10 : AppColors.sandDeep.withOpacity(0.5)) : (isDark ? Colors.white12 : AppColors.white)),
                        borderRadius: BorderRadius.circular(16),
                        border: isToday ? Border.all(color: AppColors.amber, width: 2) : null,
                        boxShadow: hasLog ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: AppText.body(context: context,
                              size: 13,
                              weight: FontWeight.w700,
                              color: hasLog ? AppColors.white : (isFuture ? AppColors.muted : (isDark ? Colors.white : AppColors.ink)),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPeriodDay)
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle)),
                                if (isPeriodDay && isHighFlare) const SizedBox(width: 2),
                                if (isHighFlare)
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Indicators', style: AppText.body(context: context, size: 12, weight: FontWeight.w700, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _legendItem(context, 'Period', AppColors.rose),
                      _legendItem(context, 'High Flare', AppColors.amber),
                      _legendItem(context, 'Logged (low)', AppColors.sageLight),
                      _legendItem(context, 'Logged (high)', AppColors.rose, isBox: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color, {bool isBox = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: isBox ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isBox ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.body(context: context, size: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _DayEditSheet extends StatefulWidget {
  final int day;
  final bool isFuture;
  final Map<String, double> initial;

  const _DayEditSheet({required this.day, required this.isFuture, required this.initial});

  @override
  State<_DayEditSheet> createState() => _DayEditSheetState();
}

class _DayEditSheetState extends State<_DayEditSheet> {
  late Map<String, double> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<String, double>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white12 : AppColors.sandDeep, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Day ${widget.day} Log', style: AppText.display(context: context, size: 20)),
            const SizedBox(height: 4),
            Text('View or update this day\'s log', style: AppText.body(context: context, size: 12.5, color: AppColors.muted)),
            const SizedBox(height: 16),
            SymptomSlider(label: 'Pain', icon: Icons.bolt, accent: AppColors.rose, value: _values['pain'] ?? 0, lowLabel: 'None', highLabel: 'Severe', onChanged: (v) => setState(() => _values['pain'] = v)),
            SymptomSlider(label: 'Fatigue', icon: Icons.bedtime_outlined, accent: AppColors.amber, value: _values['fatigue'] ?? 0, lowLabel: 'Rested', highLabel: 'Exh.', onChanged: (v) => setState(() => _values['fatigue'] = v)),
            SymptomSlider(label: 'Mood', icon: Icons.sentiment_satisfied_alt, accent: AppColors.sage, value: _values['mood'] ?? 0, lowLabel: 'Low', highLabel: 'Great', onChanged: (v) => setState(() => _values['mood'] = v)),
            SymptomSlider(label: 'Bloating', icon: Icons.water_drop_outlined, accent: AppColors.plum, value: _values['bloating'] ?? 0, lowLabel: 'None', highLabel: 'Severe', onChanged: (v) => setState(() => _values['bloating'] = v)),
            SymptomSlider(label: 'Acne', icon: Icons.face, accent: AppColors.rose, value: _values['acne'] ?? 1, lowLabel: 'Clear', highLabel: 'Severe', onChanged: (v) => setState(() => _values['acne'] = v)),
            SymptomSlider(label: 'Sleep', icon: Icons.king_bed_outlined, accent: AppColors.sage, value: _values['sleep'] ?? 7, lowLabel: 'Poor', highLabel: 'Great', onChanged: (v) => setState(() => _values['sleep'] = v)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_values),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.plum,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  elevation: 0,
                ),
                child: Text('Update Logs', style: AppText.body(context: context, size: 15, weight: FontWeight.w700, color: AppColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}