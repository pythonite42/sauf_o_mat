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

  int get total => (longdrink ?? 0) * 2 + (shot ?? 0) + (beer ?? 0) + (lutz ?? 0);
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
      ChartData(group: 'Gruppe3', longdrink: 3, shot: 11, beer: 22, lutz: 20),
      ChartData(group: 'Gruppe4', longdrink: 15, shot: 16, beer: 25, lutz: 40),
      ChartData(group: 'Gruppe5', longdrink: 20, shot: 21, beer: 30, lutz: 13),
      ChartData(group: 'Gruppe6', longdrink: 24, shot: 25, beer: 35, lutz: 11),
      ChartData(group: 'Gruppe7', longdrink: 22, shot: 25, beer: 35, lutz: 11),
      ChartData(group: 'Gruppe8', longdrink: 12, shot: 15, beer: 25, lutz: 16),
    ];
    _chartData?.sort((a, b) {
      final aSum = (a.longdrink ?? 0) * 2 + (a.shot ?? 0) + (a.beer ?? 0) + (a.lutz ?? 0);
      final bSum = (b.longdrink ?? 0) * 2 + (b.shot ?? 0) + (b.beer ?? 0) + (b.lutz ?? 0);
      return aSum.compareTo(bSum);
    });

    final medals = ['🥇 ', '🥈 ', '🥉 '];
    for (int i = 0; i < _chartData!.length; i++) {
      final originalName = _chartData![i].group.toString().replaceAll(RegExp(r'[🥇🥈🥉]'), '');
      if (i > _chartData!.length - 4) {
        _chartData![i] = ChartData(
          group: '${medals[_chartData!.length - 1 - i]}$originalName',
          longdrink: _chartData![i].longdrink,
          shot: _chartData![i].shot,
          beer: _chartData![i].beer,
          lutz: _chartData![i].lutz,
        );
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(30, 0, 30, 30),
      child: SfCartesianChart(
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
            yValueMapper: (ChartData data, int index) => index < ((_chartData?.length ?? 0) - 3)
                ? data.total
                : (data.longdrink == null ? null : data.longdrink! * 2),
            name: 'Bargetränk',
            color: Theme.of(context).colorScheme.secondary,
            pointColorMapper: (data, index) =>
                index < ((_chartData?.length ?? 0) - 3) ? Colors.grey : Theme.of(context).colorScheme.secondary,
          ),
          StackedBarSeries<ChartData, String>(
            dataSource: _chartData,
            xValueMapper: (ChartData data, int index) => data.group,
            yValueMapper: (ChartData data, int index) => index < ((_chartData?.length ?? 0) - 3) ? 0 : data.beer,
            name: 'Bier',
            color: Theme.of(context).colorScheme.tertiary,
            pointColorMapper: (data, index) =>
                index < ((_chartData?.length ?? 0) - 3) ? Colors.grey : Theme.of(context).colorScheme.tertiary,
          ),
          StackedBarSeries<ChartData, String>(
            dataSource: _chartData,
            xValueMapper: (ChartData data, int index) => data.group,
            yValueMapper: (ChartData data, int index) => index < ((_chartData?.length ?? 0) - 3) ? 0 : data.shot,
            name: 'Shot',
            color: cyanAccent,
            pointColorMapper: (data, index) => index < ((_chartData?.length ?? 0) - 3) ? Colors.grey : cyanAccent,
          ),
          StackedBarSeries<ChartData, String>(
            dataSource: _chartData,
            xValueMapper: (ChartData data, int index) => data.group,
            yValueMapper: (ChartData data, int index) => index < ((_chartData?.length ?? 0) - 3) ? 0 : data.lutz,
            name: 'Lutz',
            color: redAccent,
            pointColorMapper: (data, index) => index < ((_chartData?.length ?? 0) - 3) ? Colors.grey : redAccent,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chartData!.clear();
    super.dispose();
  }
}
