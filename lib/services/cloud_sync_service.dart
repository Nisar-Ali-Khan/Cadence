import 'package:cloud_firestore/cloud_firestore.dart';

class CloudSyncService {
  final String uid;
  CloudSyncService(this.uid);

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> pushAll({
    required DateTime cycleStartDate,
    required int cycleLength,
    required List<double> cycleData,
    required Map<int, Map<String, double>> dailyLogs,
    required List<Map<String, String>> reports,
    required Map<String, bool> reminders,
    required Map<String, List<int>> reminderTimes,
    required String condition,
    required String weightUnit,
    required Map<int, double> weightLog,
    required Map<int, String> dailyNotes,
    required Map<int, Map<String, bool>> medicationLog,
    required Map<int, int> waterLog,
    required List<String> medicationNames,
    required String themeMode,
    String? profilePicUrl,
  }) async {
    try {
      await _doc.set({
        'condition': condition,
        'cycleStartDate': cycleStartDate.toIso8601String(),
        'cycleLength': cycleLength,
        'cycleData': cycleData,
        'dailyLogs': dailyLogs.map((k, v) => MapEntry(k.toString(), v)),
        'reports': reports,
        'reminders': reminders,
        'reminderTimes': reminderTimes.map((k, v) => MapEntry(k, '${v[0]}:${v[1]}')),
        'weightUnit': weightUnit,
        'weightLog': weightLog.map((k, v) => MapEntry(k.toString(), v)),
        'dailyNotes': dailyNotes.map((k, v) => MapEntry(k.toString(), v)),
        'medicationLog': medicationLog.map((k, v) => MapEntry(k.toString(), v)),
        'waterLog': waterLog.map((k, v) => MapEntry(k.toString(), v)),
        'medicationNames': medicationNames,
        'themeMode': themeMode,
        'profilePicUrl': profilePicUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline or transient failure — local storage remains the source of
      // truth for this session, next successful sync will catch up.
    }
  }

  Future<Map<String, dynamic>?> pullAll() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists) return null;
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAllCloudData() async {
    try {
      await _doc.delete();
    } catch (_) {
      // Best-effort — local delete + auth delete still succeed even if this fails offline.
    }
  }
}