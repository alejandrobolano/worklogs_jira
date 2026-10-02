import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';
import 'package:worklogs_jira/src/settings/settings_service.dart';

class DashboardController with ChangeNotifier {
  DashboardController(this._jiraService, this._settingsService);
  final JiraService _jiraService;
  final SettingsService _settingsService;

  Future<Response> getWorklist(String startRange, String finishRange) async {
    final url = await _settingsService.getJiraPath();
    if (url == null || url.isEmpty) {
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
    if (email == null || email.isEmpty) {
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
    final apiVersion = await _settingsService.getJiraApiVersion();
    var enhancedSearch = apiVersion == 3;
    final query = {
      'jql': jqlQuery,
      'fields':
          'key,summary,timespent,timetracking,issuetype,project,subtasks,assignee,status',
      'maxResults': '100',
    };
    var uri = Uri.parse('${url}${enhancedSearch ? 'search/jql' : 'search'}')
        .replace(queryParameters: query);
    var response = await _jiraService.getData(uri.toString(), basicAuth);

    // Keep Jira Server/Data Center v2 compatible; Cloud removed legacy search.
    if (!enhancedSearch && response.statusCode == 410) {
      enhancedSearch = true;
      uri = Uri.parse('${url}search/jql').replace(queryParameters: query);
      response = await _jiraService.getData(uri.toString(), basicAuth);
    }
    if (!enhancedSearch) return response;

    final issues = <dynamic>[];
    final seenTokens = <String>{};
    while (true) {
      if (!isOkStatusCode(response.statusCode)) return response;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      issues.addAll(data['issues'] as List<dynamic>? ?? []);
      final nextPageToken = data['nextPageToken'] as String?;
      if (data['isLast'] == true ||
          nextPageToken == null ||
          nextPageToken.isEmpty) {
        data['issues'] = issues;
        data['isLast'] = true;
        data.remove('nextPageToken');
        return Response.bytes(
            utf8.encode(jsonEncode(data)), response.statusCode,
            headers: {
              ...response.headers,
              'content-type': 'application/json; charset=utf-8',
            },
            reasonPhrase: response.reasonPhrase);
      }
      if (!seenTokens.add(nextPageToken)) {
        throw const FormatException('Repeated Jira search page token');
      }
      uri = uri.replace(queryParameters: {
        ...query,
        'nextPageToken': nextPageToken,
      });
      response = await _jiraService.getData(uri.toString(), basicAuth);
    }
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

  Future<Response> getIssueWorklogs(String issueKey) async {
    final url = await _settingsService.getJiraPath();
    final basicAuth = await _settingsService.getAuthentication();
    if (url == "" || basicAuth == null || basicAuth == "") {
      return Future<Response>(
        () => Response('Error: Configuration not found', 400),
      );
    }
    String finalUrl = '${url!}issue/$issueKey/worklog';
    return _jiraService.getData(finalUrl, basicAuth);
  }
}
