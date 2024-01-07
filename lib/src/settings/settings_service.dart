import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'package:http/http.dart' as http;

class SettingsService {
  SettingsService(this._preferencesService);

  final PreferencesService _preferencesService;

  static const String _usernameKey = 'username';
  static const String _basicAuthKey = 'basicAuth';
  static const String _issuePreffixKey = 'issuePreffix';
  static const String _lastIssueKey = 'lastIssue';
  static const String _jiraPathKey = 'jiraPath';

  Future<SharedPreferences> _getPreferencesInstance() async {
    WidgetsFlutterBinding.ensureInitialized();
    return await SharedPreferences.getInstance();
  }

  Future<ThemeMode> themeMode() async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    final value = prefs.getString("theme");

    if (value == null || value == "") {
      return ThemeMode.system;
    }
    return ThemeMode.values.firstWhere((element) => element.name == value);
  }

  Future<void> updateThemeMode(ThemeMode theme) async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    await prefs.setString("theme", theme.name);
  }

  Future<String?> getAuthentication() async {
    return _preferencesService.get(_basicAuthKey);
  }

  Future<void> addAuthentication(basicAuth) async {
    await _preferencesService.set(_basicAuthKey, basicAuth);
  }

  Future<String?> getIssuePreffix() async {
    return _preferencesService.get(_issuePreffixKey);
  }

  Future<void> addIssuePreffix(issuePreffix) async {
    await _preferencesService.set(_issuePreffixKey, issuePreffix);
  }

  Future<String?> getLastIssue() async {
    return _preferencesService.get(_lastIssueKey);
  }

  Future<void> addLastIssue(lastIssue) async {
    await _preferencesService.set(_lastIssueKey, lastIssue);
  }

  Future<String?> getUsername() async {
    return _preferencesService.get(_usernameKey);
  }

  Future<void> addUsername(username) async {
    await _preferencesService.set(_usernameKey, username);
  }

//todo /rest/api/2

  Future<String?> getJiraPath() async {
    var jiraPathSaved = await getJiraBasePath();
    if (jiraPathSaved == null || (jiraPathSaved.isEmpty)) {
      return "";
    }
    if (jiraPathSaved.endsWith("/")) {
      return jiraPathSaved.substring(0, jiraPathSaved.length - 1);
    }
    return "$jiraPathSaved/rest/api/2/";
  }

  Future<String?> getJiraBasePath() async {
    return _preferencesService.get(_jiraPathKey);
  }

  Future<void> addJiraPath(jiraPath) async {
    await _preferencesService.set(_jiraPathKey, jiraPath);
  }

  Future<bool> isCorrectUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
