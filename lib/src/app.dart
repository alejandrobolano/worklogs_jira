import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_controller.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_view.dart';
import 'jira/jira_controller.dart';
import 'jira/jira_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
    required this.jiraController,
    required this.dashboardController,
  });

  final SettingsController settingsController;
  final JiraController jiraController;
  final DashboardController dashboardController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'JetBrainsMono',
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              textTheme: ThemeData.dark()
                  .textTheme
                  .apply(fontFamily: 'JetBrainsMono')),
          themeMode: settingsController.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case DashboardView.routeName:
                    return DashboardView(controller: dashboardController);
                  default:
                    return JiraView(
                      controller: jiraController,
                    );
                }
              },
            );
          },
        );
      },
    );
  }
}
