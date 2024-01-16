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
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  var _issuePreffixController = TextEditingController();
  var _jiraPathController = TextEditingController();

  late bool _isVisiblePassword = false;
  late bool _isTokenSelected = true;
  final _textControllers = [];
  String _version = "";
  List<WorkDay> _workDays = [];

  @override
  void initState() {
    _textControllers.add(_userController);
    _textControllers.add(_passwordController);
    _textControllers.add(_tokenController);
    _issuePreffixController =
        TextEditingController(text: widget.controller.issuePreffix ?? "");
    _jiraPathController =
        TextEditingController(text: widget.controller.jiraPath ?? "");
    _workDays = _getWorkDays();

    _getAppVersion();
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
        _passwordController.text,
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

  @override
  Widget build(BuildContext context) {
    final MaterialStateProperty<Icon?> thumbIcon =
        MaterialStateProperty.resolveWith<Icon?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const Icon(Icons.check);
        }
        return const Icon(Icons.close);
      },
    );

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
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)?.user,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SwitchListTile(
                thumbIcon: thumbIcon,
                value: _isTokenSelected,
                onChanged: (bool value) {
                  setState(() {
                    _isTokenSelected = value;
                  });
                },
                title: Text(AppLocalizations.of(context)!.useToken.toString()),
                subtitle: Text(AppLocalizations.of(context)!
                    .useTokenDescription
                    .toString())),
            const SizedBox(height: 24.0),
            if (!_isTokenSelected)
              SizedBox(
                child: TextField(
                  obscureText: !_isVisiblePassword,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: AppLocalizations.of(context)?.password,
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
            if (_isTokenSelected)
              SizedBox(
                child: TextField(
                  obscureText: !_isVisiblePassword,
                  controller: _tokenController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: "Token",
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
            SizedBox(
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _issuePreffixController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)?.issuePreffix,
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            DropdownButtonFormField<ThemeMode>(
              decoration: const InputDecoration(
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
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: 50.0,
        ),
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
