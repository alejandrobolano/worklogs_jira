import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_controller.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_view.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';
import 'package:worklogs_jira/src/localization/app_localizations.dart';
import 'package:worklogs_jira/src/models/worklist_response.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';

Map<String, dynamic> issue(String key) => {
      'id': '10002',
      'key': key,
      'fields': {
        'summary': 'Trabajo completado',
        'timespent': 3600,
        'issuetype': {'name': 'Task'},
        'project': {'name': 'Proyecto'},
        'status': {'name': 'Done'},
        'assignee': {'displayName': 'Test User'},
      },
    };

Response page(List<Map<String, dynamic>> issues,
        {bool? isLast, String? nextPageToken}) =>
    Response(
        jsonEncode({
          'issues': issues,
          if (isLast != null) 'isLast': isLast,
          if (nextPageToken != null) 'nextPageToken': nextPageToken,
        }),
        200);

DashboardController controllerFor(_SearchService service, {int version = 3}) {
  SharedPreferences.setMockInitialValues({
    'jiraPath': 'https://jira.test',
    'jiraApiVersion': '$version',
    'email': 'user@example.com',
    'basicAuth': 'Basic test',
  });
  return DashboardController(service, SettingsService(PreferencesService()));
}

void main() {
  test('requests fields and combines all enhanced v3 search pages', () async {
    final service = _SearchService([
      page([issue('TEST-1')], isLast: false, nextPageToken: 'next+/='),
      page([issue('TEST-2')], isLast: true),
    ]);
    final controller = controllerFor(service);
    final response = await controller.getWorklist('2026-10-01', '2026-10-02');
    final result = WorklistResponse.fromJson(jsonDecode(response.body));

    expect(result.issues!.map((item) => item!.key), ['TEST-1', 'TEST-2']);
    expect(result.issues!.first!.fields!.summary, 'Trabajo completado');
    expect(service.urls.first.path, '/rest/api/3/search/jql');
    expect(service.urls.first.queryParameters['jql'],
        'worklogDate >= "2026-10-01" AND worklogDate <= "2026-10-02" AND worklogAuthor = "user@example.com"');
    expect(
        service.urls.first.queryParameters['fields']!.split(','),
        containsAll([
          'key',
          'summary',
          'timespent',
          'issuetype',
          'project',
          'subtasks',
          'assignee',
          'status'
        ]));
    expect(
        service.urls.first.queryParameters.containsKey('nextPageToken'), false);
    expect(service.urls.last.queryParameters['nextPageToken'], 'next+/=');
    expect(jsonDecode(response.body)['isLast'], true);
    expect(jsonDecode(response.body).containsKey('nextPageToken'), false);
  });

  test('keeps legacy v2 search response and endpoint', () async {
    final legacy = Response(
        jsonEncode({
          'startAt': 0,
          'maxResults': 50,
          'total': 1,
          'issues': [issue('TEST-1')],
        }),
        200);
    final service = _SearchService([legacy]);
    final response = await controllerFor(service, version: 2)
        .getWorklist('2026-10-01', '2026-10-02');

    expect(response, same(legacy));
    expect(service.urls.single.path, '/rest/api/2/search');
    expect(WorklistResponse.fromJson(jsonDecode(response.body)).total, 1);
  });

  test('falls back to enhanced v2 search when Cloud returns 410', () async {
    final service = _SearchService([
      Response('Removed endpoint', 410),
      page([issue('TEST-1')], isLast: false, nextPageToken: 'next'),
      page([issue('TEST-2')], isLast: true),
    ]);
    final response = await controllerFor(service, version: 2)
        .getWorklist('2026-10-01', '2026-10-02');

    expect(service.urls.map((url) => url.path), [
      '/rest/api/2/search',
      '/rest/api/2/search/jql',
      '/rest/api/2/search/jql',
    ]);
    expect(WorklistResponse.fromJson(jsonDecode(response.body)).issues,
        hasLength(2));
  });

  test('returns empty enhanced results without extra requests', () async {
    final service = _SearchService([page([], isLast: true)]);
    final response =
        await controllerFor(service).getWorklist('2026-10-01', '2026-10-02');
    expect(
        WorklistResponse.fromJson(jsonDecode(response.body)).issues, isEmpty);
    expect(service.urls, hasLength(1));
  });

  test('preserves errors from a subsequent page instead of partial success',
      () async {
    final error = Response('{"errorMessages":["Missing permission"]}', 403,
        headers: {'x-atlassian-trace-id': 'trace-id'});
    final service = _SearchService([
      page([issue('TEST-1')], isLast: false, nextPageToken: 'next'),
      error,
    ]);
    final response =
        await controllerFor(service).getWorklist('2026-10-01', '2026-10-02');
    expect(response, same(error));
  });

  test('rejects repeated page tokens rather than looping forever', () async {
    final service = _SearchService([
      page([issue('TEST-1')], isLast: false, nextPageToken: 'same'),
      page([issue('TEST-2')], isLast: false, nextPageToken: 'same'),
    ]);
    await expectLater(
        controllerFor(service).getWorklist('2026-10-01', '2026-10-02'),
        throwsFormatException);
    expect(service.urls, hasLength(2));
  });

  test('reads timeSpentSeconds when only timetracking is present', () {
    final fields = Fields.fromJson({
      'timetracking': {'timeSpentSeconds': 400},
    });
    expect(fields.timespent, 400);
    expect(
        Fields.fromJson({
          'timespent': 0,
          'timetracking': {'timeSpentSeconds': 400},
        }).timespent,
        0);
  });

  testWidgets('renders enhanced results in dashboard list and table',
      (tester) async {
    final service = _SearchService([
      page([issue('TEST-1')], isLast: true)
    ]);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: DashboardView(controller: controllerFor(service)),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.update));
    await tester.pumpAndSettle();

    expect(find.text('TEST-1'), findsOneWidget);
    expect(find.text('Proyecto | 1.0 h'), findsOneWidget);
    await tester.tap(find.text('TEST-1'));
    await tester.pumpAndSettle();
    expect(find.text('Trabajo completado'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.text('Trabajo completado'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tabla'));
    await tester.pumpAndSettle();
    expect(find.text('Trabajo completado'), findsOneWidget);
    expect(find.text('TEST-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SearchService extends JiraService {
  _SearchService(this.responses);

  final List<Response> responses;
  final urls = <Uri>[];

  @override
  Future<Response> getData(String url, String basicAuth) async {
    final uri = Uri.parse(url);
    if (uri.path.endsWith('/worklog')) {
      return Response(
          jsonEncode({
            'worklogs': [
              {
                'started': '2026-10-01T10:00:00.000+0200',
                'timeSpentSeconds': 3600
              },
            ],
          }),
          200);
    }
    urls.add(uri);
    return responses[urls.length - 1];
  }
}
