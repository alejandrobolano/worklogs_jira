import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
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

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    final basicAuth = await _settingsService.getAuthentication();
    _isAuthSaved = basicAuth != '' && basicAuth != null;
    _issuePreffix = await _settingsService.getIssuePreffix();
    _jiraPath = await _settingsService.getJiraBasePath();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> savePreferences(String username, String password, String token,
      String issuePreffix, String jiraPath) async {
    if (username.isNotEmpty && (password.isNotEmpty || token.isNotEmpty)) {
      await _settingsService.addAuthentication(token.isNotEmpty
          ? 'Bearer $token'
          : 'Basic ${base64Encode(utf8.encode('$username:$password'))}');
      await _settingsService.addUsername(username);
    }

    if (issuePreffix.isNotEmpty) {
      await _settingsService.addIssuePreffix(issuePreffix.toUpperCase());
    }

    if (jiraPath.isNotEmpty) {
      final isCorrectUrl = await _settingsService.isCorrectUrl(jiraPath);
      if (isCorrectUrl) {
        await _settingsService.addJiraPath(jiraPath);
      }
    }
  }
}
