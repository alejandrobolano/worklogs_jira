import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:worklogs_jira/config/app_config.dart';
import 'package:worklogs_jira/src/dashboard/charts/bars_chart_view.dart';
import 'package:worklogs_jira/src/dashboard/charts/pie_chart_view.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_controller.dart';
import 'package:worklogs_jira/src/dashboard/charts/indicator_view.dart';
import 'package:worklogs_jira/src/dashboard/worklist/worklist_view.dart';
import 'package:worklogs_jira/src/helper/date_helper.dart';
import 'package:worklogs_jira/src/helper/widget_helper.dart';
import 'package:worklogs_jira/src/models/worklist_response.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.controller});

  static const routeName = '/dashboard';
  final DashboardController controller;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

enum ChartType { none, bars, pie }

class _DashboardViewState extends State<DashboardView> {
  static String _url = '';
  late WorklistResponse _worklistResponse = WorklistResponse();
  late final _startRangeDateController =
      TextEditingController(text: DateHelper.getFirstDayOfMonth());
  late final _finishRangeDateController =
      TextEditingController(text: DateHelper.formatDate(DateTime.now()));
  bool _isLoading = false;
  bool _isBarsChartVisible = false;
  bool _isPieChartVisible = false;
  List<Widget> _indicators = [];
  List<PieChartSectionData> _sections = [];
  List<BarChartGroupData> _bars = [];
  late double _biggerTimespent = 0;
  final Map<int, String> _tooltipTitle = {};

  int touchedIndex = -1;

  @override
  void dispose() {
    super.dispose();
  }

  void _getData() async {
    setState(() {
      _isLoading = true;
    });
    final response = await widget.controller.getWorklist(
        _url, _startRangeDateController.text, _finishRangeDateController.text);
    _handleReponse(response);
    setState(() {
      _isLoading = false;
    });
  }

  void _handleReponse(response, {extraText}) {
    String text = '';

    if (widget.controller.isOkStatusCode(response.statusCode)) {
      Map<String, dynamic> map = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _worklistResponse = WorklistResponse.fromJson(map);
          fillData();
        });
      }
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

  String _createUrlByEnvironment(AppConfig config) {
    return config.apiBaseUrl;
  }

  void _showDatePicker(TextEditingController rangeController) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateHelper.getInitialDate(),
        firstDate: DateTime(DateTime.now().year),
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime val) =>
            val.weekday == DateTime.saturday || val.weekday == DateTime.sunday
                ? false
                : true);

    if (pickedDate != null) {
      debugPrint(pickedDate.toString());
      String formattedDate = DateHelper.formatDate(pickedDate);
      setState(() {
        rangeController.text = formattedDate;
      });
    } else {
      debugPrint("Date is not selected");
    }
  }

  void fillData() {
    final issues = _worklistResponse.issues;
    _indicators = [];
    _sections = [];
    _bars = [];
    if (mounted && issues != null) {
      for (int i = 0; i < issues.length; i++) {
        Issues element = issues[i]!;
        Color color = WidgetHelper.getRandomColor();

        if (issues.length < 16) {
          _indicators.add(
              Indicator(color: color, text: element.key ?? "", isSquare: true));

          _indicators.add(const SizedBox(
            height: 4,
          ));
        }

        double timespent = (element.fields!.timespent ?? 0) / 3600.0;
        _biggerTimespent =
            timespent > _biggerTimespent ? timespent : _biggerTimespent;
        final isTouched = i == touchedIndex;
        final fontSize = isTouched ? 25.0 : 16.0;
        _sections.add(PieChartSectionData(
            value: timespent,
            color: color,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            )));

        _bars.add(BarChartGroupData(groupVertically: true, x: i, barRods: [
          BarChartRodData(
            toY: timespent,
            color: color,
          )
        ]));

        _tooltipTitle[i] = element.key ?? "";
      }
      _worklistResponse.issues?.forEach((element) => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    AppConfig config = AppConfig.of(context)!;
    _url = _createUrlByEnvironment(config);
    //_getData();
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
          ),
          actions: <Widget>[
            PopupMenuButton<ChartType>(
              tooltip: AppLocalizations.of(context)?.showChart,
              onSelected: (ChartType result) {
                switch (result) {
                  case ChartType.bars:
                    setState(() {
                      _isBarsChartVisible = !_isBarsChartVisible;
                    });
                  case ChartType.pie:
                    setState(() {
                      _isPieChartVisible = !_isPieChartVisible;
                    });
                  default:
                    _isBarsChartVisible = false;
                    _isPieChartVisible = false;
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                CheckedPopupMenuItem(
                  checked: _isBarsChartVisible,
                  value: ChartType.bars,
                  child: Text(AppLocalizations.of(context)?.barsChart ?? ""),
                ),
                CheckedPopupMenuItem(
                  checked: _isPieChartVisible,
                  value: ChartType.pie,
                  child: Text(AppLocalizations.of(context)?.pieChart ?? ""),
                ),
              ],
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: SizedBox(
                          child: TextField(
                            keyboardType: TextInputType.datetime,
                            controller: _startRangeDateController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              suffixIcon: const Icon(Icons.calendar_today),
                              labelText:
                                  AppLocalizations.of(context)?.startRange,
                            ),
                            readOnly: true,
                            onTap: () =>
                                _showDatePicker(_startRangeDateController),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: SizedBox(
                          child: TextField(
                            keyboardType: TextInputType.datetime,
                            controller: _finishRangeDateController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              suffixIcon: const Icon(Icons.calendar_today),
                              labelText:
                                  AppLocalizations.of(context)?.finishRange,
                            ),
                            readOnly: true,
                            onTap: () =>
                                _showDatePicker(_finishRangeDateController),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            if (_worklistResponse.issues != null && _isPieChartVisible)
              PieChartView(
                  pieWidgetModel: PieWidgetModel(
                      indicators: _indicators, sections: _sections)),
            if (_worklistResponse.issues != null && _isBarsChartVisible)
              BarsChartView(
                  barsWidgetModel: BarsWidgetModel(
                      indicators: _indicators,
                      sections: _sections,
                      bars: _bars,
                      maxY: _biggerTimespent,
                      tooltipTitles: _tooltipTitle)),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: LinearProgressIndicator(
                  semanticsLabel: AppLocalizations.of(context)?.loading,
                ),
              ),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  child: WorkListView(
                    worklogResponse: _worklistResponse,
                  )),
            )
          ]),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Container(
            height: 50.0,
          ),
        ),
        floatingActionButton: Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
                onPressed: () => _getData(),
                heroTag: 'update',
                child: const Icon(Icons.update))),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniEndDocked,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling);
  }
}
