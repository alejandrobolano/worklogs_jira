import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:worklogs_jira/src/dashboard/charts/bars_chart_view.dart';
import 'package:worklogs_jira/src/dashboard/charts/pie_chart_view.dart';
import 'package:worklogs_jira/src/dashboard/dashboard_controller.dart';
import 'package:worklogs_jira/src/dashboard/charts/indicator_view.dart';
import 'package:worklogs_jira/src/dashboard/worklist/worklist_view.dart';
import 'package:worklogs_jira/src/dashboard/logged_tasks_table.dart';
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

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
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
  late TabController _tabController;

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _getData() async {
    setState(() {
      _isLoading = true;
    });
    final response = await widget.controller.getWorklist(
        _startRangeDateController.text, _finishRangeDateController.text);
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

  void _showDatePicker(TextEditingController rangeController) async {
    List<int> notWorkedDays = await widget.controller.getNotWorkedDays();
    if (!context.mounted) return;
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateHelper.getInitialDate(notWorkedDays),
        firstDate: DateTime(DateTime.now().year - 3),
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime val) =>
            !notWorkedDays.contains(val.weekday));

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

  _launchURL(String? key) async {
    final jiraPath = await widget.controller.getJiraBasePath();
    final uri = Uri.parse("$jiraPath/browse/$key");
    final isPossibleLaunchUrl = await canLaunchUrl(uri);
    if (isPossibleLaunchUrl) {
      await launchUrl(uri);
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<Map<String, dynamic>> _getWorklogs(String issueKey) async {
    try {
      final response = await widget.controller.getIssueWorklogs(issueKey);
      if (widget.controller.isOkStatusCode(response.statusCode)) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching worklogs for $issueKey: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
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
                      _isPieChartVisible = !_isBarsChartVisible;
                    });
                  case ChartType.pie:
                    setState(() {
                      _isPieChartVisible = !_isPieChartVisible;
                      _isBarsChartVisible = !_isPieChartVisible;
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
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: LinearProgressIndicator(
                  semanticsLabel: AppLocalizations.of(context)?.loading,
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.list), text: 'Lista'),
                        Tab(icon: Icon(Icons.table_chart), text: 'Tabla'),
                      ],
                    ),
                    SizedBox(
                      height: 500,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 24),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            WorkListView(
                              worklogResponse: _worklistResponse,
                              launchUrl: _launchURL,
                            ),
                            LoggedTasksTable(
                              issues: _worklistResponse.issues,
                              onTaskTap: _launchURL,
                              getWorklogsCallback: _getWorklogs,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
        bottomNavigationBar: const BottomAppBar(
          shape: CircularNotchedRectangle(),
          height: 65,
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
