import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_controller.dart';
import 'package:worklogs_jira/src/dashboard/logged_tasks_table.dart';
import 'package:worklogs_jira/src/jira/jira_controller.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';
import 'package:worklogs_jira/src/jira/jira_view.dart';
import 'package:worklogs_jira/src/jira/worklog_list/worklog_list_view.dart';
import 'package:worklogs_jira/src/localization/app_localizations.dart';
import 'package:worklogs_jira/src/models/common_response.dart';
import 'package:worklogs_jira/src/models/daily_task.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
import 'package:worklogs_jira/src/models/worklist_response.dart';
import 'package:worklogs_jira/src/models/worklog_response.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';

Future<SettingsService> settings(int version, {List<WorkDay>? days}) async {
  SharedPreferences.setMockInitialValues({
    'jiraPath': 'https://jira.test',
    'basicAuth': 'Basic test',
    'email': 'user@example.com',
    'jiraApiVersion': '$version',
  });
  final service = SettingsService(PreferencesService());
  await service.addWorkDays(days ??
      List.generate(
          7,
          (i) => WorkDay(
              day: i + 1, hoursWorked: i == 4 ? 7 : 8.5, isWorking: i < 5)));
  return service;
}

Response offsetPage(String key, int start, int total, List<dynamic> items) =>
    Response(
        jsonEncode({
          'startAt': start,
          'maxResults': items.length,
          'total': total,
          key: items,
        }),
        200);

Widget app(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: Scaffold(body: child),
    );

