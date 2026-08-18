import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/cycle_ring.dart';
import '../widgets/section_card.dart';
import '../widgets/symptom_slider.dart';
import 'calendar_screen.dart';

class TodayScreen extends StatelessWidget {
  final List<double> cycleData;
  final int currentDay;
  final int cycleLength;
  final Map<String, double> todayLog;
  final bool logged;
  final Map<int, Map<String, double>> dailyLogs;
  final List<String> trackingGoals;
  final double? todayWeightKg;
  final String weightUnit;
  final int streak;
  final String condition;
  final String todayNote;
  final List<String> medicationNames;
  final Map<String, bool> medicationLog;
  final int waterGlasses;
  final DateTime cycleStartDate;
  final void Function(String key, double value) onChangeLog;
  final VoidCallback onSave;
  final void Function(int day, Map<String, double> values) onSaveDay;
  final void Function(double weightKg) onChangeWeight;
  final void Function(String unit) onChangeWeightUnit;
  final void Function(String note) onUpdateNote;
  final void Function(String name, bool taken) onToggleMedication;
  final void Function(int glasses) onUpdateWater;

  const TodayScreen({
    super.key,
    required this.cycleData,
    required this.currentDay,
    required this.cycleLength,
    required this.todayLog,
    required this.logged,
    required this.dailyLogs,
    required this.trackingGoals,
    required this.todayWeightKg,
    required this.weightUnit,
    required this.streak,
    required this.condition,
    required this.todayNote,
    required this.medicationNames,
    required this.medicationLog,
    required this.waterGlasses,
    required this.cycleStartDate,
    required this.onChangeLog,
    required this.onSave,
    required this.onSaveDay,
    required this.onChangeWeight,
    required this.onChangeWeightUnit,
    required this.onUpdateNote,
    required this.onToggleMedication,
    required this.onUpdateWater,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  double _weightStepKg() => weightUnit == 'kg' ? 0.5 : 0.5 / 2.20462;

  String _displayWeight(double kg) {
    final value = weightUnit == 'kg' ? kg : kg * 2.20462;
    return value.toStringAsFixed(1);
  }

  List<String> _buildPatternInsights() {
    final sortedDays = dailyLogs.keys.toList()..sort();
    if (sortedDays.length < 2) return [];

    double avg(String key) {
      final values = sortedDays.map((d) => dailyLogs[d]![key] ?? 0).toList();
      return values.reduce((a, b) => a + b) / values.length;
    }

    final avgPain = avg('pain');
    final avgFatigue = avg('fatigue');
    final avgBloating = avg('bloating');

    final ranked = [
      MapEntry('fatigue', avgFatigue),
      MapEntry('pain', avgPain),
      MapEntry('bloating', avgBloating),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final topSymptom = ranked.first;

    final notes = <String>[
      'Your average ${topSymptom.key} across ${sortedDays.length} logged days is ${topSymptom.value.toStringAsFixed(1)}/10 — the highest you track.',
    ];

    if (sortedDays.length >= 4) {
      final half = sortedDays.length ~/ 2;
      final earlyDays = sortedDays.sublist(0, half);
      final laterDays = sortedDays.sublist(half);
      final earlyFatigue = earlyDays.map((d) => dailyLogs[d]!['fatigue'] ?? 0).reduce((a, b) => a + b) / earlyDays.length;
      final laterFatigue = laterDays.map((d) => dailyLogs[d]!['fatigue'] ?? 0).reduce((a, b) => a + b) / laterDays.length;

      if (laterFatigue - earlyFatigue >= 1.5) {
        notes.add('Fatigue has been trending upward across your logged days this cycle.');
      } else if (earlyFatigue - laterFatigue >= 1.5) {
        notes.add('Fatigue has eased compared to earlier in this cycle.');
      } else {
        notes.add('Bloating has averaged ${avgBloating.toStringAsFixed(1)}/10 across your logged days.');
      }
    } else {
      notes.add('Keep logging — patterns get clearer with more days tracked.');
    }

    return notes;
  }

  Widget _stepButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color ?? AppColors.sand, borderRadius: BorderRadius.circular(99)),
        child: Icon(icon, size: 18, color: AppColors.plum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeDay = currentDay.clamp(1, cycleData.length);
    final i1 = safeDay - 1;
    final i2 = (safeDay - 2).clamp(0, cycleData.length - 1);
    final i3 = (safeDay - 3).clamp(0, cycleData.length - 1);
    final avgRecent = (cycleData[i1] + cycleData[i2] + cycleData[i3]) / 3;
    
    String flareLabel = 'Flare pattern';
    List<String> rescueTips = [];
    if (condition == 'Endometriosis') {
      flareLabel = 'Inflammatory flare';
      rescueTips = ['Apply heat to pelvic area', 'Avoid inflammatory foods', 'Rest in a comfortable position'];
    } else if (condition == 'Fibromyalgia') {
      flareLabel = 'Pain flare';
      rescueTips = ['Try gentle stretching', 'Ensure good sleep tonight', 'Hydrate with magnesium-rich water'];
    } else if (condition == 'Autoimmune condition') {
      flareLabel = 'Immune flare';
      rescueTips = ['Reduce stress (5min breathing)', 'Anti-inflammatory tea', 'Consult your specialist if severe'];
    } else if (condition == 'PCOS') {
      flareLabel = 'Hormonal flare';
      rescueTips = ['Walk for 10-15 mins', 'Check sugar intake', 'Focus on protein-rich meal'];
    }

    final String flareRisk = avgRecent >= 6 ? 'Elevated' : (avgRecent >= 3.5 ? 'Moderate' : 'Low');
    final Color flareColor = avgRecent >= 6 ? AppColors.rose : (avgRecent >= 3.5 ? AppColors.amber : AppColors.sage);
    final insights = _buildPatternInsights();

    final nextPeriodDate = cycleStartDate.add(Duration(days: cycleLength));
    final ovulationDay = (cycleLength / 2).round();
    final isOvulatingSoon = (currentDay >= ovulationDay - 2 && currentDay <= ovulationDay + 2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(), style: AppText.display(size: 24), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(DateFormat('EEEE, MMMM d').format(DateTime.now()), style: AppText.body(size: 13, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (streak >= 2) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Flexible(child: Text('$streak day streak', style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CalendarScreen(
                        cycleData: cycleData,
                        dailyLogs: dailyLogs,
                        cycleLength: cycleLength,
                        currentDay: safeDay,
                        onSaveDay: onSaveDay,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(99)),
                    child: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.plum),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(99)),
                  child: const Icon(Icons.notifications_none, size: 18, color: AppColors.plum),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _predictionItem('Next Period', DateFormat('MMM d').format(nextPeriodDate), Icons.calendar_today_outlined, AppColors.rose),
              const SizedBox(width: 12),
              _predictionItem('Ovulation', isOvulatingSoon ? 'Soon' : 'In ${ovulationDay - currentDay} days', Icons.favorite_outline, AppColors.sage),
            ],
          ),
        ),

        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              CycleRing(cycleData: cycleData, currentDay: safeDay, cycleLength: cycleLength),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: avgRecent >= 3.5 ? () => _showRescueToolkit(context, flareLabel, rescueTips) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: flareColor.withOpacity(0.13), borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: flareColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Flexible(child: Text('$flareLabel: $flareRisk', style: AppText.body(size: 12, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (avgRecent >= 3.5) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.info_outline, size: 12, color: AppColors.ink),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log today', style: AppText.display(size: 17)),
              const SizedBox(height: 10),
              SymptomSlider(label: 'Pain', icon: Icons.bolt, accent: AppColors.rose, value: todayLog['pain']!, lowLabel: 'None', highLabel: 'Severe', onChanged: (v) => onChangeLog('pain', v)),
              SymptomSlider(label: 'Fatigue', icon: Icons.bedtime_outlined, accent: AppColors.amber, value: todayLog['fatigue']!, lowLabel: 'Rested', highLabel: 'Exhausted', onChanged: (v) => onChangeLog('fatigue', v)),
              SymptomSlider(label: 'Mood', icon: Icons.sentiment_satisfied_alt, accent: AppColors.sage, value: todayLog['mood']!, lowLabel: 'Low', highLabel: 'Great', onChanged: (v) => onChangeLog('mood', v)),
              SymptomSlider(label: 'Bloating', icon: Icons.water_drop_outlined, accent: AppColors.plum, value: todayLog['bloating']!, lowLabel: 'None', highLabel: 'Severe', onChanged: (v) => onChangeLog('bloating', v)),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: logged ? AppColors.sage : AppColors.plum,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (logged) const Icon(Icons.check, size: 16),
                      if (logged) const SizedBox(width: 6),
                      Text(logged ? 'Saved for today' : "Save today's log", style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Water tracker', style: AppText.display(size: 17)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$waterGlasses glasses today', style: AppText.body(size: 15, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Goal: 8 glasses (2L)', style: AppText.body(size: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  _stepButton(Icons.remove, () => onUpdateWater((waterGlasses - 1).clamp(0, 30))),
                  const SizedBox(width: 12),
                  _stepButton(Icons.add, () => onUpdateWater((waterGlasses + 1).clamp(0, 30)), color: AppColors.plum.withOpacity(0.08)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  8,
                  (index) => Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index == 7 ? 0 : 4),
                      decoration: BoxDecoration(
                        color: index < waterGlasses ? AppColors.plum : AppColors.sand,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Medication', style: AppText.display(size: 17)),
              const SizedBox(height: 12),
              if (medicationNames.isEmpty)
                Text('Add your medications in Profile to track them here.', style: AppText.body(size: 13, color: AppColors.muted))
              else
                ...medicationNames.map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(name, style: AppText.body(size: 14, weight: FontWeight.w600))),
                      Checkbox(
                        value: medicationLog[name] ?? false,
                        onChanged: (v) => onToggleMedication(name, v ?? false),
                        activeColor: AppColors.sage,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily note', style: AppText.display(size: 17)),
              const SizedBox(height: 12),
              _NoteField(initialValue: todayNote, onUpdate: onUpdateNote),
            ],
          ),
        ),
        if (trackingGoals.contains('Weight'))
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weight', style: AppText.display(size: 17)),
                    GestureDetector(
                      onTap: () => onChangeWeightUnit(weightUnit == 'kg' ? 'lbs' : 'kg'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(99)),
                        child: Text(weightUnit, style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.plum)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepButton(Icons.remove, () => onChangeWeight(((todayWeightKg ?? 65.0) - _weightStepKg()).clamp(20, 300))),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(todayWeightKg == null ? '—' : _displayWeight(todayWeightKg!), style: AppText.display(size: 32)),
                        Text(weightUnit, style: AppText.body(size: 12, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    _stepButton(Icons.add, () => onChangeWeight(((todayWeightKg ?? 65.0) + _weightStepKg()).clamp(20, 300))),
                  ],
                ),
              ],
            ),
          ),
        if (todayLog['pain']! >= 8)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.1), border: Border.all(color: AppColors.rose.withOpacity(0.3)), borderRadius: BorderRadius.circular(18)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.rose),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This pain level is higher than your recent average. It may be worth checking in with your doctor sooner rather than at your next scheduled visit.',
                    style: AppText.body(size: 13),
                  ),
                ),
              ],
            ),
          ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 16, color: AppColors.plum),
                  const SizedBox(width: 8),
                  Text('Patterns in your logs', style: AppText.display(size: 17)),
                ],
              ),
              const SizedBox(height: 12),
              if (insights.isEmpty)
                Text('Log at least 2 days from here and patterns will start showing up in this card.', style: AppText.body(size: 13.5, color: AppColors.muted))
              else
                ...List.generate(insights.length, (i) {
                  final isLast = i == insights.length - 1;
                  return Container(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.sandDeep))),
                    child: Text(insights[i], style: AppText.body(size: 13.5)),
                  );
                }),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.sandDeep))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 13, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These are patterns from your own logs, not a diagnosis. Share them with your doctor for context.',
                        style: AppText.body(size: 11.5, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _predictionItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body(size: 11, color: AppColors.muted)),
                  Text(value, style: AppText.body(size: 13, weight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescueToolkit(BuildContext context, String title, List<String> tips) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rescue Toolkit', style: AppText.display(size: 20)),
            const SizedBox(height: 4),
            Text('Actionable tips for your $title', style: AppText.body(size: 13, color: AppColors.muted)),
            const SizedBox(height: 20),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: AppColors.sage),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tip, style: AppText.body(size: 14))),
                ],
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Got it', style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.plum))),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onUpdate;

  const _NoteField({required this.initialValue, required this.onUpdate});

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_NoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text && !FocusScope.of(context).hasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: _controller,
        maxLines: 3,
        style: AppText.body(size: 13.5),
        decoration: const InputDecoration(
          hintText: 'How are you really feeling? Any specific triggers?',
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppColors.muted),
        ),
        onChanged: widget.onUpdate,
      ),
    );
  }
}