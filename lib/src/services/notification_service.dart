import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_day.dart';
import '../settings/preferences_service.dart';
import '../settings/settings_service.dart';

class ReminderSyncResult {
  const ReminderSyncResult({
    required this.success,
    required this.activeReminderDays,
    required this.removedTasks,
    required this.createdTasks,
    required this.verifiedTasks,
    this.errorMessage,
  });

  final bool success;
  final List<String> activeReminderDays;
  final List<String> removedTasks;
  final List<String> createdTasks;
  final List<String> verifiedTasks;
  final String? errorMessage;

  factory ReminderSyncResult.success({
    List<String> activeReminderDays = const <String>[],
    List<String> removedTasks = const <String>[],
    List<String> createdTasks = const <String>[],
    List<String> verifiedTasks = const <String>[],
  }) {
    return ReminderSyncResult(
      success: true,
      activeReminderDays: activeReminderDays,
      removedTasks: removedTasks,
      createdTasks: createdTasks,
      verifiedTasks: verifiedTasks,
    );
  }

  factory ReminderSyncResult.failure({
    required String errorMessage,
    List<String> activeReminderDays = const <String>[],
    List<String> removedTasks = const <String>[],
    List<String> createdTasks = const <String>[],
    List<String> verifiedTasks = const <String>[],
  }) {
    return ReminderSyncResult(
      success: false,
      errorMessage: errorMessage,
      activeReminderDays: activeReminderDays,
      removedTasks: removedTasks,
      createdTasks: createdTasks,
      verifiedTasks: verifiedTasks,
    );
  }

  String buildUserMessage(Locale locale, {required bool reminderEnabled}) {
    final bool isEs = locale.languageCode == 'es';
    final String active = activeReminderDays.isEmpty
        ? (isEs ? 'ninguno' : 'none')
        : activeReminderDays.join(', ');
    final String removed = removedTasks.isEmpty
        ? (isEs ? 'ninguna' : 'none')
        : removedTasks.join(', ');
    final String verified = verifiedTasks.isEmpty
        ? (isEs ? 'ninguna' : 'none')
        : verifiedTasks.join(', ');

    if (!success) {
      return isEs
          ? 'Error al sincronizar los recordatorios.\nDías activos: $active\nEliminadas: $removed\nVerificadas: $verified\nDetalle: ${errorMessage ?? 'desconocido'}'
          : 'Failed to sync reminders.\nActive days: $active\nRemoved: $removed\nVerified: $verified\nDetails: ${errorMessage ?? 'unknown'}';
    }

    if (!reminderEnabled || activeReminderDays.isEmpty) {
      return isEs
          ? 'Recordatorios desactivados.\nTareas eliminadas: $removed\nVerificadas en Windows: $verified'
          : 'Reminders disabled.\nRemoved tasks: $removed\nVerified in Windows: $verified';
    }

    final String created = createdTasks.isEmpty
        ? (isEs ? 'ninguna' : 'none')
        : createdTasks.join(', ');

    return isEs
        ? 'Recordatorios sincronizados.\nDías: $active\nCreadas: $created\nEliminadas previas: $removed\nVerificadas en Windows: $verified'
        : 'Reminders synced.\nDays: $active\nCreated: $created\nPreviously removed: $removed\nVerified in Windows: $verified';
  }
}

class _WindowsTaskInfo {
  const _WindowsTaskInfo({
    required this.taskName,
    required this.dayCode,
    required this.time,
  });

  final String taskName;
  final String dayCode;
  final String time;

  String get summary => '$dayCode $time';
}

class _WindowsTaskMutationResult {
  const _WindowsTaskMutationResult({
    required this.success,
    this.errorMessage,
    this.removedTasks = const <_WindowsTaskInfo>[],
    this.createdTasks = const <_WindowsTaskInfo>[],
    this.verifiedTasks = const <_WindowsTaskInfo>[],
  });