void main() {
  for (final version in [2, 3]) {
    for (final dashboard in [false, true]) {
      test(
          'loads all worklogs via ${dashboard ? 'dashboard' : 'Jira'} v$version',
          () async {
        final service = _FlowService([
          offsetPage('worklogs', 0, 2, [
            {'id': '1'}
          ]),
          offsetPage('worklogs', 1, 2, [
            {'id': '2'}
          ]),
        ]);
        final prefs = await settings(version);
        final response = dashboard
            ? await DashboardController(service, prefs)
                .getIssueWorklogs('TEST-1')
            : await JiraController(service, prefs).getData('TEST-1');
        final body = jsonDecode(response.body);
        expect(body['worklogs'], [
          {'id': '1'},
          {'id': '2'}
        ]);
        expect(body['startAt'], 0);
        expect(body['maxResults'], 2);
        expect(
            service.urls.first.path, '/rest/api/$version/issue/TEST-1/worklog');
        expect(service.urls.last.queryParameters['startAt'], '1');
        expect(service.urls.last.queryParameters.containsKey('nextPageToken'),
            false);
      });
    }
  }

  test('legacy v2 dashboard search loads all offset pages', () async {
    final service = _FlowService([
      offsetPage('issues', 0, 2, [
        {'id': '1', 'key': 'TEST-1'}
      ]),
      offsetPage('issues', 1, 2, [
        {'id': '2', 'key': 'TEST-2'}
      ]),
    ]);
    final response = await DashboardController(service, await settings(2))
        .getWorklist('2026-10-01', '2026-10-02');
    expect(jsonDecode(response.body)['issues'], hasLength(2));
    expect(service.urls.last.queryParameters['startAt'], '1');
    expect(service.urls.last.queryParameters['fields'], isNotEmpty);
  });

  test('worklog pagination preserves a later HTTP error', () async {
    final error = Response('{"errorMessages":["Forbidden"]}', 403);
    final service = _FlowService([
      offsetPage('worklogs', 0, 2, [
        {'id': '1'}
      ]),
      error,
    ]);
    final response =
        await JiraController(service, await settings(3)).getData('TEST-1');
    expect(response, same(error));
  });

  test('worklog pagination rejects pages that do not advance', () async {
    final service = _FlowService([
      offsetPage('worklogs', 0, 2, []),
    ]);
    await expectLater(
        JiraController(service, await settings(3)).getData('TEST-1'),
        throwsFormatException);
  });

  test('repetitions cap Friday independently and skip weekend', () async {
    final service = _FlowService([]);
    final controller = JiraController(service, await settings(3));
    expect(
        (await controller.postData('TEST-1', 8.5, '2026-10-02', 3)).statusCode,
        201);
    expect(service.posts.map((post) => post['hours']), [7, 8.5, 8.5]);
    expect(service.posts.map((post) => post['date']),
        ['2026-10-02', '2026-10-05', '2026-10-06']);
    expect(await controller.calculateLastLoggedDate('2026-10-02', 3),
        '2026-10-06');
  });

  test('no working days returns an error without recursion or posting',
      () async {
    final service = _FlowService([]);
    final controller = JiraController(
        service,
        await settings(3, days: [
          WorkDay(day: 1, hoursWorked: 0, isWorking: false),
        ]));
    expect((await controller.postData('TEST-1', 8, '2026-10-02', 1)).statusCode,
        402);
    expect(service.posts, isEmpty);
  });

  test('invalid durations and repetitions never create worklogs', () async {
    final service = _FlowService([]);
    final controller = JiraController(service, await settings(3));
    for (final hours in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
          (await controller.postData('TEST-1', hours, '2026-10-02', 1))
              .statusCode,
          400);
    }
    expect((await controller.postData('TEST-1', 8, '2026-10-02', 0)).statusCode,
        400);
    expect(service.posts, isEmpty);
  });

  test('multitask failure keeps only pending tasks for retry', () async {
    final service = _FlowService([],
        postResponses: [Response('', 201), Response('Forbidden', 403)]);
    final controller = JiraController(service, await settings(3));
    final response = await controller.postMultipleTasksForDay('2026-10-02', [
      DailyTask(issue: 'TEST-1', hours: 8.5),
      DailyTask(issue: 'TEST-2', hours: 1.25),
    ]);
    expect(response.statusCode, 403);
    final pending = await controller.getDraftTasks();
    expect(pending.map((task) => task.issue), ['TEST-2']);
    final retried =
        await controller.postMultipleTasksForDay('2026-10-02', pending);
    expect(retried.statusCode, 201);
    expect(retried.body, 'Successful request for 1 tasks');
    expect(service.posts.map((post) => post['issue']),
        ['TEST-1', 'TEST-2', 'TEST-2']);
    expect(service.posts.first['hours'], 8.5);
    expect(await controller.getDraftTasks(), isEmpty);
  });

  test('validates every multitask before posting any of them', () async {
    final service = _FlowService([]);
    final controller = JiraController(service, await settings(3));
    expect(
        (await controller.postMultipleTasksForDay('2026-10-02', [
          DailyTask(issue: 'TEST-1', hours: 1),
          DailyTask(issue: 'TEST-2', hours: -1),
        ]))
            .statusCode,
        400);
    expect(service.posts, isEmpty);
  });

  testWidgets(
      'worklog list handles one-word and missing authors without avatars',
      (tester) async {
    Worklog? deleted;
    final worklog =
        Worklog(id: '1', issueId: '10', author: Author(displayName: 'Alex'));
    await tester.pumpWidget(app(WorklogListView(
      worklogResponse:
          WorklogResponse(worklogs: [worklog, Worklog(id: '2', issueId: '10')]),
      onDeleteData: (value) => deleted = value,
    )));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    expect(deleted, same(worklog));
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'table filters calendar dates, tolerates missing summary and clears empty results',
      (tester) async {
    final issues = [Issues(key: 'TEST-1', fields: Fields())];
    Future<Map<String, dynamic>> load(String key) async => {
          'worklogs': [
            {
              'started': '2026-09-30T10:00:00.000+0200',
              'timeSpentSeconds': 3600
            },
            {
              'started': '2026-10-01T00:30:00.000+0200',
              'timeSpentSeconds': 900
            },
            {
              'started': '2026-10-02T10:00:00.000+0200',
              'timeSpentSeconds': 7200
            },
          ],
        };
    await tester.pumpWidget(app(LoggedTasksTable(
      issues: issues,
      onTaskTap: (_) {},
      getWorklogsCallback: load,
      startRange: '2026-10-01',
      finishRange: '2026-10-01',
    )));
    await tester.pumpAndSettle();
    expect(find.text('01/10/2026'), findsOneWidget);
    expect(find.text('30/09/2026'), findsNothing);
    expect(find.text('02/10/2026'), findsNothing);
    expect(find.text('0.25h'), findsNWidgets(2));
    await tester.pumpWidget(app(LoggedTasksTable(
      issues: const [],
      onTaskTap: (_) {},
      getWorklogsCallback: load,
    )));
    await tester.pumpAndSettle();
    expect(find.text('TEST-1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('worklog details scroll on small screens with long comments',
      (tester) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final comment =
        List.filled(40, 'Comentario largo de trabajo registrado').join('\n');
    await tester.pumpWidget(app(WorklogListView(
      worklogResponse: WorklogResponse(worklogs: [
        Worklog(
          id: '1',
          issueId: '10',
          author: Author(displayName: 'Alex'),
          timeSpent: '1d 30m',
          timeSpentSeconds: 30600,
          comment: comment,
          created: DateTime(2026, 10, 2),
          updated: DateTime(2026, 10, 2),
          started: DateTime(2026, 10, 1),
        ),
      ]),
      onDeleteData: (_) {},
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final avatar = find.byWidgetPredicate(
        (widget) => widget is CircleAvatar && widget.radius == 32);
    expect(tester.getSize(avatar), const Size(64, 64));
    expect(tester.takeException(), isNull);
    final updatedTile = find.ancestor(
      of: find.byIcon(Icons.calendar_today_outlined).last,
      matching: find.byType(ListTile),
    );
    await tester.ensureVisible(updatedTile);
    await tester.pumpAndSettle();
    expect(tester.getRect(updatedTile).bottom, lessThanOrEqualTo(480));
    expect(tester.takeException(), isNull);
  });

  testWidgets('table ignores stale worklog responses after refresh',
      (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    Future<Map<String, dynamic>> load(String key) =>
        key == 'OLD-1' ? pending.future : Future.value({'worklogs': []});
    await tester.pumpWidget(app(LoggedTasksTable(
      issues: [Issues(key: 'OLD-1')],
      onTaskTap: (_) {},
      getWorklogsCallback: load,
    )));
    await tester.pump();
    await tester.pumpWidget(app(LoggedTasksTable(
      issues: [Issues(key: 'NEW-1')],
      onTaskTap: (_) {},
      getWorklogsCallback: load,
    )));
    await tester.pumpAndSettle();
    pending.complete({
      'worklogs': [
        {'started': '2026-10-01T08:00:00.000+0000', 'timeSpentSeconds': 3600},
      ]
    });
    await tester.pumpAndSettle();
    expect(find.text('OLD-1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'load and delete errors release UI for retry and successful delete refreshes',
      (tester) async {
    final controller = _ViewController(await settings(3));
    await tester.pumpWidget(app(JiraView(controller: controller)));
    await tester.pumpAndSettle();
    final issueField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.keyboardType == TextInputType.text);
    await tester.enterText(issueField, 'TEST-1');

    Future<void> load() async {
      ScaffoldMessenger.of(tester.element(find.byType(JiraView)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
    }

    await load();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await load();
    expect(find.text('Alex'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Alex'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsNothing);
    expect(controller.deletions, 2);
    expect(controller.loads, 3);
    expect(tester.takeException(), isNull);
  });
}

class _ViewController extends JiraController {
  _ViewController(SettingsService settings) : super(_FlowService([]), settings);
  int loads = 0;
  int deletions = 0;

  @override
  Future<bool> getOnboardingSeen() async => true;

  @override
  Future<Response> getData(String issue) async {
    loads++;
    if (loads == 1) throw StateError('Simulated load failure');
    return Response(
        jsonEncode({
          'worklogs': loads == 2
              ? [
                  {
                    'id': '1',
                    'issueId': '10',
                    'author': {'displayName': 'Alex'},
                    'timeSpent': '8h 30m',
                    'timeSpentSeconds': 30600,
                    'created': '2026-10-02T08:00:00.000+0000',
                    'updated': '2026-10-02T08:00:00.000+0000',
                    'started': '2026-10-02T08:00:00.000+0000',
                  },
                ]
              : []
        }),
        200);
  }

  @override
  Future<Response> deleteData(String id, String issueId) async {
    expect(id, '1');
    expect(issueId, '10');
    deletions++;
    if (deletions == 1) throw StateError('Simulated delete failure');
    return Response('', 204);
  }
}

class _FlowService extends JiraService {
  _FlowService(this.responses, {List<Response>? postResponses})
      : postResponses = postResponses ?? [];
  final List<Response> responses;
  final List<Response> postResponses;
  final urls = <Uri>[];
  final posts = <Map<String, dynamic>>[];

  @override
  Future<Response> getData(String url, String basicAuth) async {
    urls.add(Uri.parse(url));
    return responses.removeAt(0);
  }

  @override
  Future<Response> postData(String url, String basicAuth, String issue,
      double hours, String date) async {
    posts.add({'issue': issue, 'hours': hours, 'date': date});
    return postResponses.isEmpty
        ? Response('', 201)
        : postResponses.removeAt(0);
  }
}
