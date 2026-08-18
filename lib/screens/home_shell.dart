import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/report_item.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/bottom_nav.dart';
import 'today_screen.dart';
import 'trends_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'learn_screen.dart';
import '../main.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final StorageService _storage;
  late final CloudSyncService _cloud;
  final _connectivity = ConnectivityService();
  StreamSubscription<bool>? _connectivitySub;
  bool _isOffline = false;

  bool _loading = true;
  int activeIndex = 0;

  late DateTime cycleStartDate;
  int cycleLength = 28;
  String condition = 'PCOS';
  String weightUnit = 'kg';

  int get currentDay {
    final days = DateTime.now().difference(DateTime(cycleStartDate.year, cycleStartDate.month, cycleStartDate.day)).inDays;
    return (days % cycleLength) + 1;
  }

  int get currentStreak {
    var streak = 0;
    var day = currentDay;
    while (day >= 1 && dailyLogs.containsKey(day)) {
      streak++;
      day--;
    }
    return streak;
  }

  double? get todayWeightKg => weightLog[currentDay];

  List<double> cycleData = [];
  Map<String, double> todayLog = {'pain': 3, 'fatigue': 4, 'mood': 5, 'bloating': 3, 'acne': 1, 'sleep': 7};
  bool logged = false;
  List<ReportItem> reports = [];
  Map<String, bool> reminders = {'medication': true, 'dailyLog': true};
  Map<int, Map<String, double>> dailyLogs = {};
  List<String> trackingGoals = [];
  Map<int, double> weightLog = {};
  Map<int, String> dailyNotes = {};
  Map<int, Map<String, bool>> medicationLog = {};
  Map<int, int> waterLog = {};
  List<String> medicationNames = [];

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid ?? 'guest';
    _storage = StorageService(uid);
    _cloud = CloudSyncService(uid);
    _loadState();

    _connectivity.isOnlineNow().then((online) {
      if (mounted) setState(() => _isOffline = !online);
    });
    _connectivitySub = _connectivity.onStatusChange.listen((online) {
      if (mounted) setState(() => _isOffline = !online);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  List<double> _resizeCycleData(List<double> data, int newLength) {
    if (data.length == newLength) return data;
    if (data.length > newLength) return data.sublist(0, newLength);
    return [...data, ...List.filled(newLength - data.length, 1.0)];
  }

  Future<void> _loadState() async {
    final cloudData = await _cloud.pullAll();

    final loadedCycleLength = await _storage.loadCycleLength();
    final defaultCycle = List<double>.filled(loadedCycleLength, 1.0);
    final localCycleData = await _storage.loadCycleData(defaultCycle);
    final localDailyLogs = await _storage.loadDailyLogs();
    final localReportsRaw = await _storage.loadReports([]);
    // Filter out dummy/placeholder reports permanently
    final localReports = localReportsRaw.where((r) {
      final title = r['title'] ?? '';
      return !title.contains('July 2026') && !title.contains('June 2026');
    }).toList();

    final localReminders = await _storage.loadReminders(reminders);
    final localReminderTimes = await _storage.loadReminderTimes();
    final localStart = await _storage.loadOrInitCycleStart();
    final log = await _storage.loadTodayLog(todayLog);
    final localGoals = await _storage.loadTrackingGoals();
    final localCondition = await _storage.loadCondition();
    final localWeightUnit = await _storage.loadWeightUnit();
    final localWeightLog = await _storage.loadWeightLog();
    final localDailyNotes = await _storage.loadDailyNotes();
    final localMedicationLog = await _storage.loadMedicationLog();
    final localWaterLog = await _storage.loadWaterLog();
    final localMedNames = await _storage.loadMedicationNames();

    DateTime resolvedStart = localStart;
    int resolvedCycleLength = loadedCycleLength;
    List<double> resolvedCycleData = localCycleData;
    Map<int, Map<String, double>> resolvedDailyLogs = localDailyLogs;
    List<Map<String, String>> resolvedReports = localReports;
    Map<String, bool> resolvedReminders = localReminders;
    Map<String, List<int>> resolvedReminderTimes = localReminderTimes;
    String resolvedCondition = localCondition;
    String resolvedWeightUnit = localWeightUnit;
    Map<int, double> resolvedWeightLog = localWeightLog;
    Map<int, String> resolvedDailyNotes = localDailyNotes;
    Map<int, Map<String, bool>> resolvedMedicationLog = localMedicationLog;
    Map<int, int> resolvedWaterLog = localWaterLog;
    List<String> resolvedMedNames = localMedNames;

    if (cloudData != null) {
      resolvedStart = DateTime.tryParse(cloudData['cycleStartDate'] ?? '') ?? localStart;
      resolvedCycleLength = (cloudData['cycleLength'] as num?)?.toInt() ?? loadedCycleLength;
      resolvedCycleData = ((cloudData['cycleData'] as List?) ?? []).map((e) => (e as num).toDouble()).toList();
      if (resolvedCycleData.isEmpty) resolvedCycleData = List<double>.filled(resolvedCycleLength, 1.0);
      resolvedCycleData = _resizeCycleData(resolvedCycleData, resolvedCycleLength);

      final cloudDailyLogs = (cloudData['dailyLogs'] as Map?) ?? {};
      resolvedDailyLogs = cloudDailyLogs.map((k, v) {
        final inner = (v as Map).map((ik, iv) => MapEntry(ik.toString(), (iv as num).toDouble()));
        return MapEntry(int.parse(k.toString()), inner);
      });

      final cloudReportsRaw = (cloudData['reports'] as List?) ?? [];
      resolvedReports = cloudReportsRaw
          .map((e) => Map<String, String>.from(e as Map))
          .where((r) {
            final title = r['title'] ?? '';
            return !title.contains('July 2026') && !title.contains('June 2026');
          })
          .toList();

      final cloudReminders = (cloudData['reminders'] as Map?) ?? {};
      resolvedReminders = cloudReminders.map((k, v) => MapEntry(k.toString(), v as bool));

      final cloudReminderTimes = (cloudData['reminderTimes'] as Map?) ?? {};
      if (cloudReminderTimes.isNotEmpty) {
        resolvedReminderTimes = cloudReminderTimes.map((k, v) {
          final parts = (v as String).split(':');
          return MapEntry(k.toString(), [int.parse(parts[0]), int.parse(parts[1])]);
        });
      }

      resolvedCondition = (cloudData['condition'] as String?) ?? localCondition;
      resolvedWeightUnit = (cloudData['weightUnit'] as String?) ?? localWeightUnit;
      final cloudWeightLog = (cloudData['weightLog'] as Map?) ?? {};
      if (cloudWeightLog.isNotEmpty) {
        resolvedWeightLog = cloudWeightLog.map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toDouble()));
      }

      final cloudNotes = (cloudData['dailyNotes'] as Map?) ?? {};
      resolvedDailyNotes = cloudNotes.map((k, v) => MapEntry(int.parse(k.toString()), v as String));

      final cloudMeds = (cloudData['medicationLog'] as Map?) ?? {};
      resolvedMedicationLog = cloudMeds.map((k, v) {
        final inner = (v as Map? ?? {}).map((ik, iv) => MapEntry(ik.toString(), iv == true));
        return MapEntry(int.parse(k.toString()), inner);
      });

      final cloudWater = (cloudData['waterLog'] as Map?) ?? {};
      resolvedWaterLog = cloudWater.map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()));

      resolvedMedNames = ((cloudData['medicationNames'] as List?) ?? localMedNames).map((e) => e.toString()).toList();

      await _storage.saveCycleSetup(lastPeriodDate: resolvedStart, cycleLength: resolvedCycleLength);
      await _storage.saveCycleData(resolvedCycleData);
      await _storage.saveDailyLogs(resolvedDailyLogs);
      await _storage.saveReports(resolvedReports);
      await _storage.saveReminders(resolvedReminders);
      await _storage.saveCondition(resolvedCondition);
      await _storage.saveWeightUnit(resolvedWeightUnit);
      await _storage.saveWeightLog(resolvedWeightLog);
      await _storage.saveDailyNotes(resolvedDailyNotes);
      await _storage.saveMedicationLog(resolvedMedicationLog);
      await _storage.saveWaterLog(resolvedWaterLog);
      await _storage.saveMedicationNames(resolvedMedNames);
      for (final entry in resolvedReminderTimes.entries) {
        await _storage.saveReminderTime(entry.key, entry.value[0], entry.value[1]);
      }
    } else {
      resolvedCycleData = _resizeCycleData(localCycleData, loadedCycleLength);
      // Even if cloud is null, we should ensure local storage is cleaned up if we filtered anything.
      if (localReportsRaw.length != localReports.length) {
        await _storage.saveReports(localReports);
      }
    }

    setState(() {
      cycleStartDate = resolvedStart;
      cycleLength = resolvedCycleLength;
      cycleData = resolvedCycleData;
      todayLog = log;
      reports = resolvedReports.map((m) => ReportItem.fromMap(m)).toList();
      reminders = resolvedReminders;
      dailyLogs = resolvedDailyLogs;
      trackingGoals = localGoals;
      condition = resolvedCondition;
      weightUnit = resolvedWeightUnit;
      weightLog = resolvedWeightLog;
      dailyNotes = resolvedDailyNotes;
      medicationLog = resolvedMedicationLog;
      waterLog = resolvedWaterLog;
      medicationNames = resolvedMedNames;
      _loading = false;
    });

    _syncToCloud(reminderTimes: resolvedReminderTimes);

    final loggedFlag = await _storage.loadLoggedFlag(currentDay);
    if (mounted) setState(() => logged = loggedFlag);
  }

  Future<void> _syncToCloud({Map<String, List<int>>? reminderTimes}) async {
    final times = reminderTimes ?? await _storage.loadReminderTimes();
    final currentTheme = CadenceApp.of(context).themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _cloud.pushAll(
      cycleStartDate: cycleStartDate,
      cycleLength: cycleLength,
      cycleData: cycleData,
      dailyLogs: dailyLogs,
      reports: reports.map((r) => r.toMap()).toList(),
      reminders: reminders,
      reminderTimes: times,
      condition: condition,
      weightUnit: weightUnit,
      weightLog: weightLog,
      dailyNotes: dailyNotes,
      medicationLog: medicationLog,
      waterLog: waterLog,
      medicationNames: medicationNames,
      themeMode: currentTheme,
    );
  }

  void updateNote(String note) {
    setState(() => dailyNotes[currentDay] = note);
    _storage.saveDailyNotes(dailyNotes);
    _syncToCloud();
  }

  void toggleMedication(String name, bool taken) {
    final dayLog = Map<String, bool>.from(medicationLog[currentDay] ?? {});
    dayLog[name] = taken;
    setState(() => medicationLog[currentDay] = dayLog);
    _storage.saveMedicationLog(medicationLog);
    _syncToCloud();
  }

  void updateMedicationNames(List<String> names) {
    setState(() => medicationNames = names);
    _storage.saveMedicationNames(names);
    _syncToCloud();
  }

  Future<void> toggleTheme() async {
    await CadenceApp.of(context).toggleTheme();
    _syncToCloud();
  }

  void updateWater(int glasses) {
    setState(() => waterLog[currentDay] = glasses);
    _storage.saveWaterLog(waterLog);
    _syncToCloud();
  }

  void updateLog(String key, double value) {
    setState(() {
      todayLog[key] = value;
      logged = false;
    });
    _storage.saveTodayLog(todayLog);
    _storage.saveLoggedFlag(false, currentDay);
  }

  void saveLog() {
    final severity = (todayLog['pain']! + todayLog['fatigue']! + (10 - todayLog['mood']!) + todayLog['bloating']! + todayLog['acne']! + (10 - todayLog['sleep']!)) / 6;
    final safeDay = currentDay.clamp(1, cycleData.length);
    setState(() {
      cycleData[safeDay - 1] = double.parse(severity.toStringAsFixed(1));
      dailyLogs[currentDay] = Map<String, double>.from(todayLog);
      logged = true;
    });
    _storage.saveCycleData(cycleData);
    _storage.saveDailyLogs(dailyLogs);
    _storage.saveLoggedFlag(true, currentDay);
    _syncToCloud();
  }

  void saveDayLog(int day, Map<String, double> values) {
    final severity = (values['pain']! + values['fatigue']! + (10 - values['mood']!) + values['bloating']! + (values['acne'] ?? 1) + (10 - (values['sleep'] ?? 7))) / 6;
    final safeIndex = (day - 1).clamp(0, cycleData.length - 1);

    setState(() {
      cycleData[safeIndex] = double.parse(severity.toStringAsFixed(1));
      dailyLogs[day] = Map<String, double>.from(values);
      if (day == currentDay) {
        todayLog = Map<String, double>.from(values);
        logged = true;
      }
    });

    _storage.saveCycleData(cycleData);
    _storage.saveDailyLogs(dailyLogs);
    if (day == currentDay) {
      _storage.saveTodayLog(todayLog);
      _storage.saveLoggedFlag(true, currentDay);
    }
    _syncToCloud();
  }

  void changeWeight(double weightKg) {
    setState(() => weightLog[currentDay] = weightKg);
    _storage.saveWeightLog(weightLog);
    _syncToCloud();
  }

  void changeWeightUnit(String unit) {
    setState(() => weightUnit = unit);
    _storage.saveWeightUnit(unit);
  }

  void generateReport() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final label = '${months[now.month - 1]} ${now.year}';
    setState(() {
      reports.insert(0, ReportItem(title: 'Cycle Report — $label', date: 'Generated just now'));
    });
    _storage.saveReports(reports.map((r) => r.toMap()).toList());
    _syncToCloud();
  }

  void toggleReminder(String key) {
    setState(() => reminders[key] = !(reminders[key] ?? false));
    _storage.saveReminders(reminders);
    _syncToCloud();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _HomeSkeleton();
    }

    final screens = [
      TodayScreen(
        cycleData: cycleData,
        currentDay: currentDay,
        cycleLength: cycleLength,
        todayLog: todayLog,
        logged: logged,
        dailyLogs: dailyLogs,
        trackingGoals: trackingGoals,
        todayWeightKg: todayWeightKg,
        weightUnit: weightUnit,
        streak: currentStreak,
        condition: condition,
        todayNote: dailyNotes[currentDay] ?? '',
        medicationNames: medicationNames,
        medicationLog: medicationLog[currentDay] ?? {},
        waterGlasses: waterLog[currentDay] ?? 0,
        cycleStartDate: cycleStartDate,
        onChangeLog: updateLog,
        onSave: saveLog,
        onSaveDay: saveDayLog,
        onChangeWeight: changeWeight,
        onChangeWeightUnit: changeWeightUnit,
        onUpdateNote: updateNote,
        onToggleMedication: toggleMedication,
        onUpdateWater: updateWater,
      ),
      TrendsScreen(dailyLogs: dailyLogs, cycleLength: cycleLength),
      LearnScreen(condition: condition),
      ReportsScreen(reports: reports, dailyLogs: dailyLogs, cycleLength: cycleLength, onGenerate: generateReport),
      ProfileScreen(
        reminders: reminders,
        cycleLength: cycleLength,
        cycleStartDate: cycleStartDate,
        medicationNames: medicationNames,
        onToggle: toggleReminder,
        onToggleTheme: toggleTheme,
        onUpdateMeds: updateMedicationNames,
        onDataChanged: () async {
          // 1. Refresh internal state variables from local storage first.
          // This ensures we have the latest selection (like condition) made in EditProfile.
          final newCondition = await _storage.loadCondition();
          final newGoals = await _storage.loadTrackingGoals();
          final newStart = await _storage.loadOrInitCycleStart();
          final newLength = await _storage.loadCycleLength();
          
          setState(() {
            condition = newCondition;
            trackingGoals = newGoals;
            cycleStartDate = newStart;
            cycleLength = newLength;
          });

          // 2. Now push the updated state to cloud.
          await _syncToCloud();
          
          // 3. Finally reload everything to ensure local/cloud are in perfect sync.
          await _loadState();
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_isOffline) _buildOfflineBanner(),
            Expanded(child: screens[activeIndex]),
          ],
        ),
      ),
      bottomNavigationBar: CadenceBottomNav(activeIndex: activeIndex, onTap: (i) => setState(() => activeIndex = i)),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.amber.withOpacity(0.18),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 14, color: AppColors.amber),
          const SizedBox(width: 8),
          Text('You\'re offline — changes will sync once you\'re back online.', style: AppText.body(context: context, size: 11.5, weight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.ink)),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  Widget _bar(BuildContext context, {double width = double.infinity, double height = 16}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(width: width, height: height, decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.sandDeep, borderRadius: BorderRadius.circular(8)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(context, width: 140, height: 22),
              const SizedBox(height: 6),
              _bar(context, width: 100, height: 12),
              const SizedBox(height: 20),
              Container(
                height: 280,
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
                child: Center(child: Container(width: 180, height: 180, decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColors.sandDeep, shape: BoxShape.circle))),
              ),
              const SizedBox(height: 16),
              Container(height: 220, decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24))),
            ],
          ),
        ),
      ),
    );
  }
}
