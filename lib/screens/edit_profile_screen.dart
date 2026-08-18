import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/section_card.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthService();
  late final StorageService _storage;
  late final TextEditingController _name;

  bool _loading = true;
  bool _saving = false;
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  List<String> _trackingGoals = [];
  String _condition = 'PCOS';

  static const _allGoals = ['Cycle tracking', 'Symptoms', 'Mood & energy', 'Weight'];
  static const _allConditions = ['PCOS', 'Endometriosis', 'Fibromyalgia', 'Autoimmune condition'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _auth.currentUser?.displayName ?? '');
    final uid = _auth.currentUser?.uid ?? 'guest';
    _storage = StorageService(uid);
    _loadCycleInfo();
  }

  Future<void> _loadCycleInfo() async {
    final start = await _storage.loadOrInitCycleStart();
    final length = await _storage.loadCycleLength();
    final goals = await _storage.loadTrackingGoals();
    final condition = await _storage.loadCondition();
    if (!mounted) return;
    setState(() {
      _lastPeriodDate = start;
      _cycleLength = length;
      _trackingGoals = goals;
      _condition = condition;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.sage, onPrimary: Colors.black, surface: Color(0xFF1E1E1E), onSurface: Colors.white)
                : const ColorScheme.light(primary: AppColors.plum, onPrimary: AppColors.white, surface: AppColors.sand, onSurface: AppColors.ink),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) setState(() => _lastPeriodDate = selected);
  }

  void _toggleGoal(String goal) {
    setState(() => _trackingGoals.contains(goal) ? _trackingGoals.remove(goal) : _trackingGoals.add(goal));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_name.text.trim().isNotEmpty) {
        await _auth.currentUser?.updateDisplayName(_name.text.trim());
      }
      await _storage.saveCycleSetup(
        lastPeriodDate: _lastPeriodDate ?? DateTime.now(),
        cycleLength: _cycleLength,
      );
      await _storage.saveTrackingGoals(_trackingGoals);
      await _storage.saveCondition(_condition);
      
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.ink),
        title: Text('Edit profile', style: AppText.display(context: context, size: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.plum))
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About you', style: AppText.display(context: context, size: 16)),
                const SizedBox(height: 14),
                Text('Full name', style: AppText.body(context: context, size: 12.5, weight: FontWeight.w600, color: AppColors.muted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.sand, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: AppColors.muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _name,
                          style: AppText.body(context: context, size: 14, weight: FontWeight.w600),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.sand, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 18, color: AppColors.muted),
                      const SizedBox(width: 12),
                      Text(email, style: AppText.body(context: context, size: 14, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Condition', style: AppText.display(context: context, size: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _allConditions.map((c) {
                    final selected = _condition == c;
                    return GestureDetector(
                      onTap: () => setState(() => _condition = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.sage.withOpacity(0.15) : (isDark ? Colors.white10 : AppColors.sand),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: selected ? AppColors.sage : (isDark ? Colors.white12 : AppColors.sandDeep), width: selected ? 1.5 : 1),
                        ),
                        child: Text(c, style: AppText.body(context: context, size: 12.5, weight: FontWeight.w700, color: selected ? AppColors.sage : (isDark ? Colors.white70 : AppColors.ink))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What you\'re tracking', style: AppText.display(context: context, size: 16)),
                const SizedBox(height: 4),
                Text('Choose everything that matters to you.', style: AppText.body(context: context, size: 12.5, color: AppColors.muted)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _allGoals.map((goal) {
                    final selected = _trackingGoals.contains(goal);
                    return GestureDetector(
                      onTap: () => _toggleGoal(goal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.plum.withOpacity(0.08) : (isDark ? Colors.white10 : AppColors.sand),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: selected ? AppColors.plum : (isDark ? Colors.white12 : AppColors.sandDeep), width: selected ? 1.5 : 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 15, color: selected ? (isDark ? AppColors.sageLight : AppColors.plum) : AppColors.muted),
                            const SizedBox(width: 6),
                            Text(goal, style: AppText.body(context: context, size: 12.5, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cycle settings', style: AppText.display(context: context, size: 16)),
                const SizedBox(height: 4),
                Text('Used to calculate which cycle day you\'re on.', style: AppText.body(context: context, size: 12.5, color: AppColors.muted)),
                const SizedBox(height: 16),
                Text('Last period start date', style: AppText.body(context: context, size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.sand, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: isDark ? AppColors.sageLight : AppColors.plum),
                        const SizedBox(width: 12),
                        Text(
                          _lastPeriodDate == null ? 'Select date' : '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}',
                          style: AppText.body(context: context, size: 14, weight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Average cycle length', style: AppText.body(context: context, size: 13, weight: FontWeight.w600)),
                    Text('$_cycleLength days', style: AppText.mono(context: context, size: 12)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: isDark ? AppColors.sage : AppColors.plum, inactiveTrackColor: isDark ? Colors.white12 : AppColors.sandDeep, thumbColor: isDark ? AppColors.sage : AppColors.plum, trackHeight: 4),
                  child: Slider(value: _cycleLength.toDouble(), min: 21, max: 45, divisions: 24, onChanged: (v) => setState(() => _cycleLength = v.round())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.plum, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)), elevation: 0),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : Text('Save changes', style: AppText.body(context: context, size: 14, weight: FontWeight.w600, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
