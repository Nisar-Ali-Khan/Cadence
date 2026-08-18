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
        initial: existing ?? {'pain': 3, 'fatigue': 3, 'mood': 5, 'bloating': 3},
      ),
    );

    if (result != null) {
      final severity = (result['pain']! + result['fatigue']! + (10 - result['mood']!) + result['bloating']!) / 4;
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
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.sand,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text('Cycle calendar', style: AppText.display(size: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tap any past or current day to view or update its log.', style: AppText.body(size: 12.5, color: AppColors.muted)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: widget.cycleLength,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final hasLog = _dailyLogs.containsKey(day);
                  final severity = (day - 1) < _cycleData.length ? _cycleData[day - 1] : 0.0;
                  final isToday = day == widget.currentDay;
                  final isFuture = day > widget.currentDay;

                  return GestureDetector(
                    onTap: isFuture ? null : () => _openDay(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasLog
                            ? _colorFor(severity)
                            : (isFuture ? AppColors.sandDeep.withOpacity(0.5) : AppColors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: isToday ? Border.all(color: AppColors.amber, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: hasLog ? AppColors.white : (isFuture ? AppColors.muted : AppColors.ink),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legendDot('Not logged', AppColors.white, bordered: true),
                _legendDot('Logged (low)', AppColors.sageLight),
                _legendDot('Logged (high)', AppColors.rose),
                _legendDot('Upcoming', AppColors.sandDeep),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color, {bool bordered = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: bordered ? Border.all(color: AppColors.sandDeep) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.body(size: 11, color: AppColors.muted)),
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
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.sandDeep, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Day ${widget.day}', style: AppText.display(size: 20)),
          const SizedBox(height: 4),
          Text('View or update this day\'s log', style: AppText.body(size: 12.5, color: AppColors.muted)),
          const SizedBox(height: 16),
          SymptomSlider(
            label: 'Pain', icon: Icons.bolt, accent: AppColors.rose,
            value: _values['pain'] ?? 0, lowLabel: 'None', highLabel: 'Severe',
            onChanged: (v) => setState(() => _values['pain'] = v),
          ),
          SymptomSlider(
            label: 'Fatigue', icon: Icons.bedtime_outlined, accent: AppColors.amber,
            value: _values['fatigue'] ?? 0, lowLabel: 'Rested', highLabel: 'Exhausted',
            onChanged: (v) => setState(() => _values['fatigue'] = v),
          ),
          SymptomSlider(
            label: 'Mood', icon: Icons.sentiment_satisfied_alt, accent: AppColors.sage,
            value: _values['mood'] ?? 0, lowLabel: 'Low', highLabel: 'Great',
            onChanged: (v) => setState(() => _values['mood'] = v),
          ),
          SymptomSlider(
            label: 'Bloating', icon: Icons.water_drop_outlined, accent: AppColors.plum,
            value: _values['bloating'] ?? 0, lowLabel: 'None', highLabel: 'Severe',
            onChanged: (v) => setState(() => _values['bloating'] = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_values),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.plum,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Save', style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}