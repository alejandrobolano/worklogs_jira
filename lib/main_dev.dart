import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  await dotenv.load(fileName: "assets/.env.development");

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
