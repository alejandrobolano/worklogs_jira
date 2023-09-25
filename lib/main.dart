import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';

import 'config/app_config.dart';
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
  await settingsController.loadSettings();

  await dotenv.load(fileName: "assets/.env.production");

  var configuredApp = AppConfig.getInstance(
      flavorName: dotenv.env['FLAVOR_NAME'].toString(),
      apiBaseUrl: dotenv.env['API_URL'].toString(),
      debug: bool.parse(dotenv.env['DEBUG'].toString()),
      child: MyApp(
        settingsController: settingsController,
        jiraController: jiraController,
      ));
  runApp(configuredApp);
}
