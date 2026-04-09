import 'package:flutter/material.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
import 'settings_service.dart';
import '../services/notification_service.dart';

class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;
  SettingsService get settingsService => _settingsService;

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;
  late bool _isAuthSaved;
  bool get isAuthSaved => _isAuthSaved;
  late String? _issuePreffix;
  String? get issuePreffix => _issuePreffix;
  late String? _jiraPath;
  String? get jiraPath => _jiraPath;
  late String? _email;
  String? get email => _email;
  late List<WorkDay>? _workDays;
  List<WorkDay>? get workDays => _workDays;

  // reminder settings
  late bool _reminderEnabled;
  bool get reminderEnabled => _reminderEnabled;
  late TimeOfDay _reminderTime;
  TimeOfDay get reminderTime => _reminderTime;
  late String _reminderMessage;
  String get reminderMessage => _reminderMessage;

  // Default seed color (deep purple / the current app default)
  static const int _defaultSeedColorValue = 0xFF6750A4;
  late Color _seedColor = const Color(_defaultSeedColorValue);
  Color get seedColor => _seedColor;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _issuePreffix = await _settingsService.getIssuePreffix();
    _jiraPath = await _settingsService.getJiraBasePath();
    _email = await _settingsService.getEmail();
    var authentication = await _settingsService.getAuthentication();
    _isAuthSaved = _jiraPath != null &&
        _jiraPath != '' &&
        authentication != null &&
        authentication != '';
    _workDays = await _settingsService.getWorkDays();
    // reminder preferences
    _reminderEnabled = await _settingsService.getReminderEnabled();
    _reminderTime = await _settingsService.getReminderTime() ??
        const TimeOfDay(hour: 9, minute: 0);
    _reminderMessage = await _settingsService.getReminderMessage() ?? '';
    final int? storedColor = await _settingsService.getSeedColor();
    _seedColor = storedColor != null
        ? Color(storedColor)
        : const Color(_defaultSeedColorValue);
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> updateSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    await _settingsService.setSeedColor(color.toARGB32());
  }

  Future<void> savePreferences(
      String username,
      String email,
      String token,
      String issuePreffix,
      String jiraPath,
      List<WorkDay> workDays,
      bool reminderEnabled,
      TimeOfDay reminderTime,
      String reminderMessage) async {
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

    if (email.isNotEmpty) {
      await _settingsService.addEmail(email);
    }

    // reminder prefs
    await _settingsService.setReminderEnabled(reminderEnabled);
    await _settingsService.setReminderTime(reminderTime);
    await _settingsService.setReminderMessage(reminderMessage);

    // update controller state for UI
    _workDays = workDays;
    _reminderEnabled = reminderEnabled;
    _reminderTime = reminderTime;
    _reminderMessage = reminderMessage;
    _issuePreffix = issuePreffix.toUpperCase();
    _jiraPath = jiraPath;
    _email = email;
  }

  Future<void> clear() async {
    await _settingsService.clear();
  }

  /// helper that delegates scheduling to the notification service.
  /// Returns null if successful, or an error message if scheduling failed.
  Future<ReminderSyncResult> scheduleWorklogReminders(Locale locale) async {
    return await NotificationService.scheduleWeeklyReminderForActiveDays(
        enabled: _reminderEnabled,
        workDays: _workDays ?? [],
        defaultTime: _reminderTime,
        message: _reminderMessage,
        locale: locale);
  }

  Future<String?> getAuthentication() async {
    return await _settingsService.getAuthentication();
  }

  Future<List<String>> getUserProjects() async {
    return await _settingsService.getUserProjects();
  }
}
