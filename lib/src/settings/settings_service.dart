import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';
import 'package:http/http.dart' as http;
import 'package:worklogs_jira/src/models/work_day.dart';

class SettingsService {
  SettingsService(this._preferencesService);

  final PreferencesService _preferencesService;

  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _basicAuthKey = 'basicAuth';
  static const String _issuePreffixKey = 'issuePreffix';
  static const String _lastIssueKey = 'lastIssue';
  static const String _lastLoggedDateKey = 'lastLoggedDate';
  static const String _jiraPathKey = 'jiraPath';
  static const String _workDaysKey = 'workDaysKey';
  // reminder settings
  static const String _reminderEnabledKey = 'reminderEnabled';
  static const String _reminderTimeKey = 'reminderTime'; // stored as "HH:mm"
  static const String _reminderMessageKey = 'reminderMessage';
  static const String _dailyTasksDraftKey = 'dailyTasksDraft';
  static const String _dailyTasksDraftDateKey = 'dailyTasksDraftDate';
  static const String _onboardingSeenKey = 'onboardingSeen';
  static const int _jiraApiVersion = 2;

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

  Future<bool> areAllDataSaved() async {
    final authentication = await getAuthentication();
    final jiraPath = await getJiraBasePath();
    return authentication != null &&
        authentication != '' &&
        jiraPath != null &&
        jiraPath != '';
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

  Future<String?> getLastLoggedDate() async {
    return _preferencesService.get(_lastLoggedDateKey);
  }

  Future<void> addLastLoggedDate(String lastLoggedDate) async {
    await _preferencesService.set(_lastLoggedDateKey, lastLoggedDate);
  }

  Future<String?> getUsername() async {
    return _preferencesService.get(_usernameKey);
  }

  Future<void> addUsername(username) async {
    await _preferencesService.set(_usernameKey, username);
  }

  Future<String?> getEmail() async {
    return _preferencesService.get(_emailKey);
  }

  Future<void> addEmail(email) async {
    await _preferencesService.set(_emailKey, email);
  }

//todo /rest/api/2
  Future<String?> getJiraPath() async {
    var jiraPathSaved = await getJiraBasePath();
    if (jiraPathSaved == null || (jiraPathSaved.isEmpty)) {
      return "";
    }
    if (jiraPathSaved.endsWith("/")) {
      return "${jiraPathSaved.substring(0, jiraPathSaved.length - 1)}/rest/api/$_jiraApiVersion/";
    }
    return "$jiraPathSaved/rest/api/$_jiraApiVersion/";
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

  Future<List<WorkDay>?> getWorkDays() async {
    final List<String>? encodedList =
        await _preferencesService.getStringList(_workDaysKey);
    List<WorkDay>? decodedList =
        encodedList?.map((day) => WorkDay.fromMap(json.decode(day))).toList();
    return decodedList;
  }

  Future<void> addWorkDays(List<WorkDay> workDays) async {
    final List<String> encodedList =
        workDays.map((day) => json.encode(day.toMap())).toList();
    await _preferencesService.setStringList(_workDaysKey, encodedList);
  }

  Future<void> clear() async {
    await _preferencesService.clear();
  }

  // reminder preferences helpers
  Future<bool> getReminderEnabled() async {
    final String? raw = await _preferencesService.get(_reminderEnabledKey);
    return raw == 'true';
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _preferencesService.set(_reminderEnabledKey, enabled.toString());
  }

  Future<TimeOfDay?> getReminderTime() async {
    final String? raw = await _preferencesService.get(_reminderTimeKey);
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final formatted = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    await _preferencesService.set(_reminderTimeKey, formatted);
  }

  Future<String?> getReminderMessage() async {
    return _preferencesService.get(_reminderMessageKey);
  }

  Future<void> setReminderMessage(String message) async {
    await _preferencesService.set(_reminderMessageKey, message);
  }

  Future<List<int>> getNotWorkedDays() async {
    final List<int> result = [];
    List<WorkDay>? d = await getWorkDays();

    d?.forEach((element) {
      if (!element.isWorking) {
        result.add(element.day);
      }
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getDailyTasksDraft() async {
    final List<String>? encoded =
        await _preferencesService.getStringList(_dailyTasksDraftKey);
    if (encoded == null) return [];
    return encoded
        .map((e) => Map<String, dynamic>.from(json.decode(e) as Map))
        .toList();
  }

  Future<String?> getDailyTasksDraftDate() async {
    return _preferencesService.get(_dailyTasksDraftDateKey);
  }

  Future<void> saveDailyTasksDraft(
      List<Map<String, dynamic>> tasks, String date) async {
    final List<String> encoded = tasks.map((t) => json.encode(t)).toList();
    await _preferencesService.setStringList(_dailyTasksDraftKey, encoded);
    await _preferencesService.set(_dailyTasksDraftDateKey, date);
  }

  Future<void> clearDailyTasksDraft() async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    await prefs.remove(_dailyTasksDraftKey);
    await prefs.remove(_dailyTasksDraftDateKey);
  }

  Future<bool> getOnboardingSeen() async {
    final String? raw = await _preferencesService.get(_onboardingSeenKey);
    return raw == 'true';
  }

  Future<void> setOnboardingSeen(bool seen) async {
    await _preferencesService.set(_onboardingSeenKey, seen.toString());
  }

  Future<List<String>> getUserProjects() async {
    try {
      final jiraBasePath = await getJiraBasePath();
      final auth = await getAuthentication();

      if (jiraBasePath == null ||
          jiraBasePath.isEmpty ||
          auth == null ||
          auth.isEmpty) {
        return [];
      }

      final url = '$jiraBasePath/rest/api/$_jiraApiVersion/project';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': auth,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List projects = json.decode(response.body);
        return projects.map((project) => project['key'] as String).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
