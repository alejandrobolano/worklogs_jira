import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//More info: https://pub.dev/packages/shared_preferences
class PreferencesService {
  Future<SharedPreferences> _getPreferencesInstance() async {
    WidgetsFlutterBinding.ensureInitialized();
    return await SharedPreferences.getInstance();
  }

  Future<String?> get(String key) async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    final value = prefs.getString(key);
    return value;
  }

  Future<void> set(String key, newValue) async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    await prefs.setString(key, newValue);
  }

  Future<List<String>?> getStringList(String key) async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    final value = prefs.getStringList(key);
    return value;
  }

  Future<void> setStringList(String key, newValue) async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    await prefs.setStringList(key, newValue);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await _getPreferencesInstance();
    await prefs.clear();
  }
}
