import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  ChartData({
    this.group,
    this.longdrink,
    this.shot,
    this.beer,
    this.lutz,
  });

  final dynamic group;
  final num? longdrink;
  final num? shot;
  final num? beer;
  final num? lutz;
}

class PageDiagram extends StatefulWidget {
  const PageDiagram({super.key});

  @override
  State<PageDiagram> createState() => _PageDiagramState();
}

class _PageDiagramState extends State<PageDiagram> {
  _PageDiagramState();

  List<ChartData>? _chartData;

  @override
  void initState() {
    _chartData = <ChartData>[
      ChartData(group: 'Gruppe1', longdrink: 6, shot: 6, beer: 18, lutz: 12),
      ChartData(group: 'Gruppe2', longdrink: 8, shot: 8, beer: 19, lutz: 15),
      ChartData(group: 'Gruppe3', longdrink: 12, shot: 11, beer: 22, lutz: 20),
      ChartData(group: 'Gruppe4', longdrink: 15, shot: 16, beer: 25, lutz: 40),
      ChartData(group: 'Gruppe5', longdrink: 20, shot: 21, beer: 30, lutz: 13),
      ChartData(group: 'Gruppe6', longdrink: 24, shot: 25, beer: 35, lutz: 11),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 1,
      //title: ChartTitle(text: 'Saufometer'),
      legend: Legend(isVisible: true, position: LegendPosition.top),
      primaryXAxis: const CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        axisLine: AxisLine(width: 0),
        labelFormat: '{value}',
        majorTickLines: MajorTickLines(size: 0),
      ),
      series: <StackedBarSeries<ChartData, String>>[
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.longdrink == null ? null : data.longdrink! * 2,
          name: 'Bargetränk',
        ),
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.shot,
          name: 'Shot',
        ),
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.beer,
          name: 'Bier',
        ),
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.lutz,
          name: 'Lutz',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _chartData!.clear();
    super.dispose();
  }
}
