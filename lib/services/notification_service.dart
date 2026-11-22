import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the "session / break ended" notification so it appears even when
/// the app is in the background.
class NotificationService {
  static const int _endId = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Called when the user taps a notification (the timer is the home screen,
  /// so simply opening the app is enough).
  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    } catch (_) {}
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_timer',
          'Timer',
          channelDescription: 'Tells you when a focus session or break ends',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

  Future<void> scheduleEnd(DateTime at, String title, String body) async {
    if (!_ready) return;
    await cancelEnd();
    // UTC is fine: the plugin only needs an absolute instant.
    final when = tz.TZDateTime.from(at, tz.UTC);
    if (!when.isAfter(tz.TZDateTime.now(tz.UTC))) return;
    try {
      await _plugin.zonedSchedule(
        id: _endId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id: _endId,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelEnd() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _endId);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
