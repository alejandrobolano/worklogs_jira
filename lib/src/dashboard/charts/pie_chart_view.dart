import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartView extends StatefulWidget {
  final PieWidgetModel pieWidgetModel;
  const PieChartView({super.key, required this.pieWidgetModel});

  @override
  State<PieChartView> createState() => _PieChartViewState();
}

class _PieChartViewState extends State<PieChartView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            height: 200,
            child: PieChart(
              swapAnimationCurve: Curves.linear,
              PieChartData(
                pieTouchData: PieTouchData(
                  enabled: true,
                  /*touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },*/
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: widget.pieWidgetModel.sections,
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.pieWidgetModel.indicators,
        ),
      ],
    );
  }
}

class PieWidgetModel {
  List<Widget> indicators = [];
  List<PieChartSectionData> sections = [];

  PieWidgetModel({required this.indicators, required this.sections});
}
