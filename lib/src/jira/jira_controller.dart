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

  Future<Response> getData(String url, String issue) async {
    final basicAuth = await _settingsService.getBasicAuth();
    if (basicAuth == null || basicAuth == "") {
      return Future<Response>(
        () => Response('Error: Basic Auth not found', 400,
            reasonPhrase: "Basic auth not found"),
      );
    }
    return _jiraService.getData(url, basicAuth, issue);
  }

  Future<Response> postData(String url, String issue, double hours,
      String startDate, int repetitions) async {
    final basicAuth = await _settingsService.getBasicAuth();
    if (basicAuth == null || basicAuth == "") {
      return Future<Response>(
        () => Response('Error: Basic Auth not found', 400,
            reasonPhrase: "Basic auth not found"),
      );
    }

    final repetitionsArray = [];

    for (int i = 0; i < repetitions; i++) {
      repetitionsArray.add(i);
    }

    for (var index in repetitionsArray) {
      final dateTime = DateTime.parse(startDate);
      var date = dateTime.add(Duration(days: index));
      if (date.weekday == DateTime.saturday) {
        date = date.add(const Duration(days: 2));
      } else if (date.weekday == DateTime.friday && hours > 7) {
        hours = 7;
      }

      final response = await _jiraService.postData(
          url, basicAuth, issue, hours, DateFormat('yyyy-MM-dd').format(date));
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

  Future<Response> deleteData(String url, String id, String issueId) async {
    final basicAuth = await _settingsService.getBasicAuth();
    if (basicAuth == null || basicAuth == "") {
      return Future<Response>(
        () => Response('Error: Basic Auth not found', 400,
            reasonPhrase: "Basic auth not found"),
      );
    }
    return _jiraService.deleteData(url, basicAuth, id, issueId);
  }
}
