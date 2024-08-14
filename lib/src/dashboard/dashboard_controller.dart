import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';

class DashboardController with ChangeNotifier {
  DashboardController(this._jiraService, this._settingsService);
  final JiraService _jiraService;
  final SettingsService _settingsService;

  Future<Response> getWorklist(String startRange, String finishRange) async {
    final url = await _settingsService.getJiraBasePath();
    if (url == "") {
      return Future<Response>(
        () => Response('Error: Jira URL not found', 400,
            reasonPhrase: "Jira URL not found"),
      );
    }
    final basicAuth = await _settingsService.getAuthentication();
    String? email = await _settingsService.getEmail();
    if (basicAuth == null || basicAuth == "") {
      return Future<Response>(
        () => Response('Error: Basic Auth not found', 400,
            reasonPhrase: "Basic auth not found"),
      );
    }
    if (email == null || basicAuth == "") {
      return Future<Response>(
        () => Response(
            'Error: Email not found. You should save username and password again',
            400,
            reasonPhrase:
                "Email not found. You should save username and password again"),
      );
    }

    String jqlQuery =
        'worklogDate >= "$startRange" AND worklogDate <= "$finishRange" AND worklogAuthor = "$email"';
    String finalUrl = '${url!}/search?jql=${Uri.encodeComponent(jqlQuery)}';

    return _jiraService.getData(finalUrl, basicAuth);
  }

  bool isOkStatusCode(statusCode) {
    return statusCode == 200 || statusCode == 201 || statusCode == 204;
  }

  Future<List<int>> getNotWorkedDays() {
    return _settingsService.getNotWorkedDays();
  }

  Future<String?> getJiraBasePath() async {
    return _settingsService.getJiraBasePath();
  }
}
