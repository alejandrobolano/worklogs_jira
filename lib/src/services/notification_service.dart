import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../settings/settings_service.dart';

/// Notification service for scheduling worklog reminders.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin and timezone data.
  static Future<void> initNotifications() async {
    try {
      tzdata.initializeTimeZones();
      final String timeZoneName = tz.local.name;
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const InitializationSettings settings = InitializationSettings(
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );

      await _notifications.initialize(settings);
      debugPrint('[Notifications] Initialized for $timeZoneName');
    } catch (e) {
      debugPrint('[Notifications] Init error: $e');
    }
  }

  /// Schedule reminders for active work days.
  static Future<void> scheduleWeeklyReminderForActiveDays(
    SettingsService settingsService, {
    required bool enabled,
    required TimeOfDay time,
    String? message,
    required Locale locale,
  }) async {
    try {
      if (!enabled) {
        await cancelAllWorklogReminders();
        return;
      }

      final List<int> activeWeekdays =
          (await settingsService.getWorkDays() ?? [])
              .where((d) => d.isWorking)
              .map((d) => d.day)
              .toList();

      await cancelAllWorklogReminders();

      final String body = (message != null && message.isNotEmpty)
          ? message
          : getDefaultReminderMessage(locale);

      for (final weekday in activeWeekdays) {
        final int id = _reminderIdForWeekday(weekday);
        final tz.TZDateTime scheduled = _nextInstanceOfWeekday(weekday, time);

        try {
          await _notifications.zonedSchedule(
            id,
            locale.languageCode == 'es' ? 'Recordatorio' : 'Reminder',
            body,
            scheduled,
            const NotificationDetails(
              macOS: DarwinNotificationDetails(),
              linux: LinuxNotificationDetails(),
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidAllowWhileIdle: true,
          );

          debugPrint('[Notifications] Scheduled ID=$id for $scheduled');
        } catch (e) {
          debugPrint('[Notifications] Schedule error (ID=$id): $e');
        }
      }
    } catch (e) {
      debugPrint('[Notifications] Schedule error: $e');
    }
  }

  /// Cancel all scheduled reminders.
  static Future<void> cancelAllWorklogReminders() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('[Notifications] Cancel error: $e');
    }
  }

  /// Restore reminders from saved preferences.
  static Future<void> restoreWorklogRemindersFromPreferences(
      SettingsService settingsService, Locale locale) async {
    try {
      final bool enabled = await settingsService.getReminderEnabled();
      final TimeOfDay? time = await settingsService.getReminderTime();
      final String? message = await settingsService.getReminderMessage();

      if (enabled) {
        await scheduleWeeklyReminderForActiveDays(
          settingsService,
          enabled: enabled,
          time: time ?? const TimeOfDay(hour: 9, minute: 0),
          message: message,
          locale: locale,
        );
      } else {
        await cancelAllWorklogReminders();
      }
    } catch (e) {
      debugPrint('[Notifications] Restore error: $e');
    }
  }

  /// Get localized default message.
  static String getDefaultReminderMessage(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return 'Recuerda imputar las horas';
      default:
        return 'Remember to log your hours';
    }
  }

  static int _reminderIdForWeekday(int weekday) => 100 + weekday;

  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, TimeOfDay time) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    int loops = 0;
    while ((scheduled.weekday != weekday || scheduled.isBefore(now)) &&
        loops < 14) {
      scheduled = scheduled.add(const Duration(days: 1));
      loops++;
    }

    return scheduled;
  }
}
