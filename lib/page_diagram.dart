import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
//import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  ChartData({
    this.group,
    this.longdrink,
    this.beer,
    this.shot,
    this.lutz,
  });

  final String? group;
  final int? longdrink;
  final int? beer;
  final int? shot;
  final int? lutz;

  int get total => (longdrink ?? 0) + (beer ?? 0) + (shot ?? 0) + (lutz ?? 0);
}

class PageDiagram extends StatefulWidget {
  const PageDiagram({super.key});

  @override
  State<PageDiagram> createState() => _PageDiagramState();
}

class _PageDiagramState extends State<PageDiagram> {
  final ScrollController _scrollController = ScrollController();
  List<ChartData>? _chartData = [];
  late Timer _scrollTimer;
  late Timer _chartDataReloadTimer;
  double barHeight = 0;
  int? maxValue;
  BuildContext? _popupContext;
  bool _isPopupVisible = false;
  GlobalKey<_RacePopupWidgetState>? _popupKey;

  int totalBarsVisible = 5;
  int gridInterval = 10;
  double groupNameSpaceFactor = 0.15; //Anteilig an ganzer Breite
  int emptyCountRightOfFirst = 10;
  int chasingThreshold = 5;

  bool showPopup = false;
  String chaserGroupName = "";
  String leaderGroupName = "";

