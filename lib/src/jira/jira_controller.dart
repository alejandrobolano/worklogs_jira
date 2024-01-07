import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../settings/settings_service.dart';
import 'jira_service.dart';
import 'package:intl/intl.dart';

class JiraController with ChangeNotifier {
  JiraController(this._jiraService, this._settingsService);
  final JiraService _jiraService;
  final SettingsService _settingsService;

  Future<String?> getIssuePreffix() async {
    final issuePreffix = await _settingsService.getIssuePreffix();
    return issuePreffix;
  }

  Future<String?> getLastIssue() async {
    return await _settingsService.getLastIssue();
  }

  void setLastIssue(String lastIssue) async {
    await _settingsService.addLastIssue(lastIssue.toUpperCase());
  }

  Future<Response> getData(String issue) async {
    final url = await _getJiraPath();
    final basicAuth = await _getBasicAuth();

    if (url == "") {
      return _buildErrorResponse(
          'Error: Jira URL not found', 400, "Jira URL not found");
    }

    if (basicAuth == "") {
      return _buildErrorResponse(
          'Error: Basic Auth not found', 400, "Basic auth not found");
    }

    final String finalUrl = '$url$issue/worklog';
    return _jiraService.getData(finalUrl, basicAuth);
  }

  Future<Response> postData(
      String issue, double hours, String startDate, int repetitions) async {
    final url = await _getJiraPath();
    final basicAuth = await _getBasicAuth();

    if (url == "") {
      return _buildErrorResponse(
          'Error: Jira URL not found', 400, "Jira URL not found");
    }

    if (basicAuth == "") {
      return _buildErrorResponse(
          'Error: Basic Auth not found', 400, "Basic auth not found");
    }

    final repetitionsArray = [];

    for (int i = 0; i < repetitions; i++) {
      repetitionsArray.add(i);
    }

    double hoursCorrectly;
    bool isPlusDays = false;
    for (var index in repetitionsArray) {
      hoursCorrectly = hours;
      final dateTime = DateTime.parse(startDate);
      var daysSum = isPlusDays ? 2 + index : index;
      var date = dateTime.add(Duration(days: daysSum));
      if (date.weekday == DateTime.saturday) {
        date = date.add(const Duration(days: 2));
        isPlusDays = true;
      } else if (date.weekday == DateTime.friday && hours > 7) {
        hoursCorrectly = 7;
      }

      final response = await _jiraService.postData(url!, basicAuth, issue,
          hoursCorrectly, DateFormat('yyyy-MM-dd').format(date));
      if (!isOkStatusCode(response.statusCode)) {
        return Future<Response>(
          () => Response('Error: ${response.body}', response.statusCode,
              reasonPhrase: response.reasonPhrase),
        );
      }
    }

    return Future<Response>(
      () => Response('Successful request for $repetitions repetitions', 201),
    );
  }

  bool isOkStatusCode(statusCode) {
    return statusCode == 200 || statusCode == 201 || statusCode == 204;
  }

  Future<Response> deleteData(String id, String issueId) async {
    final url = await _getJiraPath();
    final basicAuth = await _getBasicAuth();

    if (url == "") {
      return _buildErrorResponse(
          'Error: Jira URL not found', 400, "Jira URL not found");
    }

    if (basicAuth == "") {
      return _buildErrorResponse(
          'Error: Basic Auth not found', 400, "Basic auth not found");
    }
    return _jiraService.deleteData(url!, basicAuth, id, issueId);
  }

  Future<String?> _getJiraPath() async {
    final url = await _settingsService.getJiraPath();
    return url != null && url.isNotEmpty ? "${url}issue/" : "";
  }

  Future<String> _getBasicAuth() async {
    final basicAuth = await _settingsService.getAuthentication();
    return basicAuth ?? "";
  }

  Response _buildErrorResponse(
      String message, int statusCode, String reasonPhrase) {
    return Response(message, statusCode, reasonPhrase: reasonPhrase);
  }
}
