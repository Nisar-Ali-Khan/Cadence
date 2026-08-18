import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final String uid;
  StorageService(this.uid);

  String get _keyCycleStart => '${uid}_cycle_start_date';
  String get _keyCycleLength => '${uid}_cycle_length';
  String get _keyCycleData => '${uid}_cycle_data';
  String get _keyTodayLog => '${uid}_today_log';
  String get _keyLogged => '${uid}_logged';
  String get _keyLoggedDate => '${uid}_logged_date';
  String get _keyReports => '${uid}_reports';
  String get _keyReminders => '${uid}_reminders';
  String get _keyDailyLogs => '${uid}_daily_logs';
  String get _keyReminderTimes => '${uid}_reminder_times';
  String get _keyAppLock => '${uid}_app_lock_enabled';
  String get _keyTrackingGoals => '${uid}_tracking_goals';
  String get _keyCondition => '${uid}_condition';
  String get _keyWeightUnit => '${uid}_weight_unit';
  String get _keyWeightLog => '${uid}_weight_log';
  String get _keyDailyNotes => '${uid}_daily_notes';
  String get _keyMedicationLog => '${uid}_medication_log';
  String get _keyWaterLog => '${uid}_water_log';
  String get _keyMedicationNames => '${uid}_medication_names';
  String get _keyThemeMode => '${uid}_theme_mode';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<DateTime> loadOrInitCycleStart() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyCycleStart);
    if (stored != null) return DateTime.parse(stored);
    final start = DateTime.now();
    await prefs.setString(_keyCycleStart, start.toIso8601String());
    return start;
  }

  Future<void> saveCycleSetup({required DateTime lastPeriodDate, required int cycleLength}) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCycleStart, lastPeriodDate.toIso8601String());
    await prefs.setInt(_keyCycleLength, cycleLength);
  }

  Future<int> loadCycleLength({int fallback = 28}) async {
    final prefs = await _prefs;
    return prefs.getInt(_keyCycleLength) ?? fallback;
  }

  Future<List<double>> loadCycleData(List<double> fallback) async {
    final prefs = await _prefs;
    final stored = prefs.getStringList(_keyCycleData);
    if (stored == null) return fallback;
    return stored.map((e) => double.parse(e)).toList();
  }

  Future<void> saveCycleData(List<double> data) async {
    final prefs = await _prefs;
    await prefs.setStringList(_keyCycleData, data.map((e) => e.toString()).toList());
  }

  Future<Map<String, double>> loadTodayLog(Map<String, double> fallback) async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyTodayLog);
    if (stored == null) return fallback;
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> saveTodayLog(Map<String, double> log) async {
    final prefs = await _prefs;
    await prefs.setString(_keyTodayLog, jsonEncode(log));
  }

  Future<bool> loadLoggedFlag(int currentDay) async {
    final prefs = await _prefs;
    final loggedDay = prefs.getInt(_keyLoggedDate);
    return loggedDay == currentDay && (prefs.getBool(_keyLogged) ?? false);
  }

  Future<void> saveLoggedFlag(bool logged, int currentDay) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyLogged, logged);
    await prefs.setInt(_keyLoggedDate, currentDay);
  }

  Future<List<Map<String, String>>> loadReports(List<Map<String, String>> fallback) async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyReports);
    if (stored == null) return fallback;
    final list = jsonDecode(stored) as List<dynamic>;
    return list.map((e) => Map<String, String>.from(e as Map)).toList();
  }

  Future<void> saveReports(List<Map<String, String>> reports) async {
    final prefs = await _prefs;
    await prefs.setString(_keyReports, jsonEncode(reports));
  }

  Future<Map<String, bool>> loadReminders(Map<String, bool> fallback) async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyReminders);
    if (stored == null) return fallback;
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as bool));
  }

  Future<void> saveReminders(Map<String, bool> reminders) async {
    final prefs = await _prefs;
    await prefs.setString(_keyReminders, jsonEncode(reminders));
  }

  Future<Map<String, List<int>>> loadReminderTimes() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyReminderTimes);
    final defaults = {
      'medication': [9, 0],
      'dailyLog': [20, 0],
    };
    if (stored == null) return defaults;
    final map = jsonDecode(stored) as Map<String, dynamic>;
    final result = <String, List<int>>{};
    map.forEach((k, v) {
      final parts = (v as String).split(':');
      result[k] = [int.parse(parts[0]), int.parse(parts[1])];
    });
    for (final key in defaults.keys) {
      result.putIfAbsent(key, () => defaults[key]!);
    }
    return result;
  }

  Future<void> saveReminderTime(String key, int hour, int minute) async {
    final prefs = await _prefs;
    final current = await loadReminderTimes();
    current[key] = [hour, minute];
    final serializable = current.map((k, v) => MapEntry(k, '${v[0]}:${v[1]}'));
    await prefs.setString(_keyReminderTimes, jsonEncode(serializable));
  }

  Future<Map<int, Map<String, double>>> loadDailyLogs() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyDailyLogs);
    if (stored == null) return {};
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((dayKey, value) {
      final inner = (value as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
      return MapEntry(int.parse(dayKey), inner);
    });
  }

  Future<void> saveDailyLogs(Map<int, Map<String, double>> logs) async {
    final prefs = await _prefs;
    final serializable = logs.map((day, values) => MapEntry(day.toString(), values));
    await prefs.setString(_keyDailyLogs, jsonEncode(serializable));
  }

  Future<bool> loadAppLockEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyAppLock) ?? false;
  }

  Future<void> saveAppLockEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyAppLock, enabled);
  }

  Future<List<String>> loadTrackingGoals() async {
    final prefs = await _prefs;
    return prefs.getStringList(_keyTrackingGoals) ?? [];
  }

  Future<void> saveTrackingGoals(List<String> goals) async {
    final prefs = await _prefs;
    await prefs.setStringList(_keyTrackingGoals, goals);
  }

  Future<String> loadCondition({String fallback = 'PCOS'}) async {
    final prefs = await _prefs;
    return prefs.getString(_keyCondition) ?? fallback;
  }

  Future<void> saveCondition(String condition) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCondition, condition);
  }

  Future<String> loadWeightUnit() async {
    final prefs = await _prefs;
    return prefs.getString(_keyWeightUnit) ?? 'kg';
  }

  Future<void> saveWeightUnit(String unit) async {
    final prefs = await _prefs;
    await prefs.setString(_keyWeightUnit, unit);
  }

  /// Weight log, keyed by cycle day, values always stored in kg internally.
  Future<Map<int, double>> loadWeightLog() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyWeightLog);
    if (stored == null) return {};
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
  }

  Future<void> saveWeightLog(Map<int, double> log) async {
    final prefs = await _prefs;
    final serializable = log.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_keyWeightLog, jsonEncode(serializable));
  }

  Future<Map<int, String>> loadDailyNotes() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyDailyNotes);
    if (stored == null) return {};
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as String));
  }

  Future<void> saveDailyNotes(Map<int, String> notes) async {
    final prefs = await _prefs;
    final serializable = notes.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_keyDailyNotes, jsonEncode(serializable));
  }

  Future<Map<int, Map<String, bool>>> loadMedicationLog() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyMedicationLog);
    if (stored == null) return {};
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((dayKey, value) {
      final inner = (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v as bool));
      return MapEntry(int.parse(dayKey), inner);
    });
  }

  Future<void> saveMedicationLog(Map<int, Map<String, bool>> log) async {
    final prefs = await _prefs;
    final serializable = log.map((day, values) => MapEntry(day.toString(), values));
    await prefs.setString(_keyMedicationLog, jsonEncode(serializable));
  }

  Future<Map<int, int>> loadWaterLog() async {
    final prefs = await _prefs;
    final stored = prefs.getString(_keyWaterLog);
    if (stored == null) return {};
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveWaterLog(Map<int, int> log) async {
    final prefs = await _prefs;
    final serializable = log.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_keyWaterLog, jsonEncode(serializable));
  }

  Future<List<String>> loadMedicationNames() async {
    final prefs = await _prefs;
    return prefs.getStringList(_keyMedicationNames) ?? [];
  }

  Future<void> saveMedicationNames(List<String> names) async {
    final prefs = await _prefs;
    await prefs.setStringList(_keyMedicationNames, names);
  }

  Future<String> loadThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyThemeMode) ?? 'light';
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<void> clearAllUserData() async {
    final prefs = await _prefs;
    await prefs.remove(_keyCycleStart);
    await prefs.remove(_keyCycleLength);
    await prefs.remove(_keyCycleData);
    await prefs.remove(_keyTodayLog);
    await prefs.remove(_keyLogged);
    await prefs.remove(_keyLoggedDate);
    await prefs.remove(_keyReports);
    await prefs.remove(_keyReminders);
    await prefs.remove(_keyDailyLogs);
    await prefs.remove(_keyReminderTimes);
    await prefs.remove(_keyAppLock);
    await prefs.remove(_keyTrackingGoals);
    await prefs.remove(_keyCondition);
    await prefs.remove(_keyWeightUnit);
    await prefs.remove(_keyWeightLog);
    await prefs.remove(_keyDailyNotes);
    await prefs.remove(_keyMedicationLog);
    await prefs.remove(_keyWaterLog);
    await prefs.remove(_keyMedicationNames);
    await prefs.remove(_keyThemeMode);
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final cycleStart = await loadOrInitCycleStart();
    final cycleLength = await loadCycleLength();
    final cycleData = await loadCycleData([]);
    final dailyLogs = await loadDailyLogs();
    final reports = await loadReports([]);
    final condition = await loadCondition();
    final weightLog = await loadWeightLog();
    final notes = await loadDailyNotes();
    final medLog = await loadMedicationLog();
    final waterLog = await loadWaterLog();
    final medNames = await loadMedicationNames();
    final theme = await loadThemeMode();

    return {
      'condition': condition,
      'cycleStartDate': cycleStart.toIso8601String(),
      'cycleLength': cycleLength,
      'cycleData': cycleData,
      'dailyLogs': dailyLogs.map((k, v) => MapEntry(k.toString(), v)),
      'weightLog': weightLog.map((k, v) => MapEntry(k.toString(), v)),
      'dailyNotes': notes.map((k, v) => MapEntry(k.toString(), v)),
      'medicationLog': medLog.map((k, v) => MapEntry(k.toString(), v)),
      'waterLog': waterLog.map((k, v) => MapEntry(k.toString(), v)),
      'medicationNames': medNames,
      'themeMode': theme,
      'reports': reports,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
