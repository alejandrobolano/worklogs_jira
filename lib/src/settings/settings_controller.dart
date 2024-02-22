import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
import 'settings_service.dart';

class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;
  late bool _isAuthSaved;
  bool get isAuthSaved => _isAuthSaved;
  late String? _issuePreffix;
  String? get issuePreffix => _issuePreffix;
  late String? _jiraPath;
  String? get jiraPath => _jiraPath;
  late List<WorkDay>? _workDays;
  List<WorkDay>? get workDays => _workDays;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _issuePreffix = await _settingsService.getIssuePreffix();
    _jiraPath = await _settingsService.getJiraBasePath();
    var authentication = await _settingsService.getAuthentication();
    _isAuthSaved = _jiraPath != null &&
        _jiraPath != '' &&
        authentication != null &&
        authentication != '';
    _workDays = await _settingsService.getWorkDays();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> savePreferences(String username, String token,
      String issuePreffix, String jiraPath, List<WorkDay> workDays) async {
    if (username.isNotEmpty && token.isNotEmpty) {
      await _settingsService.addAuthentication('Bearer $token');
      await _settingsService.addUsername(username);
    }

    if (issuePreffix.isNotEmpty) {
      await _settingsService.addIssuePreffix(issuePreffix.toUpperCase());
    }

    if (jiraPath.isNotEmpty) {
      await _settingsService.addJiraPath(jiraPath);
    }

    if (workDays.isNotEmpty) {
      await _settingsService.addWorkDays(workDays);
    }
  }

  Future<void> clear() async {
    await _settingsService.clear();
  }
}
