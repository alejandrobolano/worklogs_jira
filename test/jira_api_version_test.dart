import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklogs_jira/src/jira/jira_controller.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'package:worklogs_jira/src/settings/settings_controller.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';

void main() {
  test('keeps v2 for existing installs and defaults new installs to v3',
      () async {
    SharedPreferences.setMockInitialValues({'jiraPath': 'https://jira.test'});
    final existing = SettingsService(PreferencesService());
    expect(await existing.getJiraApiVersion(), 2);
    expect(await existing.getJiraPath(), 'https://jira.test/rest/api/2/');

    SharedPreferences.setMockInitialValues({});
    final fresh = SettingsService(PreferencesService());
    expect(await fresh.getJiraApiVersion(), 3);
  });

  test('sends Jira v3 worklog comments as ADF', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final responseBody = <String>[];
    final requestHandled = server.first.then((request) async {
      responseBody.add(await utf8.decoder.bind(request).join());
      request.response.statusCode = HttpStatus.created;
      await request.response.close();
    });

    await JiraService().postData(
      'http://${server.address.host}:${server.port}/rest/api/3/issue/',
      'Basic test',
      'TEST-1',
      1,
      '2026-10-01',
    );
    await requestHandled;
    await server.close();

    final body = json.decode(responseBody.single) as Map<String, dynamic>;
    expect(body['comment'], {
      'type': 'doc',
      'version': 1,
      'content': [
        {'type': 'paragraph', 'content': []}
      ]
    });
  });

  test('persists classic tokens as Basic email credentials', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SettingsService(PreferencesService());
    final controller = SettingsController(service);

    await controller.savePreferences(
      'username',
      'user@example.com',
      'classic-token',
      '',
      '',
      3,
      const [],
      false,
      const TimeOfDay(hour: 9, minute: 0),
      '',
    );

    expect(
      await service.getAuthentication(),
      'Basic ${base64Encode(utf8.encode('user@example.com:classic-token'))}',
    );
  });

  test('keeps existing authentication when token is empty', () async {
    SharedPreferences.setMockInitialValues({'basicAuth': 'Basic existing'});
    final service = SettingsService(PreferencesService());
    final controller = SettingsController(service);

    await controller.savePreferences(
      'username',
      'user@example.com',
      '',
      '',
      '',
      3,
      const [],
      false,
      const TimeOfDay(hour: 9, minute: 0),
      '',
    );

    expect(await service.getAuthentication(), 'Basic existing');
  });

  test('preserves Jira error body and headers', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SettingsService(PreferencesService());
    await service.addAuthentication('Basic test');
    await service.addJiraPath('https://jira.test');
    await service.addWorkDays([
      WorkDay(day: DateTime.thursday, hoursWorked: 8, isWorking: true),
    ]);
    final controller = JiraController(_ForbiddenJiraService(), service);

    final response = await controller.postData('TEST-1', 1, '2026-10-01', 1);

    expect(response.statusCode, 403);
    expect(response.body, '{"errorMessages":["Missing permission"]}');
    expect(response.headers['x-atlassian-trace-id'], 'trace-id');
  });
}

class _ForbiddenJiraService extends JiraService {
  @override
  Future<Response> postData(String url, String basicAuth, String issue,
      double hours, String date) async {
    return Response(
      '{"errorMessages":["Missing permission"]}',
      403,
      headers: {'x-atlassian-trace-id': 'trace-id'},
      reasonPhrase: 'Forbidden',
    );
  }
}
