import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_view.dart';
import 'package:worklogs_jira/src/helper/date_helper.dart';
import 'package:worklogs_jira/src/helper/widget_helper.dart';
import '../settings/settings_view.dart';
import 'jira_controller.dart';
import 'worklog_list/worklog_list_view.dart';
import '../models/worklog_response.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late final _dateController =
      TextEditingController(text: DateHelper.formatDate(DateTime.now()));
  late final _repetitionsController = TextEditingController();
  final _textControllers = [];
  bool _isLoading = false;
  late WorklogResponse _worklogResponse = WorklogResponse();

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

  void _getData() async {
    if (_isCorrectValidationFields(isSimple: true)) {
      setState(() {
        _isLoading = true;
      });
      final String issue = _issueController.text;
      final response = await widget.controller.getData(issue);

      if (widget.controller.isOkStatusCode(response.statusCode)) {
        Map<String, dynamic> map = jsonDecode(response.body);
        setState(() {
          _worklogResponse = WorklogResponse.fromJson(map);
        });
        widget.controller.setLastIssue(issue);
      }
      _handleReponse(response);
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _postData() async {
    if (_isCorrectValidationFields()) {
      setState(() {
        _isLoading = true;
      });
      final String issue = _issueController.text;
      final double hours = double.parse(_hoursController.text);
      final String date = _dateController.text;
      var repetitions = int.tryParse(_repetitionsController.text);
      repetitions ??= 1;
      final response =
          await widget.controller.postData(issue, hours, date, repetitions);
      _handleReponse(response, extraText: response.reasonPhrase);

      if (widget.controller.isOkStatusCode(response.statusCode)) {
        _getData();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteData(Worklog worklog) async {
    if (_isCorrectValidationFields(isSimple: true)) {
      setState(() {
        _isLoading = true;
      });
      late String? id = worklog.id;
      late String? issueId = worklog.issueId;
      if (id != null && issueId != null) {
        final response = await widget.controller.deleteData(id, issueId);
        _handleReponse(response);

        if (widget.controller.isOkStatusCode(response.statusCode)) {
          _getData();
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _handleReponse(response, {extraText}) {
    String text = '';
    if (widget.controller.isOkStatusCode(response.statusCode)) {
      text = extraText != null && extraText != ''
          ? extraText
          : AppLocalizations.of(context)?.successfulRequest;
    } else {
      text =
          "${AppLocalizations.of(context)?.errorRequest} | ${response.reasonPhrase}";
      debugPrint("An error has ocurred in the request | $response");
    }
    WidgetHelper.showMessageSnackBar(context, text);
  }

  void _showDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateHelper.getInitialDate(),
        firstDate: DateTime(DateTime.now().year - 3),
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime val) =>
            val.weekday == DateTime.saturday || val.weekday == DateTime.sunday
                ? false
                : true);

    if (pickedDate != null) {
      debugPrint(pickedDate.toString());
      setState(() {
        _dateController.text = DateHelper.formatDate(pickedDate);
      });
    } else {
      debugPrint("Date is not selected");
    }
  }

  bool _isCorrectValidationFields({isSimple = false}) {
    late bool isCorrect = true;
    if (isSimple) {
      if (_issueController.text.isEmpty) {
        WidgetHelper.showMessageSnackBar(
            context, AppLocalizations.of(context)?.issueRequired ?? '');
        return false;
      }
    } else {
      for (TextEditingController controller in _textControllers) {
        if (controller.text.isEmpty) {
          WidgetHelper.showMessageSnackBar(
              context, AppLocalizations.of(context)?.someFieldsRequired ?? '');
          isCorrect = false;
          break;
        }
      }
    }

    return isCorrect;
  }

  _launchURL() async {
    final uri = Uri.parse('https://github.com/alejandrobolano/worklogs_jira');
    final isPossibleLaunchUrl = await canLaunchUrl(uri);
    if (isPossibleLaunchUrl) {
      await launchUrl(uri);
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLastIssueLoaded = false;
    widget.controller.getLastIssue().then((value) {
      if (value != null &&
          value.isNotEmpty &&
          _issueController.text.isEmpty &&
          !isLastIssueLoaded) {
        _issueController.text = value;
        _getData();
        isLastIssueLoaded = true;
      }
    });
    widget.controller.getIssuePreffix().then((value) {
      if (value != null && value.isNotEmpty && _issueController.text.isEmpty) {
        _issueController.text = value;
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
              onPressed: () {
                _launchURL();
              },
              icon: const Icon(Icons.code)),
          IconButton(
              onPressed: () {
                Navigator.restorablePushNamed(context, DashboardView.routeName);
              },
              icon: const Icon(Icons.insert_chart_outlined_rounded)),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          )
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
                                labelText: AppLocalizations.of(context)?.issue,
                              ),
                              onChanged: (value) => _issueController.text,
                            ),
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
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: LinearProgressIndicator(
                  semanticsLabel: AppLocalizations.of(context)?.loading,
                ),
              ),
            const SizedBox(height: 24.0),
            Expanded(
                child: WorklogListView(
              worklogResponse: _worklogResponse,
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
