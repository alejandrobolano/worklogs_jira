import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_controller.dart';
import 'package:worklogs_jira/src/jira/jira_controller.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';
import 'package:worklogs_jira/src/services/notification_service.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'package:worklogs_jira/src/settings/settings_controller.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';

import 'src/app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initNotifications();

  if (args.contains('--reminder')) {
    await NotificationService.handleReminderLaunch();
    exit(0);
  }

  final bool launchedFromProtocol =
      args.any((a) => a.startsWith('worklogsjira://'));

  final SettingsService settingsService = SettingsService(PreferencesService());

  final SettingsController settingsController =
      SettingsController(settingsService);

  final JiraController jiraController =
      JiraController(JiraService(), settingsService);

  final DashboardController dashboardController =
      DashboardController(JiraService(), settingsService);

  await settingsController.loadSettings();

  final Locale systemLocale =
      Locale(Platform.localeName.split(RegExp(r'[_-]')).first);

  await NotificationService.restoreWorklogRemindersFromPreferences(
    settingsController.settingsService,
    systemLocale,
  );

  if (Platform.isWindows) {
    final NotificationAppLaunchDetails? launchDetails =
        await NotificationService.getLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp == true ||
        launchedFromProtocol) {
      debugPrint('[Main] App launched from notification tap');
    }
  }

  runApp(
    MyApp(
      settingsController: settingsController,
      jiraController: jiraController,
      dashboardController: dashboardController,
    ),
  );
}
