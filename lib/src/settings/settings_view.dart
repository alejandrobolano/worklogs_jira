import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:worklogs_jira/src/helper/date_helper.dart';
import 'package:worklogs_jira/src/models/work_day.dart';
import 'settings_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  late bool _isVisiblePassword = false;
  final _textControllers = [];
  String _version = "";
  List<WorkDay> _workDays = [];
  List<String> _availableProjects = [];
  bool _isLoadingProjects = false;

  @override
  void initState() {
    _textControllers.add(_userController);
    _textControllers.add(_emailController);
    _issuePreffixController =
        TextEditingController(text: widget.controller.issuePreffix ?? "");
    _jiraPathController =
        TextEditingController(text: widget.controller.jiraPath ?? "");
    _workDays = _getWorkDays();

    _userController.addListener(() {
      _emailController.text = _userController.text;
    });

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
    super.dispose();
  }

  Future<void> _save() async {
    await widget.controller.savePreferences(
        _userController.text,
        _emailController.text,
        _tokenController.text,
        _issuePreffixController.text,
        _jiraPathController.text,
        _workDays);
    await widget.controller.loadSettings();
    _clearTextControllers();
  }

  Future<void> _clear() async {
    await widget.controller.clear();
    _clearTextControllers();
    await widget.controller.loadSettings();
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
        ),
        actions: [
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
              //width: 250,
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _userController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.person_2_outlined),
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)?.user,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              //width: 250,
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  icon: const Icon(Icons.email),
                  labelText: AppLocalizations.of(context)?.email,
                  helperText: AppLocalizations.of(context)?.emailHelperText,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              child: TextField(
                obscureText: !_isVisiblePassword,
                controller: _tokenController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.security),
                  border: const OutlineInputBorder(),
                  labelText: "Token",
                  helperText: AppLocalizations.of(context)?.passwordDeprecated,
                  suffixIcon: IconButton(
                    icon: Icon(_isVisiblePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(
                        () {
                          _isVisiblePassword = !_isVisiblePassword;
                        },
                      );
                    },
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
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            ExpansionTile(
              title: Text(AppLocalizations.of(context)?.workedHours ?? ""),
              subtitle: Text(
                  AppLocalizations.of(context)?.workedHoursDescription ?? ""),
              childrenPadding: const EdgeInsets.all(24),
              children: _workDays.map((day) => buildWorkDayRow(day)).toList(),
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
                    initialValue: TextEditingValue(
                      text: _issuePreffixController.text,
                    ),
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
                              : (_availableProjects.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.refresh),
                                      tooltip: AppLocalizations.of(context)
                                          ?.reloadProjects,
                                      onPressed: _loadProjects,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.download),
                                      tooltip: AppLocalizations.of(context)
                                          ?.loadProjectsFromJira,
                                      onPressed: _loadProjects,
                                    )),
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
            DropdownButtonFormField<ThemeMode>(
              decoration: const InputDecoration(
                icon: Icon(Icons.color_lens_outlined),
                border: OutlineInputBorder(),
              ),
              value: widget.controller.themeMode,
              isExpanded: false,
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
            const SizedBox(height: 16.0),
            if (_version.isNotEmpty)
              InputChip(
                  avatar: const Icon(Icons.lock_outline_rounded),
                  onSelected: (bool value) {},
                  label: Text("v.$_version")),
            const SizedBox(height: 16.0),
            if (widget.controller.isAuthSaved)
              SizedBox(
                  child: InputChip(
                avatar: const Icon(Icons.check),
                onSelected: (bool value) {},
                label: Text(
                    AppLocalizations.of(context)!.authoritationSaved.toString(),
                    style: const TextStyle(color: Colors.black)),
                backgroundColor: Colors.greenAccent,
                selectedColor: Colors.black,
              )),
            const SizedBox(height: 24.0),
          ])),
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        height: 65,
      ),
      floatingActionButton: Container(
          margin: const EdgeInsets.all(10),
          child: FloatingActionButton(
              onPressed: _save,
              heroTag: 'save',
              child: const Icon(Icons.save))),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
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
                });
              },
            ),
          ],
        )
      ],
    );
  }
}