  @override
  void initState() {
    super.initState();

    _loadChartData();
    _startAutoReloadChartData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoReloadChartData() {
    _chartDataReloadTimer = Timer.periodic(Duration(seconds: 7), (_) {
      _loadChartData();
    });
  }

  Future<void> _loadChartData() async {
    try {
      Map generalSettings = await MockDataPage0().getChartSettings();
      List<Map> newDataMapList = await MockDataPage0().getRandomChartData();
      Map popupData = await MockDataPage0().getPopup();

      List<ChartData> newData = [];
      for (var newDataMap in newDataMapList) {
        newData.add(ChartData(
            group: newDataMap["group"],
            longdrink: newDataMap["longdrink"],
            beer: newDataMap["beer"],
            shot: newDataMap["shot"],
            lutz: newDataMap["lutz"]));
      }
      if (mounted) {
        setState(() {
          totalBarsVisible = generalSettings["totalBarsVisible"];
          gridInterval = generalSettings["gridInterval"];
          groupNameSpaceFactor = generalSettings["groupNameSpaceFactor"];
          emptyCountRightOfFirst = generalSettings["emptyCountRightOfFirst"];
          chasingThreshold = generalSettings["chasingThreshold"];

          showPopup = popupData["showPopup"];
          chaserGroupName = popupData["chaserGroupName"];
          leaderGroupName = popupData["leaderGroupName"];

          _chartData = newData;
          _chartData?.sort((a, b) {
            return b.total.compareTo(a.total);
          });
          maxValue = _chartData?[0].total ?? 0 + 50;

          final medals = ['🥇 ', '🥈 ', '🥉 '];
          for (int i = 0; i < _chartData!.length; i++) {
            final originalName = _chartData![i].group.toString().replaceAll(RegExp(r'[🥇🥈🥉]'), '');
            if (i < 3) {
              _chartData![i] = ChartData(
                group: '${medals[i]}$originalName',
                longdrink: _chartData![i].longdrink,
                beer: _chartData![i].beer,
                shot: _chartData![i].shot,
                lutz: _chartData![i].lutz,
              );
            }
          }
        });
      }
      buildPopup();
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
    }
  }

  void _startAutoScroll() {
    const duration = Duration(seconds: 2);

    _scrollTimer = Timer.periodic(duration, (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      final next = current + barHeight;

      _scrollController.animateTo(
        next >= (maxScroll + barHeight / 2) ? 0 : next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void buildPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (showPopup && !_isPopupVisible) {
        _isPopupVisible = true;
        _popupKey = GlobalKey<_RacePopupWidgetState>();

        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (popupCtx) {
            _popupContext = popupCtx;
            return RacePopupWidget(
              key: _popupKey,
              initialLeader: leaderGroupName,
              initialChaser: chaserGroupName,
              initialDiff: 5,
            );
          },
        );

        if (mounted) {
          setState(() {
            _isPopupVisible = false;
            _popupContext = null;
            _popupKey = null;
          });
        }
      } else if (!showPopup && _isPopupVisible && _popupContext != null) {
        Navigator.of(_popupContext!).pop();
        _isPopupVisible = false;
        _popupContext = null;
        _popupKey = null;
      } else if (_isPopupVisible && _popupKey?.currentState != null) {
        _popupKey?.currentState!.updateData(leaderGroupName, chaserGroupName, 5);
      }
    });
  }

  @override
  void dispose() {
    _chartDataReloadTimer.cancel();
    _scrollTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double getBarHeight(double screenHeight) {
    return screenHeight / 8;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MySize(context).h * 0.08;
    final legendBoxSize = MySize(context).h * 0.04;

    return Padding(
      padding: EdgeInsetsGeometry.all(padding),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Container(height: legendBoxSize, width: legendBoxSize, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 15),
                Text("Bargetränk", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ],
            ),
            Row(
              children: [
                Container(height: legendBoxSize, width: legendBoxSize, color: Theme.of(context).colorScheme.tertiary),
                SizedBox(width: 15),
                Text("Bier", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ],
            ),
            Row(
              children: [
                Container(height: legendBoxSize, width: legendBoxSize, color: cyanAccent),
                SizedBox(width: 15),
                Text("Shot", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ],
            ),
            Row(
              children: [
                Container(height: legendBoxSize, width: legendBoxSize, color: redAccent),
                SizedBox(width: 15),
                Text("Lutz", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ],
            ),
          ],
        ),
        SizedBox(height: 50),
        Expanded(
          child: (_chartData == null || _chartData!.isEmpty)
              ? Center(
                  child: CircularProgressIndicator(color: defaultOnPrimary),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    var textStyle = TextStyle(fontSize: 20, color: defaultOnPrimary);
                    var textPainter = TextPainter(
                        text: TextSpan(text: "20", style: textStyle),
                        maxLines: 1,
                        //textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor),
                        textDirection: TextDirection.ltr);
                    final Size size = (textPainter..layout()).size;

                    final availableHeight = constraints.maxHeight - size.height;
                    barHeight = (availableHeight / totalBarsVisible);
                    double frameLineWidth = 2;
                    var gridLine = Container(width: 1, height: availableHeight, color: defaultOnPrimary);
                    var groupNameWidth = constraints.maxWidth * groupNameSpaceFactor;
                    var chartWidth = constraints.maxWidth - groupNameWidth;
                    var gridCount = ((maxValue ?? 1) + emptyCountRightOfFirst) / gridInterval;

                    return Stack(children: <Widget>[
                      Positioned(
                          left: groupNameWidth,
                          child: Container(width: frameLineWidth, height: availableHeight, color: defaultOnPrimary)),
                      Positioned(
                          left: groupNameWidth,
                          child: Container(width: chartWidth, height: frameLineWidth, color: defaultOnPrimary)),
                      Positioned(
                          left: groupNameWidth + chartWidth - frameLineWidth,
                          child: Container(width: frameLineWidth, height: availableHeight, color: defaultOnPrimary)),
                      Positioned(
                          left: groupNameWidth,
                          top: availableHeight - frameLineWidth,
                          child: Container(width: chartWidth, height: frameLineWidth, color: defaultOnPrimary)),
                      ...List.generate(
                          (gridCount + 1).floor(),
                          (index) =>
                              Positioned(left: groupNameWidth + index * (chartWidth / gridCount), child: gridLine)),
                      ...List.generate(
                        (gridCount).floor(),
                        (index) => Positioned(
                          left: groupNameWidth + (index + 1) * (chartWidth / gridCount),
                          top: availableHeight,
                          child: Text(
                            ((index + 1) * gridInterval).toInt().toString(),
                            style: textStyle,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: availableHeight,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _chartData?.length,
                            itemBuilder: (context, index) {
                              final data = _chartData?[index];

                              Color groupNameColor = Colors.white;
                              int? currentTotal = _chartData?[index].total;

                              int? leadersTotal;
                              try {
                                leadersTotal = _chartData?[index - 1].total;
                              } catch (_) {}

                              int? chasersTotal;
                              try {
                                chasersTotal = _chartData?[index + 1].total;
                              } catch (_) {}

                              if (currentTotal != null) {
                                if (chasersTotal != null && (currentTotal - chasersTotal) < chasingThreshold) {
                                  groupNameColor = redAccent;
                                } else if (leadersTotal != null && (leadersTotal - currentTotal) < chasingThreshold) {
                                  groupNameColor = greenAccent;
                                }
                              }

                              return SizedBox(
                                height: barHeight,
                                child: Row(
                                  children: [
                                    Container(
                                      width: groupNameWidth,
                                      padding: EdgeInsets.only(right: 20),
                                      child: Text(
                                        data?.group ?? '',
                                        style:
                                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: groupNameColor),
                                      ),
                                    ),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final totalWidth = constraints.maxWidth;
                                          final longdrink = (data?.longdrink ?? 0).toDouble();
                                          final beer = (data?.beer ?? 0).toDouble();
                                          final shot = (data?.shot ?? 0).toDouble();
                                          final lutz = (data?.lutz ?? 0).toDouble();
                                          final maximumValue = (maxValue ?? 0) + emptyCountRightOfFirst;

                                          // Avoid division by zero
                                          if (maximumValue == 0) return const SizedBox();

                                          return Padding(
                                            padding:
                                                EdgeInsetsGeometry.symmetric(vertical: constraints.maxHeight * 0.15),
                                            child: index < 3
                                                ? Row(
                                                    children: [
                                                      Container(
                                                        height: double.infinity,
                                                        width: totalWidth * longdrink / maximumValue,
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      ),
                                                      Container(
                                                        height: double.infinity,
                                                        width: totalWidth * beer / maximumValue,
                                                        color: Theme.of(context).colorScheme.tertiary,
                                                      ),
                                                      Container(
                                                        height: double.infinity,
                                                        width: totalWidth * shot / maximumValue,
                                                        color: cyanAccent,
                                                      ),
                                                      Container(
                                                        height: double.infinity,
                                                        width: totalWidth * lutz / maximumValue,
                                                        color: redAccent,
                                                      ),
                                                    ],
                                                  )
                                                : Row(children: [
                                                    Container(
                                                      height: double.infinity,
                                                      width:
                                                          totalWidth * (longdrink + beer + shot + lutz) / maximumValue,
                                                      color: Colors.grey,
                                                    )
                                                  ]),
                                          );
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ]);
                  },
                ),
        ),
      ]),
    );
  }
}

class RacePopupWidget extends StatefulWidget {
  final String initialLeader;
  final String initialChaser;
  final int initialDiff;

  const RacePopupWidget({
    required this.initialLeader,
    required this.initialChaser,
    required this.initialDiff,
    super.key,
  });

  @override
  State<RacePopupWidget> createState() => _RacePopupWidgetState();
}

class _RacePopupWidgetState extends State<RacePopupWidget> {
  late String leader;
  late String chaser;
  late int diff;

  @override
  void initState() {
    super.initState();
    leader = widget.initialLeader;
    chaser = widget.initialChaser;
    diff = widget.initialDiff;
  }

  void updateData(String newLeader, String newChaser, int newDiff) {
    setState(() {
      leader = newLeader;
      chaser = newChaser;
      diff = newDiff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍻', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            'Fasten your liver!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '$chaser is just $diff away from overtaking $leader!',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildProgressBar(chaser, 0.85, Colors.redAccent),
          const SizedBox(height: 10),
          _buildProgressBar(leader, 0.9, Colors.greenAccent),
          const SizedBox(height: 20),
          Text(
            'Only $diff more shots – chug chug chug!',
            style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
        ),
      ],
    );
  }
}

//the following PageDiagram can "scroll" by updating the data but there is no visible scroll effect. Also the colors are not corrected for this version

/* class PageDiagram extends StatefulWidget {
  const PageDiagram({super.key});

  @override
  State<PageDiagram> createState() => _PageDiagramState();
}

class _PageDiagramState extends State<PageDiagram> {
  _PageDiagramState();

  List<ChartData>? _chartData;
  int _startIndex = 0;
  late Timer _scrollTimer;
  final int visibleBarsCount = 5;

  @override
  void initState() {
    super.initState();
    _prepareData();
    _startAutoScroll();
  }

  void _prepareData() {
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
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      setState(() {
        final dataLength = _chartData!.length;
        _startIndex += 1;
        if (_startIndex + visibleBarsCount > dataLength) {
          _startIndex = 0; // Wieder von vorne
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleData = _chartData!.sublist(
      _startIndex,
      (_startIndex + visibleBarsCount).clamp(0, _chartData!.length),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
      child: SfCartesianChart(
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          zoomMode: ZoomMode.x,
        ),
        plotAreaBorderWidth: 1,
        plotAreaBorderColor: defaultOnPrimary,
        //title: ChartTitle(text: 'Saufometer'),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          textStyle: const TextStyle(fontSize: 30),
          padding: 20,
          itemPadding: 50,
        ),
        primaryXAxis: CategoryAxis(
          initialVisibleMinimum: _startIndex.toDouble(),
          initialVisibleMaximum: (_startIndex + visibleBarsCount).toDouble(),
          labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          labelFormat: '{value}',
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(width: 1, color: defaultOnPrimary),
          labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        series: <StackedBarSeries<ChartData, String>>[
          StackedBarSeries<ChartData, String>(
            dataSource: visibleData,
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
            dataSource: visibleData,
            xValueMapper: (ChartData data, int index) => data.group,
            yValueMapper: (ChartData data, int index) => index < ((_chartData?.length ?? 0) - 3) ? 0 : data.beer,
            name: 'Bier',
            color: Theme.of(context).colorScheme.tertiary,
            pointColorMapper: (data, index) =>
                index < ((_chartData?.length ?? 0) - 3) ? Colors.grey : Theme.of(context).colorScheme.tertiary,
          ),
          StackedBarSeries<ChartData, String>(
            dataSource: visibleData,
            xValueMapper: (ChartData data, int index) => data.group,
            yValueMapper: (ChartData data, int index) => index < ((_chartData?.length ?? 0) - 3) ? 0 : data.shot,
            name: 'Shot',
            color: cyanAccent,
            pointColorMapper: (data, index) => index < ((_chartData?.length ?? 0) - 3) ? Colors.grey : cyanAccent,
          ),
          StackedBarSeries<ChartData, String>(
            dataSource: visibleData,
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
    _scrollTimer.cancel();
    super.dispose();
  }
}
 */
