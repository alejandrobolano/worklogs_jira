import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklogs_jira/src/settings/preferences_service.dart';

class SettingsService {
  SettingsService(this._preferencesService);

  final PreferencesService _preferencesService;

  static const String _usernameKey = 'username';
  static const String _basicAuthKey = 'basicAuth';
  static const String _issuePreffixKey = 'issuePreffix';
  static const String _lastIssueKey = 'lastIssue';

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

  Future<String?> getBasicAuth() async {
    return _preferencesService.get(_basicAuthKey);
  }

  Future<void> addBasicAuth(basicAuth) async {
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
}
