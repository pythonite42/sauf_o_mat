import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
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
  final int? longdrink;
  final int? shot;
  final int? beer;
  final int? lutz;
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
      ChartData(group: 'Gruppe3', longdrink: 30, shot: 11, beer: 22, lutz: 20),
      ChartData(group: 'Gruppe4', longdrink: 15, shot: 16, beer: 25, lutz: 40),
      ChartData(group: 'Gruppe5', longdrink: 20, shot: 21, beer: 30, lutz: 13),
      ChartData(group: 'Gruppe6', longdrink: 24, shot: 25, beer: 35, lutz: 11),
    ];
    _chartData?.sort((a, b) {
      final aSum = (a.longdrink ?? 0) * 2 + (a.shot ?? 0) + (a.beer ?? 0) + (a.lutz ?? 0);
      final bSum = (b.longdrink ?? 0) * 2 + (b.shot ?? 0) + (b.beer ?? 0) + (b.lutz ?? 0);
      return aSum.compareTo(bSum);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 1,
      //title: ChartTitle(text: 'Saufometer'),
      legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          textStyle: TextStyle(fontSize: 30),
          padding: 20,
          itemPadding: 50),
      plotAreaBorderColor: defaultOnPrimary,
      primaryXAxis: CategoryAxis(
        axisLine: AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0, color: defaultOnPrimary),
        labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      primaryYAxis: NumericAxis(
        axisLine: AxisLine(width: 0),
        labelFormat: '{value}',
        majorTickLines: MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
          width: 1,
          color: defaultOnPrimary,
        ),
        labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      series: <StackedBarSeries<ChartData, String>>[
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.lutz,
          name: 'Lutz',
          pointColorMapper: (data, index) => index < 3 ? Colors.grey : redAccent,
        ),
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.longdrink == null ? null : data.longdrink! * 2,
          name: 'Bargetränk',
          pointColorMapper: (data, index) => index < 3 ? Colors.grey : Theme.of(context).colorScheme.tertiary,
        ),
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.beer,
          name: 'Bier',
          pointColorMapper: (data, index) => index < 3 ? Colors.grey : cyanAccent,
        ),
        StackedBarSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, int index) => data.group,
          yValueMapper: (ChartData data, int index) => data.shot,
          name: 'Shot',
          pointColorMapper: (data, index) => index < 3 ? Colors.grey : Theme.of(context).colorScheme.secondary,
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
