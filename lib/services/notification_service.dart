import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showDailyQuoteNotification(
      String quote, String author) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_quote_channel',
      'Daily Quote',
      channelDescription: 'Your daily wisdom quote notification',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      '✨ Daily Wisdom ✨',
      '$quote\n\n— $author',
      details,
    );
  }

  static Future<void> scheduleDailyQuote({
    required int hour,
    required int minute,
    required String quote,
    required String author,
  }) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    final DateTime finalTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    // بەکارهێنانی گۆڕاوەکان - debugPrint
    debugPrint("Daily quote scheduled for: ${finalTime.toLocal()}");

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_quote_channel',
      'Daily Quote',
      channelDescription: 'Your daily wisdom quote',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.periodicallyShow(
      1,
      '📖 Your Daily Quote',
      '$quote\n\n— $author',
      RepeatInterval.daily,
      details,
    );
  }

  static Future<void> scheduleReminder(
    DateTime time,
    String title,
    String body,
    int id,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Your personal reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    final tzDateTime = tz.TZDateTime.from(time, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }
}
