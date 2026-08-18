import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int medicationId = 1001;
  static const int dailyLogId = 1002;

  Future<void> init() async {
    if (_initialized) return;
    
    try {
      // 1. Initialize timezone data
      tzdata.initializeTimeZones();
      
      // 2. Attempt to get device timezone with extreme safety
      String timeZoneName = 'UTC'; // Default fallback
      try {
        final dynamic res = await FlutterTimezone.getLocalTimezone();
        if (res is String) {
          timeZoneName = res;
        } else {
          // If it's a TimezoneInfo object, try to get the name
          timeZoneName = res.toString();
        }
        
        // Validate if the location exists in the database
        try {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
        } catch (e) {
          debugPrint('Location $timeZoneName not found, using UTC');
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      } catch (e) {
        debugPrint('Timezone detection failed: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // 3. Setup Notification Plugin
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _plugin.initialize(settings);

      // 4. Request permissions (Android 13+)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService critical init error: $e');
      // Prevent crash by marking as "initialized" even if failed, or just let it be.
      // The main goal is to NOT throw an exception back to main().
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();
    if (!_initialized) return; // Still not init? Exit.

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cadence_reminders',
            'Cadence reminders',
            channelDescription: 'Daily medication and logging reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) await init();
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
  
  Future<void> cancelAll() async {
    if (!_initialized) await init();
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
