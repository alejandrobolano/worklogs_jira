import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklogs_jira/src/localization/app_localizations.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'package:worklogs_jira/src/settings/settings_controller.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';
import 'package:worklogs_jira/src/settings/settings_view.dart';

final tokenField = find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == 'Token',
);

Finder saveButton(Finder field) => find.descendant(
      of: field,
      matching: find.widgetWithIcon(IconButton, Icons.save_outlined),
    );

Finder savedCheck(Finder field) => find.descendant(
      of: field,
      matching: find.byIcon(Icons.check_circle),
    );

Future<_TestSettingsController> openSettings(WidgetTester tester,
    {String? authentication}) async {
  SharedPreferences.setMockInitialValues({
    'email': 'user@example.com',
    'jiraPath': 'https://jira.test',
    if (authentication != null) 'basicAuth': authentication,
  });
  PackageInfo.setMockInitialValues(
    appName: 'Worklogs Jira',
    packageName: 'worklogs_jira',
    version: '2.9.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final controller =
      _TestSettingsController(SettingsService(PreferencesService()));
  await controller.loadSettings();
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('es')],
    home: SettingsView(controller: controller),
  ));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('keeps saved check after masking and saving another field',
      (tester) async {
    final controller = await openSettings(tester);
    await tester.enterText(tokenField, 'test-token');
    await tester.tap(saveButton(tokenField));
    await tester.pumpAndSettle();

    expect(savedCheck(tokenField), findsOneWidget);
    expect(tester.widget<TextField>(tokenField).controller!.text,
        '***************');
    expect(tester.widget<IconButton>(saveButton(tokenField)).onPressed, isNull);
    final expectedAuth =
        'Basic ${base64Encode(utf8.encode('user@example.com:test-token'))}';
    expect(await controller.getAuthentication(), expectedAuth);

    final emailField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.keyboardType == TextInputType.emailAddress);
    await tester.tap(saveButton(emailField));
    await tester.pumpAndSettle();

    expect(controller.submittedTokens, ['test-token', '']);
    expect(await controller.getAuthentication(), expectedAuth);
    expect(savedCheck(tokenField), findsOneWidget);
  });

  testWidgets('blocks repeated saves while token save is pending',
      (tester) async {
    final controller = await openSettings(tester);
    controller.pendingSave = Completer<void>();
    await tester.enterText(tokenField, 'test-token');
    await tester.tap(saveButton(tokenField));
    await tester.pump();

    expect(tester.widget<IconButton>(saveButton(tokenField)).onPressed, isNull);
    expect(tester.widget<TextField>(tokenField).readOnly, isTrue);
    await tester.tap(saveButton(tokenField));
    expect(controller.submittedTokens, ['test-token']);

    controller.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(savedCheck(tokenField), findsOneWidget);
  });

  testWidgets('saving another field never submits an unsaved token',
      (tester) async {
    final controller =
        await openSettings(tester, authentication: 'Basic existing');
    await tester.tap(tokenField);
    await tester.enterText(tokenField, 'unsaved-token');
    final emailField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.keyboardType == TextInputType.emailAddress);
    await tester.tap(saveButton(emailField));
    await tester.pumpAndSettle();

    expect(controller.submittedTokens, ['']);
    expect(await controller.getAuthentication(), 'Basic existing');
    expect(savedCheck(tokenField), findsNothing);
  });
}

class _TestSettingsController extends SettingsController {
  _TestSettingsController(super.settingsService);

  final submittedTokens = <String>[];
  Completer<void>? pendingSave;

  @override
  Future<List<String>> getUserProjects() async => [];

  @override
  Future<void> savePreferences(
      String username,
      String email,
      String token,
      String issuePreffix,
      String jiraPath,
      int jiraApiVersion,
      List<WorkDay> workDays,
      bool reminderEnabled,
      TimeOfDay reminderTime,
      String reminderMessage) async {
    submittedTokens.add(token);
    if (pendingSave != null) await pendingSave!.future;
    await super.savePreferences(
        username,
        email,
        token,
        issuePreffix,
        jiraPath,
        jiraApiVersion,
        workDays,
        reminderEnabled,
        reminderTime,
        reminderMessage);
  }
}
