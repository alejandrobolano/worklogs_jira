// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WorklogsJira';

  @override
  String get settings => 'Settings';

  @override
  String get user => 'User';

  @override
  String get email => 'Email';

  @override
  String get emailHelperText =>
      '(Optional) It is necessary if you want to use the Dashboard.';

  @override
  String get password => 'Password';

  @override
  String get authoritationSaved => 'Authorization saved';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get issue => 'Issue';

  @override
  String get hours => 'Hours';

  @override
  String get repetitions => '# Repetitions of issue';

  @override
  String get startDate => 'Start date';

  @override
  String get load => 'Load issue';

  @override
  String get log => 'Log issue';

  @override
  String get successfulRequest => 'Successful request';

  @override
  String get errorRequest => 'An error has occurred';

  @override
  String get issueRequired => 'Issue required';

  @override
  String get someFieldsRequired => 'Some fields are required';

  @override
  String get issueEmpty => 'This issue has not worklogs';

  @override
  String get listEmpty => 'There aren\'t issues logs in this date range';

  @override
  String get issuePreffix => 'Issue preffix';

  @override
  String get showChart => 'Show chart';

  @override
  String get barsChart => 'Bars chart';

  @override
  String get pieChart => 'Pie chart';

  @override
  String get startRange => 'Start range';

  @override
  String get finishRange => 'Finish range';

  @override
  String get loading => 'Loading';

  @override
  String get timeSpent => 'Time spent';

  @override
  String get startedLog => 'Started log';

  @override
  String get comment => 'Comments';

  @override
  String get created => 'Created';

  @override
  String get updated => 'Updated';

  @override
  String get assginee => 'Assignee';

  @override
  String get jiraPath => 'Jira\'s URL';

  @override
  String get useToken => 'Use token';

  @override
  String get useTokenDescription =>
      'You can use token or password for authentication';

  @override
  String get workedHours => 'Worked daily hours';

  @override
  String get workedHoursDescription =>
      'Put your max quantity daily hours and check worked day';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get setSettings => 'You must set setting params';

  @override
  String get passwordDeprecated =>
      'Basic Authentication (user & password) has been disabled';

  @override
  String get subtasks => 'Subtasks';

  @override
  String lastLoggedDate(String date) {
    return 'Last logged date: $date';
  }

  @override
  String get loggedTasks => 'Logged tasks';

  @override
  String get task => 'Task';

  @override
  String get date => 'Date';

  @override
  String get reloadProjects => 'Reload projects';

  @override
  String get loadProjectsFromJira => 'Load projects from Jira';

  @override
  String get loadProjectsHelper => 'Load projects from Jira or write manually';

  @override
  String projectsAvailable(int count) {
    return '$count projects available';
  }

  @override
  String get worklogReminder => 'Worklog reminder';

  @override
  String get enableReminder => 'Enable reminder';

  @override
  String get selectReminderTime => 'Select reminder time';

  @override
  String get customReminderMessage => 'Custom message';

  @override
  String get applyToAllDays => 'Apply to all working days';

  @override
  String get reminderTimeForDay => 'Reminder time';

  @override
  String get daysReceiveReminder => 'Days that will receive the reminder';

  @override
  String get noWorkingDaysReminder =>
      'Select at least one working day to enable reminders.';

  @override
  String get resetToDefaultTime => 'Reset to default time';

  @override
  String get reminderDaysHint =>
      'Enable or disable the reminder individually for each working day. Tap the time to set a custom time.';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get newVersion => 'New version';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String get noReleaseNotes => 'No release notes available';

  @override
  String get later => 'Later';

  @override
  String get download => 'Download';

  @override
  String get multiTaskTitle => 'Log multiple tasks';

  @override
  String get addTask => 'Add task';

  @override
  String get logAll => 'Log all';

  @override
  String totalHoursInfo(String total, String max) {
    return 'Total: ${total}h / ${max}h';
  }

  @override
  String hoursExceeded(String total, String max) {
    return 'Daily hours exceeded (${total}h / ${max}h). Continue anyway?';
  }

  @override
  String get continueAnyway => 'Continue';

  @override
  String get reviewTasks => 'Review';

  @override
  String get noTasksToLog => 'No tasks to log';

  @override
  String get allTasksLogged => 'All tasks logged successfully';

  @override
  String get onboardingSkip => 'Got it!';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSettingsTitle => 'Settings';

  @override
  String get onboardingSettingsDesc =>
      'Configure your work hours per day, reminders, authentication and Jira URL here.';

  @override
  String get onboardingFabTitle => 'Quick actions';

  @override
  String get onboardingFabDesc =>
      'Use these buttons to load your issue worklogs or log hours directly in one tap.';

  @override
  String get onboardingDashboardTitle => 'Dashboard';

  @override
  String get onboardingDashboardDesc =>
      'Visualise all your logged tasks with charts and reports across any date range.';

  @override
  String get onboardingMultiTaskTitle => 'Log multiple tasks';

  @override
  String get onboardingMultiTaskDesc =>
      'Build a list of tasks for the day, save it as a draft and submit them all at once when you are ready.';

  @override
  String get onboardingGithubTitle => 'Source code';

  @override
  String get onboardingGithubDesc =>
      'The full source code of this app is available on GitHub.';
}