  final bool success;
  final String? errorMessage;
  final List<_WindowsTaskInfo> removedTasks;
  final List<_WindowsTaskInfo> createdTasks;
  final List<_WindowsTaskInfo> verifiedTasks;
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _appName = 'WorklogsJira';
  static const String _appUserModelId = '35383WorklogsJira.WorklogsJira';
  static const String _protocol = 'worklogsjira';

  static const String _taskPrefix = 'WorklogsJira_Reminder_';
  static const String _legacyTaskName = 'WorklogsJira_DailyReminder';
  static const String _lastReminderDateKey = 'lastReminderDate';

  static final Map<int, String> _dayToSchtasks = <int, String>{
    1: 'MON',
    2: 'TUE',
    3: 'WED',
    4: 'THU',
    5: 'FRI',
    6: 'SAT',
    7: 'SUN',
  };

  /// PowerShell day names used by New-ScheduledTaskTrigger -DaysOfWeek
  static final Map<int, String> _dayToPowerShell = <int, String>{
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  static Timer? _alignTimer;
  static Timer? _reminderTimer;
  static bool _initialized = false;

  static const String _reminderLockName = 'worklogsjira_reminder.lock';
  static const String _schedulerLockName = 'worklogsjira_scheduler.lock';

  static void Function(NotificationResponse response)? onNotificationTap;

  static Future<void> initNotifications() async {
    if (_initialized) return;

    const InitializationSettings settings = InitializationSettings(
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: _appName,
        appUserModelId: _appUserModelId,
        guid: 'd49b0314-ee7a-4626-bf79-97cdb8a99a1c',
      ),
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          '[Notifications] tapped id=${response.id} payload=${response.payload}',
        );
        onNotificationTap?.call(response);
      },
    );

    if (Platform.isWindows) {
      await _registerWindowsIntegration();
    }

    _initialized = true;
    debugPrint('[Notifications] initialized');
  }

  static Future<ReminderSyncResult> scheduleWeeklyReminderForActiveDays({
    required bool enabled,
    required List<WorkDay> workDays,
    required TimeOfDay defaultTime,
    String? message,
    required Locale locale,
  }) async {
    try {
      await initNotifications();

      _stopReminderTimer();

      final List<_WindowsTaskInfo> desiredTasks =
          _buildDesiredWindowsTasks(workDays, defaultTime);
      final List<String> activeDaySummaries =
          desiredTasks.map((task) => task.summary).toList();

      if (!enabled || desiredTasks.isEmpty) {
        _WindowsTaskMutationResult removalResult =
            const _WindowsTaskMutationResult(success: true);
        if (Platform.isWindows) {
          removalResult = await _removeWindowsTasks();
        }
        return removalResult.success
            ? ReminderSyncResult.success(
                removedTasks: removalResult.removedTasks
                    .map((task) => task.summary)
                    .toList(),
                verifiedTasks: removalResult.verifiedTasks
                    .map((task) => task.summary)
                    .toList(),
              )
            : ReminderSyncResult.failure(
                errorMessage:
                    removalResult.errorMessage ?? 'Failed to remove tasks',
                removedTasks: removalResult.removedTasks
                    .map((task) => task.summary)
                    .toList(),
                verifiedTasks: removalResult.verifiedTasks
                    .map((task) => task.summary)
                    .toList(),
              );
      }

      _WindowsTaskMutationResult windowsResult =
          const _WindowsTaskMutationResult(success: true);

      if (Platform.isWindows) {
        windowsResult = await _scheduleWindowsTasks(
          workDays: workDays,
          defaultTime: defaultTime,
        );
        if (!windowsResult.success) {
          _startReminderTimer(
            workDays: workDays,
            defaultTime: defaultTime,
            locale: locale,
            message: message,
          );
          return ReminderSyncResult.failure(
            errorMessage: windowsResult.errorMessage ??
                'Failed to synchronize Windows tasks',
            activeReminderDays: activeDaySummaries,
            removedTasks:
                windowsResult.removedTasks.map((task) => task.summary).toList(),
            createdTasks:
                windowsResult.createdTasks.map((task) => task.summary).toList(),
            verifiedTasks: windowsResult.verifiedTasks
                .map((task) => task.summary)
                .toList(),
          );
        }
      }

      _startReminderTimer(
        workDays: workDays,
        defaultTime: defaultTime,
        locale: locale,
        message: message,
      );

      return ReminderSyncResult.success(
        activeReminderDays: activeDaySummaries,
        removedTasks:
            windowsResult.removedTasks.map((task) => task.summary).toList(),
        createdTasks:
            windowsResult.createdTasks.map((task) => task.summary).toList(),
        verifiedTasks:
            windowsResult.verifiedTasks.map((task) => task.summary).toList(),
      );
    } catch (e) {
      final String errorMsg = 'Failed to schedule reminders: $e';
      return ReminderSyncResult.failure(errorMessage: errorMsg);
    }
  }

  static Future<void> restoreWorklogRemindersFromPreferences(
    SettingsService settingsService,
    Locale locale,
  ) async {
    await initNotifications();

    final bool enabled = await settingsService.getReminderEnabled();
    final TimeOfDay? savedDefaultTime = await settingsService.getReminderTime();
    final String? message = await settingsService.getReminderMessage();
    final List<WorkDay> workDays = await settingsService.getWorkDays() ?? [];
    final List<_WindowsTaskInfo> desiredTasks = _buildDesiredWindowsTasks(
        workDays, savedDefaultTime ?? const TimeOfDay(hour: 9, minute: 0));

    _stopReminderTimer();

    if (!enabled || desiredTasks.isEmpty) {
      if (Platform.isWindows) {
        final _WindowsTaskMutationResult removalResult =
            await _removeWindowsTasks();
        if (!removalResult.success) {
          debugPrint(
            '[Notifications] startup task cleanup warning: ${removalResult.errorMessage}',
          );
        }
      }
      return;
    }

    if (Platform.isWindows) {
      final _WindowsTaskMutationResult result = await _scheduleWindowsTasks(
        workDays: workDays,
        defaultTime: savedDefaultTime ?? const TimeOfDay(hour: 9, minute: 0),
      );
    }

    _startReminderTimer(
      workDays: workDays,
      defaultTime: savedDefaultTime ?? const TimeOfDay(hour: 9, minute: 0),
      locale: locale,
      message: message,
    );
  }

  static Future<void> cancelAllWorklogReminders() async {
    _stopReminderTimer();

    if (Platform.isWindows) {
      await _removeWindowsTasks();
    }

    await _notifications.cancelAll();
  }

  static Future<void> clearTodayDedup() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastReminderDateKey);
    } catch (e) {
      debugPrint('[Notifications] clearTodayDedup error: $e');
    }
  }

  static Future<void> handleReminderLaunch() async {
    try {
      await initNotifications();

      final SettingsService settingsService =
          SettingsService(PreferencesService());

      final bool enabled = await settingsService.getReminderEnabled();
      if (!enabled) {
        return;
      }

      final List<WorkDay> workDays = await settingsService.getWorkDays() ?? [];
      final WorkDay? today = _getTodayWorkDay(workDays);

      if (today == null || !today.isWorking) {
        return;
      }

      final String? customMessage = await settingsService.getReminderMessage();
      final Locale locale = _systemLocale();

      await _showReminderIfNeeded(
        title: locale.languageCode == 'es' ? 'Recordatorio' : 'Reminder',
        body: (customMessage != null && customMessage.trim().isNotEmpty)
            ? customMessage.trim()
            : getDefaultReminderMessage(locale),
        locale: locale,
      );

      await Future<void>.delayed(const Duration(seconds: 5));
    } catch (e, st) {
      debugPrint('[Notifications] handleReminderLaunch error: $e\n$st');
    }
  }

  static Future<NotificationAppLaunchDetails?> getLaunchDetails() {
    return _notifications.getNotificationAppLaunchDetails();
  }

  static void _startReminderTimer({
    required List<WorkDay> workDays,
    required TimeOfDay defaultTime,
    required Locale locale,
    String? message,
  }) {
    final List<WorkDay> activeDays =
        workDays.where((d) => d.isWorking).toList();

    if (activeDays.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    final int secondsUntilNextMinute = 60 - now.second;
    final Duration firstDelay = Duration(
      seconds: secondsUntilNextMinute == 60 ? 0 : secondsUntilNextMinute,
    );

    _alignTimer = Timer(firstDelay, () async {
      await _checkInAppReminder(
        workDays: activeDays,
        defaultTime: defaultTime,
        locale: locale,
        message: message,
      );

      _reminderTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        await _checkInAppReminder(
          workDays: activeDays,
          defaultTime: defaultTime,
          locale: locale,
          message: message,
        );
      });
    });
  }

  static void _stopReminderTimer() {
    _alignTimer?.cancel();
    _alignTimer = null;

    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  static Future<void> _checkInAppReminder({
    required List<WorkDay> workDays,
    required TimeOfDay defaultTime,
    required Locale locale,
    String? message,
  }) async {
    try {
      final WorkDay? today = _getTodayWorkDay(workDays);
      if (today == null || !today.isWorking) return;

      final DateTime now = DateTime.now();
      final TimeOfDay target = today.reminderTimeOfDay ?? defaultTime;

      final int nowMinutes = now.hour * 60 + now.minute;
      final int targetMinutes = target.hour * 60 + target.minute;

      if (nowMinutes != targetMinutes) return;

      await _showReminderIfNeeded(
        title: locale.languageCode == 'es' ? 'Recordatorio' : 'Reminder',
        body: (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : getDefaultReminderMessage(locale),
        locale: locale,
      );
    } catch (e, st) {
      debugPrint('[Notifications] timer check error: $e\n$st');
    }
  }

  static Future<_WindowsTaskMutationResult> _scheduleWindowsTasks({
    required List<WorkDay> workDays,
    required TimeOfDay defaultTime,
  }) async {
    if (!Platform.isWindows) {
      return const _WindowsTaskMutationResult(success: true);
    }

    return _withSchedulerLock<_WindowsTaskMutationResult>(() async {
      final List<_WindowsTaskInfo> desiredTasks =
          _buildDesiredWindowsTasks(workDays, defaultTime);
      final List<_WindowsTaskInfo> existingTasks =
          await _queryWindowsTasksUnlocked(taskNames: _knownTaskNames);

      if (_sameTaskSet(existingTasks, desiredTasks)) {
        debugPrint('[Notifications] Windows tasks already up to date');
        return _WindowsTaskMutationResult(
          success: true,
          verifiedTasks: existingTasks,
        );
      }

      final _WindowsTaskMutationResult removalResult =
          await _removeWindowsTasksUnlocked();

      if (!removalResult.success) {
        return removalResult;
      }

      final String exePath = Platform.resolvedExecutable;
      final List<String> taskSpecs = <String>[];

      for (final _WindowsTaskInfo task in desiredTasks) {
        final String? dayName =
            _dayToPowerShell[_taskDayFromName(task.taskName)];
        if (dayName == null) {
          continue;
        }

        taskSpecs.add(
          "@{ Name='${_psSingleQuoted(task.taskName)}'; Day='$dayName'; Time='${_psSingleQuoted(task.time)}' }",
        );
      }

      final String script = [
        r'$ErrorActionPreference = "Stop"',
        "\$exePath = '${_psSingleQuoted(exePath)}'",
        "\$tasks = @(${taskSpecs.join(', ')})",
        r'$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -StartWhenAvailable',
        r'foreach ($task in $tasks) {',
        r'  $action = New-ScheduledTaskAction -Execute $exePath -Argument "--reminder"',
        r'  $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $task.Day -At $task.Time',
        r'  Register-ScheduledTask -TaskName $task.Name -Action $action -Trigger $trigger -Settings $settings -RunLevel Limited -Force | Out-Null',
        r'}',
        "Write-Output 'OK'",
      ].join('; ');

      try {
        final ProcessResult result = await _runPowerShell(script);
        final String stdout = result.stdout.toString().trim();
        final String stderr = result.stderr.toString().trim();

        if (result.exitCode != 0 || !stdout.endsWith('OK')) {
          final _WindowsTaskMutationResult rollbackResult =
              await _removeWindowsTasksUnlocked();
          final String errMsg = stderr.isNotEmpty ? stderr : 'Unknown error';
          debugPrint('[Notifications] batch task create failed: $errMsg');
          return _WindowsTaskMutationResult(
            success: false,
            errorMessage:
                'Failed to create reminder tasks: $errMsg. Rollback applied.',
            removedTasks: <_WindowsTaskInfo>[
              ...removalResult.removedTasks,
              ...rollbackResult.removedTasks,
            ],
            createdTasks: const <_WindowsTaskInfo>[],
            verifiedTasks: rollbackResult.verifiedTasks,
          );
        }

        for (final _WindowsTaskInfo task in desiredTasks) {
          debugPrint(
              '[Notifications] task created: ${task.taskName} -> ${task.summary}');
        }
      } catch (e) {
        final _WindowsTaskMutationResult rollbackResult =
            await _removeWindowsTasksUnlocked();
        debugPrint('[Notifications] batch task create exception: $e');
        return _WindowsTaskMutationResult(
          success: false,
          errorMessage:
              'Exception creating reminder tasks: $e. Rollback applied.',
          removedTasks: <_WindowsTaskInfo>[
            ...removalResult.removedTasks,
            ...rollbackResult.removedTasks,
          ],
          createdTasks: const <_WindowsTaskInfo>[],
          verifiedTasks: rollbackResult.verifiedTasks,
        );
      }

      final List<_WindowsTaskInfo> verifiedTasks =
          await _queryWindowsTasksUnlocked(taskNames: _knownTaskNames);
      final Map<String, _WindowsTaskInfo> verifiedByName =
          <String, _WindowsTaskInfo>{
        for (final _WindowsTaskInfo task in verifiedTasks) task.taskName: task,
      };

      final List<_WindowsTaskInfo> missingOrMismatched =
          desiredTasks.where((task) {
        final _WindowsTaskInfo? verified = verifiedByName[task.taskName];
        return verified == null || verified.time != task.time;
      }).toList();

      if (missingOrMismatched.isNotEmpty) {
        return _WindowsTaskMutationResult(
          success: false,
          errorMessage:
              'Windows task verification failed for: ${missingOrMismatched.map((task) => task.summary).join(', ')}',
          removedTasks: removalResult.removedTasks,
          createdTasks: desiredTasks,
          verifiedTasks: verifiedTasks,
        );
      }

      return _WindowsTaskMutationResult(
        success: true,
        removedTasks: removalResult.removedTasks,
        createdTasks: desiredTasks,
        verifiedTasks: verifiedTasks,
      );
    });
  }

  static Future<_WindowsTaskMutationResult> _removeWindowsTasks() async {
    if (!Platform.isWindows) {
      return const _WindowsTaskMutationResult(success: true);
    }

    return _withSchedulerLock<_WindowsTaskMutationResult>(
      _removeWindowsTasksUnlocked,
    );
  }

  static Future<bool> _showReminderIfNeeded({
    required String title,
    required String body,
    required Locale locale,
  }) async {
    return _withReminderLock<bool>(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String todayKey = _todayKey();

      if (prefs.getString(_lastReminderDateKey) == todayKey) {
        debugPrint('[Notifications] already shown today');
        return false;
      }

      final bool isEs = locale.languageCode == 'es';

      final NotificationDetails details = NotificationDetails(
        windows: WindowsNotificationDetails(
          audio: WindowsNotificationAudio.preset(
            sound: WindowsNotificationSound.reminder,
          ),
          duration: WindowsNotificationDuration.long,
          actions: <WindowsAction>[
            WindowsAction(
              content: isEs ? 'Abrir app' : 'Open app',
              arguments: 'open',
            ),
          ],
        ),
        macOS: const DarwinNotificationDetails(),
        linux: const LinuxNotificationDetails(),
      );

      await _notifications.show(
        _buildNotificationId(),
        title,
        body,
        details,
        payload: 'open',
      );

      await prefs.setString(_lastReminderDateKey, todayKey);
      debugPrint('[Notifications] shown -> $title');
      return true;
    });
  }

  static Future<void> _registerWindowsIntegration() async {
    try {
      final String exePath = Platform.resolvedExecutable;
      final String exeQuoted = '"$exePath"';
      const String guid = 'd49b0314-ee7a-4626-bf79-97cdb8a99a1c';

      const String aumidKey =
          'HKCU\\SOFTWARE\\Classes\\AppUserModelId\\$_appUserModelId';
      const String clsidKey = 'HKCU\\SOFTWARE\\Classes\\CLSID\\{$guid}';
      const String protocolKey = 'HKCU\\SOFTWARE\\Classes\\$_protocol';

      await _regAdd(
        key: aumidKey,
        valueName: 'DisplayName',
        valueType: 'REG_SZ',
        valueData: _appName,
      );
      await _regAdd(
        key: aumidKey,
        valueName: 'IconUri',
        valueType: 'REG_SZ',
        valueData: exePath,
      );
      await _regAdd(
        key: aumidKey,
        valueName: 'CustomActivator',
        valueType: 'REG_SZ',
        valueData: '{$guid}',
      );

      await _regAdd(
        key: '$clsidKey\\LocalServer32',
        valueName: null,
        valueType: 'REG_SZ',
        valueData: exePath,
      );

      // Protocol handler: worklogsjira://
      await _regAdd(
        key: protocolKey,
        valueName: null,
        valueType: 'REG_SZ',
        valueData: 'URL:$_appName Protocol',
      );
      await _regAdd(
        key: protocolKey,
        valueName: 'URL Protocol',
        valueType: 'REG_SZ',
        valueData: '',
      );
      await _regAdd(
        key: '$protocolKey\\shell\\open\\command',
        valueName: null,
        valueType: 'REG_SZ',
        valueData: '$exeQuoted "%1"',
      );
    } catch (e, st) {
      debugPrint('[Notifications] register integration error: $e\n$st');
    }
  }

  static Future<void> _regAdd({
    required String key,
    required String? valueName,
    required String valueType,
    required String valueData,
  }) async {
    final List<String> args = <String>[
      'add',
      key,
      if (valueName == null) '/ve' else ...<String>['/v', valueName],
      '/t',
      valueType,
      '/d',
      valueData,
      '/f',
    ];

    final ProcessResult result = await Process.run(
      'reg',
      args,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      debugPrint('[Notifications] reg add failed: ${result.stderr}');
    }
  }

  static WorkDay? _getTodayWorkDay(List<WorkDay> workDays) {
    final int today = DateTime.now().weekday;

    for (final WorkDay day in workDays) {
      if (day.day == today) return day;
    }
    return null;
  }

  static List<_WindowsTaskInfo> _buildDesiredWindowsTasks(
    List<WorkDay> workDays,
    TimeOfDay defaultTime,
  ) {
    return workDays
        .where((day) => day.isWorking)
        .map(
          (day) => _WindowsTaskInfo(
            taskName: '$_taskPrefix${day.day}',
            dayCode: _dayToSchtasks[day.day] ?? day.day.toString(),
            time: _fmtTime(day.reminderTimeOfDay ?? defaultTime),
          ),
        )
        .toList();
  }

  static List<String> getActiveReminderDaySummaries(
    List<WorkDay> workDays,
    TimeOfDay defaultTime,
  ) {
    return _buildDesiredWindowsTasks(workDays, defaultTime)
        .map((task) => task.summary)
        .toList();
  }

  static List<String> getActiveReminderDayCodes(List<WorkDay> workDays) {
    return workDays
        .where((day) => day.isWorking)
        .map((day) => _dayToSchtasks[day.day] ?? day.day.toString())
        .toList();
  }

  static Locale _systemLocale() {
    try {
      final String raw = Platform.localeName;
      final String lang = raw.split(RegExp(r'[_-]')).first.trim();
      return lang.isEmpty ? const Locale('en') : Locale(lang);
    } catch (_) {
      return const Locale('en');
    }
  }

  static String _todayKey() {
    final DateTime now = DateTime.now();
    final String y = now.year.toString();
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _fmtTime(TimeOfDay t) {
    final String h = t.hour.toString().padLeft(2, '0');
    final String m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static int _buildNotificationId() {
    return DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  }

  static String _psSingleQuoted(String value) {
    return value.replaceAll("'", "''");
  }

  static bool _sameTaskSet(
    List<_WindowsTaskInfo> current,
    List<_WindowsTaskInfo> desired,
  ) {
    if (current.length != desired.length) {
      return false;
    }

    final Map<String, String> currentByName = <String, String>{
      for (final _WindowsTaskInfo task in current) task.taskName: task.time,
    };

    for (final _WindowsTaskInfo task in desired) {
      if (currentByName[task.taskName] != task.time) {
        return false;
      }
    }

    return true;
  }

  static String getDefaultReminderMessage(Locale locale) {
    return locale.languageCode == 'es'
        ? 'Recuerda imputar las horas'
        : 'Remember to log your hours';
  }

  static List<String> get _knownTaskNames => <String>[
        _legacyTaskName,
        'WorklogsJira_Reminder',
        'WorklogsJiraReminder',
        ...List<String>.generate(7, (i) => '$_taskPrefix${i + 1}'),
        ...List<String>.generate(7, (i) => '$_taskPrefix$i'),
      ];

  static Future<ProcessResult> _runPowerShell(String script) {
    return Process.run(
      'powershell',
      <String>[
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ],
      runInShell: false,
    );
  }

  static Future<_WindowsTaskMutationResult>
      _removeWindowsTasksUnlocked() async {
    final List<_WindowsTaskInfo> beforeTasks =
        await _queryWindowsTasksUnlocked(taskNames: _knownTaskNames);

    if (beforeTasks.isEmpty) {
      return const _WindowsTaskMutationResult(success: true);
    }

    final String taskNamesQuoted =
        _knownTaskNames.map((name) => "'$name'").join(',');
    final String script =
        '@($taskNamesQuoted) | ForEach-Object { Unregister-ScheduledTask -TaskName \$_ -Confirm:\$false -ErrorAction SilentlyContinue }';

    try {
      final ProcessResult result = await _runPowerShell(script);
      if (result.exitCode != 0) {
        final String stderr = result.stderr.toString().trim();
        return _WindowsTaskMutationResult(
          success: false,
          errorMessage: stderr.isNotEmpty ? stderr : 'Unknown removal error',
          verifiedTasks: beforeTasks,
        );
      }
    } catch (e) {
      return _WindowsTaskMutationResult(
        success: false,
        errorMessage: 'Exception removing Windows tasks: $e',
        verifiedTasks: beforeTasks,
      );
    }

    final List<_WindowsTaskInfo> afterTasks =
        await _queryWindowsTasksUnlocked(taskNames: _knownTaskNames);
    final Set<String> remainingNames =
        afterTasks.map((task) => task.taskName).toSet();
    final List<_WindowsTaskInfo> removedTasks = beforeTasks
        .where((task) => !remainingNames.contains(task.taskName))
        .toList();

    if (afterTasks.isNotEmpty) {
      return _WindowsTaskMutationResult(
        success: false,
        errorMessage:
            'Some reminder tasks are still present: ${afterTasks.map((task) => task.summary).join(', ')}',
        removedTasks: removedTasks,
        verifiedTasks: afterTasks,
      );
    }

    return _WindowsTaskMutationResult(
      success: true,
      removedTasks: removedTasks,
      verifiedTasks: afterTasks,
    );
  }

  static Future<List<_WindowsTaskInfo>> _queryWindowsTasksUnlocked({
    List<String>? taskNames,
  }) async {
    const String script =
        r'$r = Get-ScheduledTask -TaskName "WorklogsJira_Reminder_*"'
        r' -ErrorAction SilentlyContinue'
        r' | ForEach-Object {'
        r' $t = @($_.Triggers | Select-Object -First 1);'
        r' [PSCustomObject]@{'
        r' TaskName = $_.TaskName;'
        r' StartBoundary = [string]$t.StartBoundary;'
        r' DaysOfWeek = (($t.DaysOfWeek | ForEach-Object { $_.ToString() }) -join ",")'
        r' }'
        r' };'
        r' if (@($r).Count -eq 0) { Write-Output "[]" }'
        r' else { $r | ConvertTo-Json -Compress }';

    try {
      final ProcessResult result = await _runPowerShell(script);
      if (result.exitCode != 0) {
        return const <_WindowsTaskInfo>[];
      }

      final String stdout = result.stdout.toString().trim();
      if (stdout.isEmpty || stdout == '[]') {
        return const <_WindowsTaskInfo>[];
      }

      final dynamic decoded = jsonDecode(stdout);
      final List<dynamic> items =
          decoded is List<dynamic> ? decoded : <dynamic>[decoded];

      return items
          .whereType<Map<String, dynamic>>()
          .map(_windowsTaskFromJson)
          .toList();
    } catch (e) {
      debugPrint('[Notifications] query tasks exception: $e');
      return const <_WindowsTaskInfo>[];
    }
  }

  static _WindowsTaskInfo _windowsTaskFromJson(Map<String, dynamic> json) {
    final String taskName = (json['TaskName'] ?? '').toString();
    final String daysOfWeek = (json['DaysOfWeek'] ?? '').toString();
    final String dayCode = _taskDayCode(taskName, daysOfWeek);
    final String startBoundary = (json['StartBoundary'] ?? '').toString();
    return _WindowsTaskInfo(
      taskName: taskName,
      dayCode: dayCode,
      time: _extractTime(startBoundary),
    );
  }

  static String _taskDayCode(String taskName, String daysOfWeek) {
    final int? taskDay = _taskDayFromName(taskName);
    if (taskDay != null) {
      return _dayToSchtasks[taskDay] ?? taskName;
    }

    final String firstDay = daysOfWeek.split(',').first.trim();
    final Map<String, String> reverseDays = <String, String>{
      'Monday': 'MON',
      'Tuesday': 'TUE',
      'Wednesday': 'WED',
      'Thursday': 'THU',
      'Friday': 'FRI',
      'Saturday': 'SAT',
      'Sunday': 'SUN',
    };
    return reverseDays[firstDay] ?? taskName;
  }

  static int? _taskDayFromName(String taskName) {
    final RegExpMatch? match =
        RegExp('$_taskPrefix(\\d+)\$').firstMatch(taskName);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  static String _extractTime(String startBoundary) {
    final RegExpMatch? match =
        RegExp(r'(\d{2}):(\d{2})').firstMatch(startBoundary);
    if (match == null) {
      return '--:--';
    }
    return '${match.group(1)}:${match.group(2)}';
  }

  static Future<T> _withSchedulerLock<T>(Future<T> Function() action) {
    return _withFileLock<T>(_schedulerLockName, action);
  }

  static Future<T> _withReminderLock<T>(Future<T> Function() action) async {
    return _withFileLock<T>(_reminderLockName, action);
  }

  static Future<T> _withFileLock<T>(
    String fileName,
    Future<T> Function() action,
  ) async {
    final File lockFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName',
    );

    if (!await lockFile.exists()) {
      await lockFile.create(recursive: true);
    }

    final RandomAccessFile raf = await lockFile.open(mode: FileMode.append);

    try {
      await raf.lock(FileLock.exclusive);
      return await action();
    } finally {
      try {
        await raf.unlock();
      } catch (_) {}
      await raf.close();
    }
  }
}
