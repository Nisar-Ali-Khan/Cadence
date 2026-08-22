import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  static const int _lastPage = 4;

  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  int _periodLength = 5;
  String _selectedCondition = 'PCOS';

  final List<String> _trackingGoals = [];

  final List<String> _goals = ['Cycle tracking', 'Symptoms', 'Mood & energy', 'Weight'];

  static const _conditions = [
    {'name': 'PCOS', 'icon': Icons.favorite_outline},
    {'name': 'Endometriosis', 'icon': Icons.spa_outlined},
    {'name': 'Fibromyalgia', 'icon': Icons.healing_outlined},
    {'name': 'Autoimmune condition', 'icon': Icons.shield_outlined},
  ];

  void _nextPage() {
    if (_currentPage < _lastPage) {
      setState(() => _currentPage++);
      _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage == 0) return;
    setState(() => _currentPage--);
    _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  Future<void> _selectPeriodDate() async {
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

  Future<void> _finishOnboarding() async {
    if (!mounted) return;

    final uid = AuthService().currentUser?.uid ?? 'guest';
    final storage = StorageService(uid);
    await storage.saveCycleSetup(lastPeriodDate: _lastPeriodDate ?? DateTime.now(), cycleLength: _cycleLength);
    await storage.saveTrackingGoals(_trackingGoals);
    await storage.saveCondition(_selectedCondition);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (route) => false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(onPressed: _previousPage, icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : AppColors.ink))
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 5,
                          width: index == _currentPage ? 28 : 8,
                          decoration: BoxDecoration(
                            color: index == _currentPage ? (isDark ? AppColors.sage : AppColors.plum) : (isDark ? Colors.white10 : AppColors.sandDeep),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(context),
                  _buildConditionPage(context),
                  _buildGoalsPage(context),
                  _buildPeriodPage(context),
                  _buildCyclePage(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  child: Text(
                    _currentPage == _lastPage ? 'Get started' : 'Continue',
                    style: AppText.body(context: context, size: 15, weight: FontWeight.w600, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(color: AppColors.plum.withOpacity(0.10), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_outline, size: 46, color: AppColors.plum),
          ),
          const SizedBox(height: 32),
          Text('Let\'s personalize\nCadence for you', textAlign: TextAlign.center, style: AppText.display(context: context, size: 30)),
          const SizedBox(height: 14),
          Text(
            'A few quick questions will help us make your tracking experience more useful.',
            textAlign: TextAlign.center,
            style: AppText.body(context: context, size: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you\nmanaging?', style: AppText.display(context: context, size: 28)),
          const SizedBox(height: 10),
          Text('This helps us tailor insights to you.', style: AppText.body(context: context, size: 14, color: AppColors.muted)),
          const SizedBox(height: 28),
          ..._conditions.map((c) {
            final name = c['name'] as String;
            final icon = c['icon'] as IconData;
            final selected = _selectedCondition == name;
            return GestureDetector(
              onTap: () => setState(() => _selectedCondition = name),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                decoration: BoxDecoration(
                  color: selected ? AppColors.plum.withOpacity(0.08) : (isDark ? Colors.white10 : AppColors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: selected ? AppColors.plum : (isDark ? Colors.white24 : AppColors.sandDeep), width: selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: selected ? AppColors.plum : AppColors.muted),
                    const SizedBox(width: 14),
                    Expanded(child: Text(name, style: AppText.body(context: context, size: 15, weight: FontWeight.w600))),
                    Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 20, color: selected ? AppColors.plum : AppColors.muted),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalsPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What would you like\nto track?', style: AppText.display(context: context, size: 28)),
          const SizedBox(height: 10),
          Text('Choose everything that matters to you.', style: AppText.body(context: context, size: 14, color: AppColors.muted)),
          const SizedBox(height: 28),
          ..._goals.map((goal) {
            final selected = _trackingGoals.contains(goal);
            return GestureDetector(
              onTap: () => setState(() => selected ? _trackingGoals.remove(goal) : _trackingGoals.add(goal)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                decoration: BoxDecoration(
                  color: selected ? AppColors.plum.withOpacity(0.08) : (isDark ? Colors.white10 : AppColors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: selected ? AppColors.plum : (isDark ? Colors.white24 : AppColors.sandDeep), width: selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? AppColors.plum : AppColors.muted),
                    const SizedBox(width: 14),
                    Expanded(child: Text(goal, style: AppText.body(context: context, size: 15, weight: FontWeight.w600))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPeriodPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When was your\nlast period?', style: AppText.display(context: context, size: 28)),
          const SizedBox(height: 10),
          Text('This helps Cadence understand your cycle.', style: AppText.body(context: context, size: 14, color: AppColors.muted)),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: _selectPeriodDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white24 : AppColors.sandDeep)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.plum.withOpacity(0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.calendar_month_outlined, color: AppColors.plum),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _lastPeriodDate == null ? 'Select date' : '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}',
                      style: AppText.body(context: context, size: 15, weight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyclePage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about\nyour cycle', style: AppText.display(context: context, size: 28)),
          const SizedBox(height: 10),
          Text('You can change these settings later.', style: AppText.body(context: context, size: 14, color: AppColors.muted)),
          const SizedBox(height: 32),
          Text('Average cycle length', style: AppText.body(context: context, size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.white, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _cycleLength.toDouble(),
                    min: 21,
                    max: 45,
                    divisions: 24,
                    activeColor: AppColors.plum,
                    onChanged: (value) => setState(() => _cycleLength = value.round()),
                  ),
                ),
                SizedBox(width: 55, child: Text('$_cycleLength days', style: AppText.body(context: context, size: 13, weight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Typical period length', style: AppText.body(context: context, size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.white, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _periodLength.toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    activeColor: AppColors.plum,
                    onChanged: (value) => setState(() => _periodLength = value.round()),
                  ),
                ),
                SizedBox(width: 55, child: Text('$_periodLength days', style: AppText.body(context: context, size: 13, weight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Your information stays private and is used to personalize your tracking experience.',
            textAlign: TextAlign.center,
            style: AppText.body(context: context, size: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
