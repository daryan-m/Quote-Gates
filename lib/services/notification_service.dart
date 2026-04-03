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

    await _notifications.initialize(
      settings: settings,
    );
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
      id: 0,
      title: '✨ Daily Wisdom ✨',
      body: '$quote\n\n— $author',
      notificationDetails: details,
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
      id: 1,
      title: '📖 Your Daily Quote',
      body: '$quote\n\n— $author',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDateTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id: id);
  }

  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }
}
