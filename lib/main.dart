import 'package:flutter/material.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_controller.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'src/app.dart';
import 'src/jira/jira_controller.dart';
import 'src/jira/jira_service.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  final settingsController =
      SettingsController(SettingsService(PreferencesService()));
  final jiraController =
      JiraController(JiraService(), SettingsService(PreferencesService()));
  final dashboardController =
      DashboardController(JiraService(), SettingsService(PreferencesService()));
  await settingsController.loadSettings();

  runApp(MyApp(
    settingsController: settingsController,
    jiraController: jiraController,
    dashboardController: dashboardController,
  ));
}
