import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarsChartView extends StatelessWidget {
  const BarsChartView({super.key, required this.barsWidgetModel});
  final BarsWidgetModel barsWidgetModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Container(
                padding: const EdgeInsets.only(left: 10, bottom: 24, top: 24),
                width: double.infinity,
                height: 250,
                child: BarChart(
                  BarChartData(
                      barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(getTooltipItem:
                              (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                                '${barsWidgetModel.tooltipTitles[group.x]}\n${rod.toY} h',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold));
                          })),
                      titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          )),
                      gridData: const FlGridData(show: true),
                      barGroups: barsWidgetModel.bars,
                      borderData: FlBorderData(show: false),
                      maxY: barsWidgetModel.maxY +
                          (10 / 100 * barsWidgetModel.maxY).toInt(),
                      minY: 0),
                ))),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: barsWidgetModel.indicators,
        )
      ],
    );
  }
}

class BarsWidgetModel {
  List<Widget> indicators = [];
  List<PieChartSectionData> sections = [];
  List<BarChartGroupData> bars = [];
  double maxY;
  Map<int, String> tooltipTitles;

  BarsWidgetModel({
    required this.indicators,
    required this.sections,
    required this.bars,
    required this.maxY,
    required this.tooltipTitles,
  });
}
