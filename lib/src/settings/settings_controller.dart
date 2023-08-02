import 'dart:convert';

import 'package:flutter/material.dart';
import 'settings_service.dart';

class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;
  late bool _isAuthSaved;
  bool get isAuthSaved => _isAuthSaved;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    final basicAuth = await _settingsService.getBasicAuth();
    _isAuthSaved = basicAuth != '' && basicAuth != null;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> savePreferences(String username, String password) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    await _settingsService.addBasicAuth(basicAuth);
  }
}
