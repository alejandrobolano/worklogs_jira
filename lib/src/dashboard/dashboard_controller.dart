import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';

class DashboardController with ChangeNotifier {
  DashboardController(this._jiraService, this._settingsService);
  final JiraService _jiraService;
  final SettingsService _settingsService;

  Future<Response> getWorklist(String startRange, String finisRange) async {
    final url = await _settingsService.getJiraPath();
    if (url == "") {
      return Future<Response>(
        () => Response('Error: Jira URL not found', 400,
            reasonPhrase: "Jira URL not found"),
      );
    }
    final basicAuth = await _settingsService.getBasicAuth();
    String? username = await _settingsService.getUsername();
    if (basicAuth == null || basicAuth == "") {
      return Future<Response>(
        () => Response('Error: Basic Auth not found', 400,
            reasonPhrase: "Basic auth not found"),
      );
    }
    if (username == null || basicAuth == "") {
      return Future<Response>(
        () => Response(
            'Error: Username not found. You should save username and password again',
            400,
            reasonPhrase:
                "Username not found. You should save username and password again"),
      );
    }

    String startRangeEncode = Uri.encodeComponent(' >="$startRange" ');
    String finishRangeEncode = Uri.encodeComponent(' <="$finisRange" ');

    String query =
        '/search?jql=worklogAuthor=$username%20AND%20worklogDate$startRangeEncode%20AND%20worklogDate$finishRangeEncode';
    final String finalrUrl = '$url$query';
    return _jiraService.getData(finalrUrl, basicAuth);
  }

  bool isOkStatusCode(statusCode) {
    return statusCode == 200 || statusCode == 201 || statusCode == 204;
  }
}
