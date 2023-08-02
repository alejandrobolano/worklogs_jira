import 'config/app_config.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/jira/jira_controller.dart';
import 'src/jira/jira_service.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

Future<void> main() async {
  final settingsController = SettingsController(SettingsService());
  final jiraController = JiraController(JiraService(), SettingsService());
  await settingsController.loadSettings();

  var configuredApp = AppConfig.getInstance(
      appName: 'Development',
      flavorName: 'development',
      apiBaseUrl: '###',
      apiEndpointUrl: '/rest/api/2/issue/',
      child: MyApp(
        settingsController: settingsController,
        jiraController: jiraController,
      ));

  runApp(configuredApp);
}
