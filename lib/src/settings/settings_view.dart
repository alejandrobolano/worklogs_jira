import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'color_picker_button.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:worklogs_jira/src/helper/date_helper.dart';
import 'package:worklogs_jira/src/helper/widget_helper.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
import 'settings_controller.dart';
import '../services/notification_service.dart';
import 'package:worklogs_jira/src/localization/app_localizations.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  var _issuePreffixController = TextEditingController();
  var _jiraPathController = TextEditingController();
  late int _jiraApiVersion;

  late bool _isVisiblePassword = false;
  final _textControllers = [];
  String _version = "";
  List<WorkDay> _workDays = [];
  List<String> _availableProjects = [];
  bool _isLoadingProjects = false;

  // reminder state
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  final _reminderMessageController = TextEditingController();
  bool _isSaving = false;
  String? _saveProgressMessage;
  bool _userSaved = false;
  bool _emailSaved = false;
  bool _tokenSaved = false;
  bool _jiraPathSaved = false;
  bool _issuePrefixSaved = false;
  bool _jiraApiVersionSaved = false;
  bool _reminderSaved = false;
  bool _workDaysSaved = false;

  @override
  void initState() {
    _textControllers.add(_userController);
    _textControllers.add(_emailController);
    _userController.text = widget.controller.username ?? '';
    _emailController.text = widget.controller.email ?? '';
    _issuePreffixController =
        TextEditingController(text: widget.controller.issuePreffix ?? "");
    _jiraPathController =
        TextEditingController(text: widget.controller.jiraPath ?? "");
    _jiraApiVersion = widget.controller.jiraApiVersion;
    _workDays = _getWorkDays();
    _normalizeReminderDays();

    // reminders
    _reminderEnabled = widget.controller.reminderEnabled;
    _reminderTime = widget.controller.reminderTime;
    _reminderMessageController.text = widget.controller.reminderMessage;

    _userController.addListener(() {
      if (_userSaved) {
        setState(() => _userSaved = false);
      }
    });
    _emailController.addListener(() {
      if (_emailSaved) {
        setState(() => _emailSaved = false);
      }
    });
    _tokenController.addListener(() {
      if (_tokenSaved) {
        setState(() => _tokenSaved = false);
      }
    });
    _issuePreffixController.addListener(() {
      if (_issuePrefixSaved) {
        setState(() => _issuePrefixSaved = false);
      }
    });
    _jiraPathController.addListener(() {
      if (_jiraPathSaved) {
        setState(() => _jiraPathSaved = false);
      }
    });

    if (widget.controller.isAuthSaved) {
      _tokenController.text = '***************';
      _tokenSaved = true;
    }
    _userSaved = (widget.controller.username ?? '').isNotEmpty &&
        _userController.text == (widget.controller.username ?? '');
    _emailSaved = (widget.controller.email ?? '').isNotEmpty &&
        _emailController.text == (widget.controller.email ?? '');
    _jiraPathSaved = (widget.controller.jiraPath ?? '').isNotEmpty &&
        _jiraPathController.text == (widget.controller.jiraPath ?? '');
    _issuePrefixSaved = (widget.controller.issuePreffix ?? '').isNotEmpty &&
        _issuePreffixController.text == (widget.controller.issuePreffix ?? '');
    _jiraApiVersionSaved = widget.controller.jiraApiVersion == _jiraApiVersion;
    _reminderSaved = widget.controller.reminderEnabled == _reminderEnabled &&
        widget.controller.reminderMessage == _reminderMessageController.text &&
        widget.controller.reminderTime == _reminderTime;
    _workDaysSaved = widget.controller.workDays != null &&
        widget.controller.workDays!.isNotEmpty;

    _getAppVersion();

    if (widget.controller.isAuthSaved) {
      _loadProjects();
    }

    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller.dispose();
    }
    _reminderMessageController.dispose();
    super.dispose();
  }

  void _normalizeReminderDays() {
    for (final WorkDay workDay in _workDays) {
      // Ensure non-working days cannot fire a reminder; preserve working days' user choice
      if (!workDay.isWorking) workDay.reminderEnabled = false;
    }
  }

  /// All working days (shown in the per-day list regardless of their reminder toggle).
  List<WorkDay> get _workingDays =>
      _workDays.where((day) => day.isWorking).toList();

  /// Working days that have their individual reminder toggle enabled.
  List<WorkDay> get _activeReminderDays =>
      _workDays.where((day) => day.isWorking && day.reminderEnabled).toList();

  TimeOfDay _effectiveTimeForDay(WorkDay day) =>
      day.reminderTimeOfDay ?? _reminderTime;

  String _localizedDayLabel(BuildContext context, int day) {
    final Locale locale = Localizations.localeOf(context);
    final DateTime monday = DateTime(2024, 1, 1);
    final DateTime date = monday.add(Duration(days: day - 1));
    final String label = DateFormat.EEEE(locale.toLanguageTag()).format(date);
    if (label.isEmpty) {
      return DateHelper.getDay(day);
    }
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  String _reminderSubtitle(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final List<WorkDay> activeDays = _activeReminderDays;

    if (activeDays.isEmpty) {
      return locale.languageCode == 'es'
          ? 'Selecciona días laborables para programar el reminder'
          : 'Select working days to schedule the reminder';
    }

    final bool hasCustomTimes =
        activeDays.any((d) => d.reminderTimeOfDay != null);

    if (!hasCustomTimes) {
      final String daysLabel =
          activeDays.map((d) => _localizedDayLabel(context, d.day)).join(', ');
      return '${_reminderTime.format(context)} · $daysLabel';
    }

    return activeDays.map((d) {
      final String abbr = _localizedDayLabel(context, d.day);
      final String time = _effectiveTimeForDay(d).format(context);
      return '$abbr $time';
    }).join(', ');
  }

  void _refreshLocalReminderState() {
    _workDays = _getWorkDays();
    _normalizeReminderDays();
    _issuePreffixController.text = widget.controller.issuePreffix ?? '';
    _jiraPathController.text = widget.controller.jiraPath ?? '';
    _jiraApiVersion = widget.controller.jiraApiVersion;
    _reminderEnabled = widget.controller.reminderEnabled;
    _reminderTime = widget.controller.reminderTime;
    _reminderMessageController.text = widget.controller.reminderMessage;
  }

  Future<void> _saveField({
    bool saveUser = false,
    bool saveEmail = false,
    bool saveToken = false,
    bool saveJiraPath = false,
    bool saveIssuePrefix = false,
    bool saveJiraApiVersion = false,
    bool saveReminder = false,
    bool saveWorkDays = false,
  }) async {
    if (_isSaving) {
      return;
    }

    try {
      FocusScope.of(context).unfocus();
      _normalizeReminderDays();

      setState(() {
        _isSaving = true;
      });

      final rawToken = saveToken && _tokenController.text != '***************'
          ? _tokenController.text
          : (widget.controller.isAuthSaved ? _tokenController.text : '');

      await widget.controller.savePreferences(
        _userController.text,
        _emailController.text,
        rawToken,
        _issuePreffixController.text,
        _jiraPathController.text,
        _jiraApiVersion,
        _workDays,
        _reminderEnabled,
        _reminderTime,
        _reminderMessageController.text,
      );

      if (!mounted) return;

      await widget.controller.loadSettings();

      if (!mounted) return;

      setState(() {
        _refreshLocalReminderState();
        _userSaved = saveUser && _userController.text.trim().isNotEmpty;
        _emailSaved = saveEmail && _emailController.text.trim().isNotEmpty;
        _tokenSaved = saveToken && _tokenController.text.trim().isNotEmpty;
        _jiraPathSaved =
            saveJiraPath && _jiraPathController.text.trim().isNotEmpty;
        _issuePrefixSaved =
            saveIssuePrefix && _issuePreffixController.text.trim().isNotEmpty;
        _jiraApiVersionSaved = saveJiraApiVersion;
        _reminderSaved = saveReminder;
        _workDaysSaved = saveWorkDays;
        if (saveToken &&
            _tokenController.text.isNotEmpty &&
            !_tokenController.text.startsWith('*')) {
          _tokenController.text = '***************';
          _tokenController.selection = TextSelection.collapsed(
            offset: _tokenController.text.length,
          );
        }
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      debugPrint('[Settings] _saveField error: $e');
      WidgetHelper.showMessageSnackBar(context, 'Error saving settings: $e');
    }
  }

  Widget _buildSaveSuffix({
    required bool saved,
    required VoidCallback onSave,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (saved)
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Guardar',
          icon: const Icon(Icons.save_outlined),
          onPressed: onSave,
        ),
      ],
    );
  }

  Future<void> _clear() async {
    await widget.controller.clear();
    await widget.controller.loadSettings();
    if (!mounted) return;
    setState(() {
      _clearTextControllers();
      _issuePreffixController.clear();
      _jiraPathController.clear();
      _refreshLocalReminderState();
    });
  }

  void _clearTextControllers() {
    for (var controller in _textControllers) {
      controller.clear();
    }
  }

  void _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      if (mounted) {
        _version = packageInfo.version;
      }
    });
  }

  List<WorkDay> _getWorkDays() {
    return widget.controller.workDays ??
        List.generate(
          DateTime.daysPerWeek,
          (index) => WorkDay(
              day: index + 1,
              hoursWorked: isWeekend(index) ? 0.0 : 8.0,
              isWorking: isWeekend(index) ? false : true),
        );
  }

  bool isWeekend(int index) =>
      index + 1 == DateTime.saturday || index + 1 == DateTime.sunday;

  Future<void> _loadProjects() async {
    if (widget.controller.jiraPath == null ||
        widget.controller.jiraPath!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final projects = await widget.controller.getUserProjects();
      setState(() {
        _availableProjects = projects;
        _isLoadingProjects = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<WorkDay> workingDays = _workingDays;
    final List<WorkDay> activeReminderDays = _activeReminderDays;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
        ),
        actions: [
          IconButton(
            tooltip: '?',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).pop('onboarding');
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)?.clearCache,
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _clear();
            },
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(children: [
            SizedBox(
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _userController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.person_2_outlined),
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)?.user,
                  suffixIcon: _buildSaveSuffix(
                    saved: _userSaved,
                    onSave: () => _saveField(saveUser: true),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  icon: const Icon(Icons.email),
                  labelText: AppLocalizations.of(context)?.email,
                  helperText: AppLocalizations.of(context)?.emailHelperText,
                  suffixIcon: _buildSaveSuffix(
                    saved: _emailSaved,
                    onSave: () => _saveField(saveEmail: true),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              child: TextField(
                obscureText: !_isVisiblePassword || _tokenSaved,
                controller: _tokenController,
                onTap: _tokenSaved
                    ? () {
                        setState(() {
                          _tokenSaved = false;
                          _tokenController.clear();
                          _isVisiblePassword = true;
                        });
                      }
                    : null,
                decoration: InputDecoration(
                  icon: const Icon(Icons.security),
                  border: const OutlineInputBorder(),
                  labelText: "Token",
                  helperText: AppLocalizations.of(context)?.passwordDeprecated,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_tokenSaved)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                      IconButton(
                        onPressed: () {
                          if (_tokenSaved) {
                            setState(() {
                              _tokenSaved = false;
                              _tokenController.clear();
                              _isVisiblePassword = true;
                            });
                            return;
                          }
                          _saveField(saveToken: true);
                        },
                        icon: const Icon(Icons.save_outlined),
                      ),
                      IconButton(
                        icon: Icon(_isVisiblePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isVisiblePassword = !_isVisiblePassword;
                          });
                        },
                      ),
                    ],
                  ),
                  alignLabelWithHint: false,
                ),
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              child: TextField(
                keyboardType: TextInputType.url,
                controller: _jiraPathController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  icon: const Icon(Icons.link_outlined),
                  border: const OutlineInputBorder(),
                  hintText: 'https://jira.domain.com/',
                  labelText: AppLocalizations.of(context)?.jiraPath,
                  suffixIcon: _buildSaveSuffix(
                    saved: _jiraPathSaved,
                    onSave: () => _saveField(saveJiraPath: true),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Icon(Icons.api),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)?.jiraApiVersion,
                      helperText: AppLocalizations.of(context)
                          ?.jiraApiVersionCompatibility,
                      suffixIcon: _buildSaveSuffix(
                        saved: _jiraApiVersionSaved,
                        onSave: () => _saveField(saveJiraApiVersion: true),
                      ),
                    ),
                    initialValue: _jiraApiVersion,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _jiraApiVersion = value);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 3,
                        child: Text(
                            AppLocalizations.of(context)!.jiraApiVersion3Label),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(
                            AppLocalizations.of(context)!.jiraApiVersion2Label),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            ExpansionTile(
              title: Text(AppLocalizations.of(context)?.workedHours ?? ""),
              subtitle: Text(
                  AppLocalizations.of(context)?.workedHoursDescription ?? ""),
              childrenPadding: const EdgeInsets.all(24),
              children: [
                ..._workDays.map((day) => buildWorkDayRow(day)).toList(),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildSaveSuffix(
                    saved: _workDaysSaved,
                    onSave: () => _saveField(saveWorkDays: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            ExpansionTile(
              title: Text(AppLocalizations.of(context)?.worklogReminder ?? ''),
              subtitle: Text(_reminderSubtitle(context)),
              childrenPadding: const EdgeInsets.all(24),
              children: [
                SwitchListTile(
                  title:
                      Text(AppLocalizations.of(context)?.enableReminder ?? ''),
                  subtitle: Text(workingDays.isEmpty
                      ? (Localizations.localeOf(context).languageCode == 'es'
                          ? 'No hay días laborables seleccionados'
                          : 'No working days selected')
                      : (Localizations.localeOf(context).languageCode == 'es'
                          ? 'Se aplicará a ${activeReminderDays.length} día(s) con recordatorio activo'
                          : 'Will apply to ${activeReminderDays.length} day(s) with reminder enabled')),
                  value: _reminderEnabled,
                  onChanged: (bool v) {
                    setState(() {
                      _reminderEnabled = v;
                    });
                  },
                ),
                if (_isSaving && _saveProgressMessage != null) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _saveProgressMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                      ),
                    ),
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)?.daysReceiveReminder ??
                        'Days that will receive the reminder',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 4.0),
                if (workingDays.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      AppLocalizations.of(context)?.noWorkingDaysReminder ??
                          'Select at least one working day to enable reminders.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  Column(
                    children: workingDays.map((day) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_localizedDayLabel(context, day.day)),
                        subtitle: day.reminderEnabled
                            ? InkWell(
                                onTap: _reminderEnabled
                                    ? () async {
                                        final TimeOfDay? picked =
                                            await showTimePicker(
                                          context: context,
                                          initialTime:
                                              _effectiveTimeForDay(day),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            day.reminderTimeOfDay = picked;
                                          });
                                        }
                                      }
                                    : null,
                                child: Wrap(
                                  spacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    Text(
                                      _effectiveTimeForDay(day).format(context),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                    if (day.reminderTimeOfDay != null)
                                      Tooltip(
                                        message: AppLocalizations.of(context)
                                                ?.resetToDefaultTime ??
                                            'Reset to default time',
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            day.reminderTimeOfDay = null;
                                          }),
                                          child: const Icon(
                                            Icons.restore,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : null,
                        value: day.reminderEnabled,
                        onChanged: _reminderEnabled
                            ? (bool v) =>
                                setState(() => day.reminderEnabled = v)
                            : null,
                      );
                    }).toList(),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: Text(
                    AppLocalizations.of(context)?.reminderDaysHint ??
                        'Enable or disable the reminder individually for each working day. Tap the time to set a custom time.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8.0),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  trailing: Text(_reminderTime.format(context)),
                  title: Text(
                      AppLocalizations.of(context)?.selectReminderTime ?? ''),
                  subtitle: Text(
                    Localizations.localeOf(context).languageCode == 'es'
                        ? 'Hora predeterminada · toca un día para personalizar por día'
                        : 'Default time · tap a day row to set individual time',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  enabled: _reminderEnabled && workingDays.isNotEmpty,
                  onTap: !_reminderEnabled || workingDays.isEmpty
                      ? null
                      : () async {
                          final picked = await showTimePicker(
                              context: context, initialTime: _reminderTime);
                          if (picked != null) {
                            setState(() {
                              _reminderTime = picked;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16.0),
                TextField(
                  enabled: _reminderEnabled,
                  controller: _reminderMessageController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText:
                        AppLocalizations.of(context)?.customReminderMessage,
                    hintText: NotificationService.getDefaultReminderMessage(
                        Localizations.localeOf(context)),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildSaveSuffix(
                    saved: _reminderSaved,
                    onSave: () => _saveField(saveReminder: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 15.0),
                  child: Icon(Icons.precision_manufacturing_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _availableProjects;
                      }
                      return _availableProjects.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      // Agregar guion al final si no lo tiene
                      final prefixWithDash =
                          selection.endsWith('-') ? selection : '$selection-';
                      _issuePreffixController.text =
                          prefixWithDash.toUpperCase();
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      if (fieldTextEditingController.text.isEmpty &&
                          _issuePreffixController.text.isNotEmpty) {
                        fieldTextEditingController.text =
                            _issuePreffixController.text;
                      }

                      fieldTextEditingController.addListener(() {
                        _issuePreffixController.text =
                            fieldTextEditingController.text;
                      });

                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: AppLocalizations.of(context)?.issuePreffix,
                          hintText: 'PROJ-',
                          suffixIcon: _isLoadingProjects
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_issuePrefixSaved)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.save_outlined),
                                      onPressed: () =>
                                          _saveField(saveIssuePrefix: true),
                                    ),
                                    if (_availableProjects.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.refresh),
                                        tooltip: AppLocalizations.of(context)
                                            ?.reloadProjects,
                                        onPressed: _loadProjects,
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        tooltip: AppLocalizations.of(context)
                                            ?.loadProjectsFromJira,
                                        onPressed: _loadProjects,
                                      ),
                                  ],
                                ),
                          helperText: _availableProjects.isEmpty
                              ? AppLocalizations.of(context)?.loadProjectsHelper
                              : AppLocalizations.of(context)?.projectsAvailable(
                                  _availableProjects.length),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.color_lens_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ThemeMode>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    initialValue: widget.controller.themeMode,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(5),
                    onChanged: widget.controller.updateThemeMode,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(AppLocalizations.of(context)!.systemTheme),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(AppLocalizations.of(context)!.lightTheme),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(AppLocalizations.of(context)!.darkTheme),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: ColorPickerButton(
                    current: widget.controller.seedColor,
                    onColorSelected: widget.controller.updateSeedColor,
                    label: AppLocalizations.of(context)!.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (_version.isNotEmpty)
              InputChip(
                  avatar: const Icon(Icons.lock_outline_rounded),
                  onSelected: (bool value) {},
                  label: Text("v.$_version")),
            const SizedBox(height: 24.0),
          ])),
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        height: 12,
      ),
    );
  }

  Widget buildWorkDayRow(WorkDay workDay) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${workDay.hoursWorked} h"),
            const SizedBox(width: 24.0),
            Flexible(
              child: TextField(
                  decoration: InputDecoration(
                    hintText: workDay.hoursWorked >= 0
                        ? workDay.hoursWorked.toString()
                        : "8.0",
                    border: const OutlineInputBorder(),
                    labelText: DateHelper.getDay(workDay.day).toString(),
                    alignLabelWithHint: false,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    setState(() {
                      workDay.hoursWorked = double.tryParse(value) ?? 0.0;
                    });
                  }),
            ),
            const SizedBox(width: 24.0),
            Checkbox(
              value: workDay.isWorking,
              onChanged: (value) {
                setState(() {
                  workDay.isWorking = value!;
                  workDay.reminderEnabled = value;
                });
              },
            ),
          ],
        )
      ],
    );
  }
}
