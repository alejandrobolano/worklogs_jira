import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _basicAuthKey = 'basicAuth';

  Future<SharedPreferences> _getPreferencesInstance() async {
    WidgetsFlutterBinding
        .ensureInitialized(); // Asegura la inicialización de Flutter
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
    final SharedPreferences prefs = await _getPreferencesInstance();
    final value = prefs.getString(_basicAuthKey);
    return value;
  }

  //More info: https://pub.dev/packages/shared_preferences
  Future<void> addBasicAuth(basicAuth) async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    await prefs.setString(_basicAuthKey, basicAuth);
  }
}
