import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// This is a small project to log works in Jira.
  ///
  /// In en, this message translates to:
  /// **'WorklogsJira'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHelperText.
  ///
  /// In en, this message translates to:
  /// **'(Optional) It is necessary if you want to use the Dashboard.'**
  String get emailHelperText;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @authoritationSaved.
  ///
  /// In en, this message translates to:
  /// **'Authorization saved'**
  String get authoritationSaved;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @repetitions.
  ///
  /// In en, this message translates to:
  /// **'# Repetitions of issue'**
  String get repetitions;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load issue'**
  String get load;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log issue'**
  String get log;

  /// No description provided for @successfulRequest.
  ///
  /// In en, this message translates to:
  /// **'Successful request'**
  String get successfulRequest;

  /// No description provided for @errorRequest.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred'**
  String get errorRequest;

  /// No description provided for @issueRequired.
  ///
  /// In en, this message translates to:
  /// **'Issue required'**
  String get issueRequired;

  /// No description provided for @someFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Some fields are required'**
  String get someFieldsRequired;

  /// No description provided for @issueEmpty.
  ///
  /// In en, this message translates to:
  /// **'This issue has not worklogs'**
  String get issueEmpty;

  /// No description provided for @listEmpty.
  ///
  /// In en, this message translates to:
  /// **'There aren\'t issues logs in this date range'**
  String get listEmpty;

  /// No description provided for @issuePreffix.
  ///
  /// In en, this message translates to:
  /// **'Issue preffix'**
  String get issuePreffix;

  /// No description provided for @showChart.
  ///
  /// In en, this message translates to:
  /// **'Show chart'**
  String get showChart;

  /// No description provided for @barsChart.
  ///
  /// In en, this message translates to:
  /// **'Bars chart'**
  String get barsChart;

  /// No description provided for @pieChart.
  ///
  /// In en, this message translates to:
  /// **'Pie chart'**
  String get pieChart;

  /// No description provided for @startRange.
  ///
  /// In en, this message translates to:
  /// **'Start range'**
  String get startRange;

  /// No description provided for @finishRange.
  ///
  /// In en, this message translates to:
  /// **'Finish range'**
  String get finishRange;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @timeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get timeSpent;

  /// No description provided for @startedLog.
  ///
  /// In en, this message translates to:
  /// **'Started log'**
  String get startedLog;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comment;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @assginee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assginee;

  /// No description provided for @jiraPath.
  ///
  /// In en, this message translates to:
  /// **'Jira\'s URL'**
  String get jiraPath;

  /// No description provided for @useToken.
  ///
  /// In en, this message translates to:
  /// **'Use token'**
  String get useToken;

  /// No description provided for @useTokenDescription.
  ///
  /// In en, this message translates to:
  /// **'You can use token or password for authentication'**
  String get useTokenDescription;

  /// No description provided for @workedHours.
  ///
  /// In en, this message translates to:
  /// **'Worked daily hours'**
  String get workedHours;

  /// No description provided for @workedHoursDescription.
  ///
  /// In en, this message translates to:
  /// **'Put your max quantity daily hours and check worked day'**
  String get workedHoursDescription;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @setSettings.
  ///
  /// In en, this message translates to:
  /// **'You must set setting params'**
  String get setSettings;

  /// No description provided for @passwordDeprecated.
  ///
  /// In en, this message translates to:
  /// **'Basic Authentication (user & password) has been disabled'**
  String get passwordDeprecated;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// Shows the last date when hours were logged
  ///
  /// In en, this message translates to:
  /// **'Last logged date: {date}'**
  String lastLoggedDate(String date);

  /// No description provided for @loggedTasks.
  ///
  /// In en, this message translates to:
  /// **'Logged tasks'**
  String get loggedTasks;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @reloadProjects.
  ///
  /// In en, this message translates to:
  /// **'Reload projects'**
  String get reloadProjects;

  /// No description provided for @loadProjectsFromJira.
  ///
  /// In en, this message translates to:
  /// **'Load projects from Jira'**
  String get loadProjectsFromJira;

  /// No description provided for @loadProjectsHelper.
  ///
  /// In en, this message translates to:
  /// **'Load projects from Jira or write manually'**
  String get loadProjectsHelper;

  /// Shows the number of available projects
  ///
  /// In en, this message translates to:
  /// **'{count} projects available'**
  String projectsAvailable(int count);

  /// No description provided for @worklogReminder.
  ///
  /// In en, this message translates to:
  /// **'Worklog reminder'**
  String get worklogReminder;

  /// No description provided for @enableReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable reminder'**
  String get enableReminder;

  /// No description provided for @selectReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Select reminder time'**
  String get selectReminderTime;

  /// No description provided for @customReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Custom message'**
  String get customReminderMessage;

  /// No description provided for @applyToAllDays.
  ///
  /// In en, this message translates to:
  /// **'Apply to all working days'**
  String get applyToAllDays;

  /// No description provided for @reminderTimeForDay.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeForDay;

  /// No description provided for @daysReceiveReminder.
  ///
  /// In en, this message translates to:
  /// **'Days that will receive the reminder'**
  String get daysReceiveReminder;

  /// No description provided for @noWorkingDaysReminder.
  ///
  /// In en, this message translates to:
  /// **'Select at least one working day to enable reminders.'**
  String get noWorkingDaysReminder;

  /// No description provided for @resetToDefaultTime.
  ///
  /// In en, this message translates to:
  /// **'Reset to default time'**
  String get resetToDefaultTime;

  /// No description provided for @reminderDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable the reminder individually for each working day. Tap the time to set a custom time.'**
  String get reminderDaysHint;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @newVersion.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get newVersion;

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// No description provided for @noReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes available'**
  String get noReleaseNotes;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @multiTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Log multiple tasks'**
  String get multiTaskTitle;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @logAll.
  ///
  /// In en, this message translates to:
  /// **'Log all'**
  String get logAll;

  /// Shows total logged hours vs max daily hours
  ///
  /// In en, this message translates to:
  /// **'Total: {total}h / {max}h'**
  String totalHoursInfo(String total, String max);

  /// Warning when sum of hours exceeds daily max
  ///
  /// In en, this message translates to:
  /// **'Daily hours exceeded ({total}h / {max}h). Continue anyway?'**
  String hoursExceeded(String total, String max);

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAnyway;

  /// No description provided for @reviewTasks.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTasks;

  /// No description provided for @noTasksToLog.
  ///
  /// In en, this message translates to:
  /// **'No tasks to log'**
  String get noTasksToLog;

  /// No description provided for @allTasksLogged.
  ///
  /// In en, this message translates to:
  /// **'All tasks logged successfully'**
  String get allTasksLogged;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get onboardingSettingsTitle;

  /// No description provided for @onboardingSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure your work hours per day, reminders, authentication and Jira URL here.'**
  String get onboardingSettingsDesc;

  /// No description provided for @onboardingFabTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get onboardingFabTitle;

  /// No description provided for @onboardingFabDesc.
  ///
  /// In en, this message translates to:
  /// **'Use these buttons to load your issue worklogs or log hours directly in one tap.'**
  String get onboardingFabDesc;

  /// No description provided for @onboardingDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get onboardingDashboardTitle;

  /// No description provided for @onboardingDashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Visualise all your logged tasks with charts and reports across any date range.'**
  String get onboardingDashboardDesc;

  /// No description provided for @onboardingMultiTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Log multiple tasks'**
  String get onboardingMultiTaskTitle;

  /// No description provided for @onboardingMultiTaskDesc.
  ///
  /// In en, this message translates to:
  /// **'Build a list of tasks for the day, save it as a draft and submit them all at once when you are ready.'**
  String get onboardingMultiTaskDesc;

  /// No description provided for @onboardingGithubTitle.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get onboardingGithubTitle;

  /// No description provided for @onboardingGithubDesc.
  ///
  /// In en, this message translates to:
  /// **'The full source code of this app is available on GitHub.'**
  String get onboardingGithubDesc;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
