import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../settings/settings_view.dart';
import 'jira_controller.dart';
import 'list/list_view.dart';
import 'models/jira_response.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class JiraView extends StatefulWidget {
  const JiraView({super.key, required this.controller});

  static const routeName = '/';
  final JiraController controller;

  @override
  State<JiraView> createState() => _JiraViewState();
}

class _JiraViewState extends State<JiraView> {
  late final _issueController = TextEditingController();
  late final _hoursController = TextEditingController();
  late final _dateController = TextEditingController();
  late final _repetitionsController = TextEditingController();
  final _textControllers = [];

  late JiraResponse _jiraResponse = JiraResponse();
  static String _url = '';

  @override
  void initState() {
    _textControllers.add(_hoursController);
    _textControllers.add(_dateController);
    _textControllers.add(_issueController);
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _createUrlByEnvironment(AppConfig config) {
    return config.apiBaseUrl;
  }

  void _getData() async {
    if (_isCorrectValidationFields(isSimple: true)) {
      final String issue = _issueController.text;
      final response = await widget.controller.getData(_url, issue);

      if (widget.controller.isOkStatusCode(response.statusCode)) {
        Map<String, dynamic> map = jsonDecode(response.body);
        setState(() {
          _jiraResponse = JiraResponse.fromJson(map);
        });
      }

      _handleReponse(response);
    }
  }

  void _postData() async {
    if (_isCorrectValidationFields()) {
      final String issue = _issueController.text;
      final double hours = double.parse(_hoursController.text);
      final String date = _dateController.text;
      var repetitions = int.tryParse(_repetitionsController.text);
      repetitions ??= 1;
      final response = await widget.controller
          .postData(_url, issue, hours, date, repetitions);
      _handleReponse(response, extraText: response.reasonPhrase);

      if (widget.controller.isOkStatusCode(response.statusCode)) {
        _getData();
      }
    }
  }

  Future<void> _deleteData(Worklog worklog) async {
    if (_isCorrectValidationFields(isSimple: true)) {
      late String? id = worklog.id;
      late String? issueId = worklog.issueId;
      if (id != null && issueId != null) {
        final response = await widget.controller.deleteData(_url, id, issueId);
        _handleReponse(response);

        if (widget.controller.isOkStatusCode(response.statusCode)) {
          _getData();
        }
      }
    }
  }

  void _handleReponse(response, {extraText}) {
    String text = '';
    if (widget.controller.isOkStatusCode(response.statusCode)) {
      debugPrint('Successful request');
      text = extraText != null && extraText != ''
          ? extraText
          : AppLocalizations.of(context)?.successfulRequest;
    } else {
      text =
          "${AppLocalizations.of(context)?.errorRequest} | ${response.reasonPhrase}";
      debugPrint("An error has ocurred in the request | $response");
    }
    _showMessageSnackBar(text);
  }

  void _showMessageSnackBar(String text) {
    final snackBar = SnackBar(
      showCloseIcon: true,
      closeIconColor: Theme.of(context).secondaryHeaderColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      content: Text(text),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _getInitialDate(),
        firstDate: DateTime(DateTime.now().year),
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime val) =>
            val.weekday == DateTime.saturday || val.weekday == DateTime.sunday
                ? false
                : true);

    if (pickedDate != null) {
      debugPrint(pickedDate.toString());
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      debugPrint(formattedDate);

      setState(() {
        _dateController.text = formattedDate;
      });
    } else {
      //_showMessageSnackBar("Date is not selected");
      debugPrint("Date is not selected");
    }
  }

  DateTime _getInitialDate() {
    var initialDate = DateTime.now();
    if (initialDate.weekday == DateTime.saturday) {
      initialDate = initialDate.add(const Duration(days: 2));
    } else if (initialDate.weekday == DateTime.sunday) {
      initialDate = initialDate.add(const Duration(days: 1));
    }
    return initialDate;
  }

  bool _isCorrectValidationFields({isSimple = false}) {
    late bool isCorrect = true;
    if (isSimple) {
      if (_issueController.text.isEmpty) {
        _showMessageSnackBar(AppLocalizations.of(context)?.issueRequired ?? '');
        return false;
      }
    } else {
      for (TextEditingController controller in _textControllers) {
        if (controller.text.isEmpty) {
          _showMessageSnackBar(
              AppLocalizations.of(context)?.someFieldsRequired ?? '');
          isCorrect = false;
          break;
        }
      }
    }

    return isCorrect;
  }

  @override
  Widget build(BuildContext context) {
    AppConfig config = AppConfig.of(context)!;
    _url = _createUrlByEnvironment(config);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: SizedBox(
                            child: TextField(
                                keyboardType: TextInputType.text,
                                controller: _issueController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText:
                                      AppLocalizations.of(context)?.issue,
                                )),
                          )),
                      const SizedBox(height: 24.0),
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: SizedBox(
                          child: TextField(
                            keyboardType: TextInputType.datetime,
                            controller: _dateController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              suffixIcon: const Icon(Icons.calendar_today),
                              labelText:
                                  AppLocalizations.of(context)?.startDate,
                            ),
                            readOnly: true,
                            onTap: _showDatePicker,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: _hoursController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: AppLocalizations.of(context)?.hours,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _repetitionsController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)?.repetitions,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Expanded(
                child: JiraListView(
              jiraResponse: _jiraResponse,
              onDeleteData: _deleteData,
            ))
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: 50.0,
        ),
      ),
      floatingActionButton: Container(
          margin: const EdgeInsets.all(10),
          child: SpeedDial(
            heroTag: 'more',
            useRotationAnimation: true,
            direction: SpeedDialDirection.up,
            icon: Icons.expand_less,
            activeIcon: Icons.expand_more,
            closeManually: false,
            curve: Curves.bounceIn,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.send),
                label: AppLocalizations.of(context)!.log,
                onTap: () => _postData(),
              ),
              SpeedDialChild(
                child: const Icon(Icons.refresh),
                label: AppLocalizations.of(context)!.load,
                onTap: () => _getData(),
              ),
            ],
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
}
