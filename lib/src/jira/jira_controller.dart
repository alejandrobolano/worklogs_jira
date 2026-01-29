import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
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

  Future<String?> getLastLoggedDate() async {
    return await _settingsService.getLastLoggedDate();
  }

  void setLastLoggedDate(String lastLoggedDate) async {
    await _settingsService.addLastLoggedDate(lastLoggedDate);
  }

  Future<Response> getData(String issue) async {
    final url = await _getJiraPath();
    final authentication = await _getAuthentication();

    if (url == "") {
      return _buildErrorResponse(
          'Error: Jira URL not found', 400, "Jira URL not found");
    }

    if (authentication == "") {
      return _buildErrorResponse(
          'Error: Basic Auth not found', 400, "Basic auth not found");
    }

    final String finalUrl = '$url$issue/worklog';
    return _jiraService.getData(finalUrl, authentication);
  }

  Future<Response> postData(
      String issue, double hours, String startDate, int repetitions) async {
    final url = await _getJiraPath();
    final basicAuth = await _getAuthentication();

    if (url == "") {
      return _buildErrorResponse(
          'Error: Jira URL not found', 400, "Jira URL not found");
    }

    if (basicAuth == "") {
      return _buildErrorResponse(
          'Error: Basic Auth not found', 400, "Basic auth not found");
    }

    final repetitionsArray = _buildRepetitionsArray(repetitions);
    List<WorkDay> workDays = await _getWorkDays() ?? [];

    if (workDays.isEmpty) {
      return _buildErrorResponse('Error: You must edit hours in settings', 402,
          "You must edit hours in settings");
    }

    double updatedHours;
    var dateTime = DateTime.parse(startDate);
    for (var _ in repetitionsArray) {
      updatedHours = hours;

      final workDay = _getNextWorkDay(workDays, dateTime);
      dateTime = workDay[1];

      if (updatedHours > workDay[0].hoursWorked) {
        updatedHours = workDay[0].hoursWorked;
      }

      final response = await _jiraService.postData(url!, basicAuth, issue,
          updatedHours, DateFormat('yyyy-MM-dd').format(dateTime));
      if (!isOkStatusCode(response.statusCode)) {
        return Future<Response>(
          () => Response('Error: ${response.body}', response.statusCode,
              reasonPhrase: response.reasonPhrase),
        );
      } else {
        dateTime = dateTime.add(const Duration(days: 1));
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
    final basicAuth = await _getAuthentication();

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

  Future<bool> areAllDataSaved() async {
    return await _settingsService.areAllDataSaved();
  }

  Future<List<int>> getNotWorkedDays() {
    return _settingsService.getNotWorkedDays();
  }

  List _getNextWorkDay(List<WorkDay> workDays, DateTime dateTime) {
    final workDay =
        workDays.firstWhere((element) => element.day == dateTime.weekday);

    if (!workDay.isWorking) {
      dateTime = dateTime.add(const Duration(days: 1));
      return _getNextWorkDay(workDays, dateTime);
    }

    return [workDay, dateTime];
  }

  Future<List<WorkDay>?> _getWorkDays() {
    final workDays = _settingsService.getWorkDays();
    return workDays;
  }

  Future<String?> _getJiraPath() async {
    final url = await _settingsService.getJiraPath();
    return url != null && url.isNotEmpty ? "${url}issue/" : "";
  }

  Future<String> _getAuthentication() async {
    final basicAuth = await _settingsService.getAuthentication();
    return basicAuth ?? "";
  }

  Response _buildErrorResponse(
      String message, int statusCode, String reasonPhrase) {
    return Response(message, statusCode, reasonPhrase: reasonPhrase);
  }

  List _buildRepetitionsArray(int repetitions) {
    final repetitionsArray = [];
    for (int i = 0; i < repetitions; i++) {
      repetitionsArray.add(i);
    }
    return repetitionsArray;
  }
}
