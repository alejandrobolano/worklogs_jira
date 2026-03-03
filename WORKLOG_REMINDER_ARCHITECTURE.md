# Worklog Reminder Architecture Diagram

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP LIFECYCLE                            │
└─────────────────────────────────────────────────────────────────┘

                        App Start (main.dart)
                               ↓
                    └─ Initialize Flutter
                    └─ Load SettingsController
                    └─ **Load Settings**
                               ↓
                    **NotificationService.initNotifications()**
                    └─ Init timezone
                    └─ Init notification plugin
                               ↓
                           runApp()
                               ↓
          App UI Rendered (MaterialApp / MyApp)
                               ↓
           **PostFrameCallback() triggered**
                               ↓
    **NotificationService.restoreWorklogRemindersFromPreferences()**
    └─ Read from SharedPreferences
    └─ Schedule notifications if enabled
                               ↓
                    App Ready & Notifications Active


┌─────────────────────────────────────────────────────────────────┐
│                      SETTINGS SAVE FLOW                          │
└─────────────────────────────────────────────────────────────────┘

        User Enters Reminder Settings
                    ↓
    ┌─ Reminder Enabled: YES/NO
    ├─ Reminder Time: HH:MM
    └─ Custom Message: String
                    ↓
        User Clicks SAVE Button
                    ↓
    SettingsView._save()
        ↓
        ├─ Validate input
        ├─ Call controller.savePreferences(
        │      username, email, token,
        │      prefix, jiraPath, workDays,
        │      reminderEnabled,        ← NEW
        │      reminderTime,           ← NEW
        │      reminderMessage         ← NEW
        │  )
        │
        └─ SettingsController.savePreferences()
            ├─ Save to SettingsService
            ├─ Save to SharedPreferences
            ├─ Update controller state
            └─ Call scheduleWorklogReminders(locale)
                    ↓
                NotificationService.scheduleWeeklyReminderForActiveDays()
                    ├─ Get active days from WorkDays
                    ├─ Cancel all existing reminders
                    ├─ For each active day:
                    │   ├─ Generate unique ID (100+day)
                    │   ├─ Calculate next occurrence
                    │   ├─ Call zonedSchedule()
                    │   └─ Store in system
                    └─ Done
                    ↓
            await controller.loadSettings()
                    ↓
            _clearTextControllers()
                    ↓
        UI Updated & Reminders Now Active


┌─────────────────────────────────────────────────────────────────┐
│                   NOTIFICATION DISPATCH                          │
└─────────────────────────────────────────────────────────────────┘

        System Time Reaches Scheduled Time
                    ↓
        Window OS Notification Service
                    ↓
        ┌──────────────────────────────┐
        │   NOTIFICATION DISPLAYED     │
        ├──────────────────────────────┤
        │ Title: "Recordatorio"        │
        │ Body: User's custom message  │
        │       or default message     │
        │ Time: HH:MM (as scheduled)   │
        └──────────────────────────────┘
                    ↓
        (Automatically repeats daily)


┌─────────────────────────────────────────────────────────────────┐
│                  CLASS HIERARCHY & DEPENDENCIES                  │
└─────────────────────────────────────────────────────────────────┘

NotificationService
├─ Static Methods
│  ├─ initNotifications()
│  ├─ scheduleWeeklyReminderForActiveDays()
│  ├─ cancelAllWorklogReminders()
│  ├─ restoreWorklogRemindersFromPreferences()
│  └─ getDefaultReminderMessage()
├─ Dependencies
│  ├─ FlutterLocalNotificationsPlugin (flutter_local_notifications)
│  ├─ SettingsService (reads WorkDays and preferences)
│  └─ timezone (for scheduling with DST support)
└─ Trigger Points
   ├─ main.dart: initNotifications()
   ├─ app.dart: restoreWorklogRemindersFromPreferences()
   └─ settings_view.dart: scheduleWorklogReminders()


SettingsController
├─ State
│  ├─ _reminderEnabled: bool
│  ├─ _reminderTime: TimeOfDay
│  ├─ _reminderMessage: String
│  └─ (+ other settings)
├─ Methods
│  ├─ loadSettings() - loads from service
│  ├─ savePreferences() - saves + schedules
│  └─ scheduleWorklogReminders() - delegates to NotificationService
└─ Dependencies
   └─ SettingsService


SettingsService
├─ Preference Getters/Setters
│  ├─ getReminderEnabled() / setReminderEnabled()
│  ├─ getReminderTime() / setReminderTime()
│  ├─ getReminderMessage() / setReminderMessage()
│  └─ (+ other settings)
└─ Dependencies
   ├─ PreferencesService
   │  └─ SharedPreferences (flutter package)
   └─ WorkDay (model for active days)


SettingsView
├─ UI Controls
│  ├─ SwitchListTile (enable/disable)
│  ├─ ListTile + TimePicker (select time)
│  └─ TextField (custom message)
├─ State Management
│  ├─ _reminderEnabled: bool
│  ├─ _reminderTime: TimeOfDay
│  └─ _reminderMessageController: TextEditingController
└─ Dependencies
   ├─ SettingsController (state + action)
   ├─ NotificationService (get defaults)
   └─ AppLocalizations (strings)


┌─────────────────────────────────────────────────────────────────┐
│              DATA PERSISTENCE LAYER (SharedPreferences)          │
└─────────────────────────────────────────────────────────────────┘

SharedPreferences Storage
├─ reminderEnabled: String ("true" / "false")
├─ reminderTime: String ("09:00" / "14:30" / etc)
├─ reminderMessage: String (user input or empty)
└─ (+ all other app settings)
   
Read By:
├─ SettingsService.getReminderXxx()
│  └─ Used by SettingsController.loadSettings()
│     └─ Used by SettingsView for UI display
└─ SettingsService.getReminderXxx()
   └─ Used by NotificationService.restoreWorklogRemindersFromPreferences()
      └─ Called at app startup

Written By:
├─ SettingsService.setReminderXxx()
│  └─ Called by SettingsController.savePreferences()
│     └─ Triggered by SettingsView._save()


┌─────────────────────────────────────────────────────────────────┐
│                    SCHEDULING ALGORITHM                          │
└─────────────────────────────────────────────────────────────────┘

Input: activeWeekdays = [1, 2, 3, 4, 5] (Mon-Fri)
       time = TimeOfDay(hour: 9, minute: 0)
       currentTime = 2026-02-26 10:00 (Thursday)

Processing:
  
  For each weekday in [1, 2, 3, 4, 5]:
    ┌─ Day 1 (Monday)
    │  └─ Next occurrence: 2026-03-02 (next Monday)
    │     └─ Time: 09:00
    │     └─ ID: 101
    │     └─ Status: Future ✓
    │
    ├─ Day 2 (Tuesday)
    │  └─ Next occurrence: 2026-02-27 (tomorrow)
    │     └─ Time: 09:00
    │     └─ ID: 102
    │     └─ Status: Future ✓
    │
    ├─ Day 3 (Wednesday)
    │  └─ Next occurrence: 2026-03-05 (next week)
    │     └─ Time: 09:00
    │     └─ ID: 103
    │     └─ Status: Future ✓
    │
    └─ ... (Thursday & Friday similar)

Result: 5 notifications scheduled, one for each active day
        Each scheduled with unique ID and recurrence set to weekly


┌─────────────────────────────────────────────────────────────────┐
│                      LOCALIZATION FLOW                           │
└─────────────────────────────────────────────────────────────────┘

App Starts
      ↓
Device Locale: en / es
      ↓
Localizations.localeOf(context) → Locale
      ↓
NotificationService.getDefaultReminderMessage(locale)
      ↓
├─ If locale.languageCode == 'es':
│  └─ Return: "Recuerda imputar las horas"
│
└─ Else (default to English):
   └─ Return: "Remember to log your hours"
      ↓
Used in:
├─ TextField hint (settings_view.dart)
└─ Notification body (if user didn't enter custom message)


┌─────────────────────────────────────────────────────────────────┐
│                     CANCEL & RESCHEDULE                          │
└─────────────────────────────────────────────────────────────────┘

User Changes Reminder Settings
         ↓
_save() called
         ↓
scheduleWeeklyReminderForActiveDays()
         ↓
cancelAllWorklogReminders()
├─ Calls: _notifications.cancelAll()
└─ Removes ALL active notifications
         ↓
For each active day:
├─ Create fresh notification
└─ Schedule with NEW time/message
         ↓
Result: Old reminders gone, new ones scheduled

This prevents:
✓ Duplicate notifications
✓ Stale old reminders
✓ Confusion on time changes
