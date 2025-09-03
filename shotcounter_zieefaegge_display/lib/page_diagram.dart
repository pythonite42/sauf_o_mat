import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_connection.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class ChartData {
  ChartData({
    this.group,
    this.longdrink,
    this.beer,
    this.shot,
    this.lutz,
    this.status,
  });

  final String? group;
  final int? longdrink;
  final int? beer;
  final int? shot;
  final int? lutz;
  final String? status;

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
  bool _popupCooldown = false;

  bool showPopup = false;
  String popupDataId = "";
  String imageUrl = "";
  String chaserGroupName = "";
  String leaderGroupName = "";
  int leaderPoints = 0;

  Color fontColor = defaultOnScroll;

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
    _chartDataReloadTimer = Timer.periodic(Duration(seconds: CustomDurations.reloadDataDiagram), (_) {
      _loadChartData();
    });
  }

  Future<void> _loadChartData() async {
    try {
      List<Map> newDataMapList = await SalesforceService().getPageDiagram();

      Map popupData = await SalesforceService().getPageDiagramPopUp();

      List<ChartData> newData = [];
      for (var newDataMap in newDataMapList) {
        newData.add(
          ChartData(
            group: newDataMap["group"],
            longdrink: newDataMap["longdrink"],
            beer: newDataMap["beer"],
            shot: newDataMap["shot"],
            lutz: newDataMap["lutz"],
            status: newDataMap["status"],
          ),
        );
      }
      if (mounted) {
        setState(() {
          showPopup = popupData["showPopup"];
          popupDataId = popupData["popupDataId"];
          imageUrl = popupData["imageUrl"];
          chaserGroupName = popupData["chaserGroupName"];
          leaderGroupName = popupData["leaderGroupName"];
          leaderPoints = popupData["leaderPoints"];

          _chartData = newData;
          _chartData?.sort((a, b) {
            return b.total.compareTo(a.total);
          });
          maxValue = _chartData?[0].total ?? 0 + 50;

          /* final medals = ['🥇 ', '🥈 ', '🥉 '];
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
          } */
        });
      }
      buildPopup();
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
    }
  }

  void _startAutoScroll() {
    var duration = Duration(seconds: CustomDurations.chartAutoScroll);

    _scrollTimer = Timer.periodic(duration, (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      final next = current + barHeight;

      _scrollController.animateTo(
        next >= (maxScroll + barHeight / 2) ? 0 : next,
        duration: Duration(milliseconds: CustomDurations.speedChartScroll),
        curve: Curves.easeInOut,
      );
    });
  }

  void buildPopup() {
    if (_popupCooldown || _isPopupVisible || !showPopup) return;

    _popupCooldown = true;
    _isPopupVisible = true;
    _popupKey = GlobalKey<_RacePopupWidgetState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (popupCtx) {
        _popupContext = popupCtx;
        return RacePopupWidget(
          key: _popupKey,
          initialImageUrl: imageUrl,
          initialLeader: leaderGroupName,
          initialChaser: chaserGroupName,
          initialPointsOfLeader: leaderPoints,
        );
      },
    );
    SalesforceService().setPageDiagramVisualizedAt(popupDataId, DateTime.now());

    Future.delayed(Duration(seconds: CustomDurations.showPopup), () {
      try {
        Navigator.of(_popupContext!).pop();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isPopupVisible = false;
          _popupContext = null;
          _popupKey = null;
        });
      }

      Future.delayed(Duration(seconds: CustomDurations.popUpCooldown), () {
        _popupCooldown = false;
      });
    });
  }

  @override
  void dispose() {
    _chartDataReloadTimer.cancel();
    _scrollTimer.cancel();
    _scrollController.dispose();

    try {
      Navigator.of(_popupContext!).pop();
    } catch (_) {}
    super.dispose();
  }

  double getBarHeight(double screenHeight) {
    return screenHeight / 8;
  }

  @override
  Widget build(BuildContext context) {
    final legendBoxSize = MySize(context).h * 0.045;
    final fontSizeLegend = 30.0;

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            child: Image.asset(
              'assets/scroll.png',
              width: MySize(context).w,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.only(
            left: MySize(context).h * 0.2,
            top: MySize(context).h * 0.12,
            right: MySize(context).h * 0.08,
            bottom: MySize(context).h * 0.04,
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                /* SizedBox(width: MySize(context).w * 0.01),
                Text("Leaderboard", style: TextStyle(fontSize: fontSizeLegend * 2, fontWeight: FontWeight.bold)),
                SizedBox(width: MySize(context).w * 0.05), */
                //SizedBox(width: MySize(context).w * 0.2),
                SizedBox(width: MySize(context).w * 0.05),

                Row(
                  children: [
                    Container(height: legendBoxSize, width: legendBoxSize, color: sunsetRed),
                    SizedBox(width: MySize(context).w * 0.01),
                    Text("Bargetränk", style: TextStyle(fontSize: fontSizeLegend, fontWeight: FontWeight.bold))
                  ],
                ),
                SizedBox(width: MySize(context).w * 0.05),
                Row(
                  children: [
                    Container(height: legendBoxSize, width: legendBoxSize, color: westernGold),
                    SizedBox(width: MySize(context).w * 0.01),
                    Text("Bier", style: TextStyle(fontSize: fontSizeLegend, fontWeight: FontWeight.bold))
                  ],
                ),
                SizedBox(width: MySize(context).w * 0.2),
                Row(
                  children: [
                    Container(height: legendBoxSize, width: legendBoxSize, color: cactusGreen),
                    SizedBox(width: MySize(context).w * 0.01),
                    Text("Shot", style: TextStyle(fontSize: fontSizeLegend, fontWeight: FontWeight.bold))
                  ],
                ),
                SizedBox(width: MySize(context).w * 0.05),

                Row(
                  children: [
                    Container(height: legendBoxSize, width: legendBoxSize, color: lightRusticBrown),
                    SizedBox(width: MySize(context).w * 0.01),
                    Text("Lutz", style: TextStyle(fontSize: fontSizeLegend, fontWeight: FontWeight.bold))
                  ],
                ),
              ],
            ),
            SizedBox(height: 50),
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.only(
                  top: MySize(context).h * 0.1,
                  right: MySize(context).w * 0.05,
                ),
                child: (_chartData == null || _chartData!.isEmpty)
                    ? Center(
                        child: CircularProgressIndicator(color: defaultOnScroll),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          var textStyle = TextStyle(fontSize: 30, color: defaultOnScroll, fontWeight: FontWeight.bold);
                          var textPainter = TextPainter(
                              text: TextSpan(text: "20", style: textStyle),
                              maxLines: 1,
                              //textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor),
                              textDirection: TextDirection.ltr);
                          final Size size = (textPainter..layout()).size;

                          final availableHeight = constraints.maxHeight - size.height;
                          barHeight = (availableHeight / GlobalSettings.totalBarsVisible);
                          double frameLineWidth = 4;
                          var gridLine = Container(width: 1, height: availableHeight, color: defaultOnScroll);
                          var groupNameWidth = constraints.maxWidth * GlobalSettings.groupNameSpaceFactor;
                          var chartWidth = constraints.maxWidth - groupNameWidth;

                          int gridIntervalsDividableBy = 10;
                          int emptyCountRightOfFirst = 10;
                          if ((maxValue ?? 1) < 50) {
                            gridIntervalsDividableBy = 5;
                            emptyCountRightOfFirst = 3;
                          }

                          int chartMaxValue = maxValue ?? 1 + emptyCountRightOfFirst;

                          while (true) {
                            if ((chartMaxValue / GlobalSettings.totalGridLinesVisible) % gridIntervalsDividableBy ==
                                0) {
                              break;
                            } else {
                              chartMaxValue++;
                            }
                          }

                          var gridInterval = chartMaxValue / GlobalSettings.totalGridLinesVisible;

                          return Stack(children: <Widget>[
                            Positioned(
                                left: groupNameWidth,
                                child:
                                    Container(width: frameLineWidth, height: availableHeight, color: defaultOnScroll)),
                            /* Positioned(
                                left: groupNameWidth,
                                child: Container(width: chartWidth, height: frameLineWidth, color: defaultOnScroll)), */
                            /* Positioned(
                                left: groupNameWidth + chartWidth - frameLineWidth,
                                child:
                                    Container(width: frameLineWidth, height: availableHeight, color: defaultOnScroll)), */
                            Positioned(
                                left: groupNameWidth,
                                top: availableHeight - frameLineWidth,
                                child: Container(width: chartWidth, height: frameLineWidth, color: defaultOnScroll)),
                            ...List.generate(
                                (GlobalSettings.totalGridLinesVisible + 1).floor(),
                                (index) => Positioned(
                                    left: groupNameWidth + index * (chartWidth / GlobalSettings.totalGridLinesVisible),
                                    child: gridLine)),
                            ...List.generate(
                              (GlobalSettings.totalGridLinesVisible).floor(),
                              (index) => Positioned(
                                left:
                                    groupNameWidth + (index + 1) * (chartWidth / GlobalSettings.totalGridLinesVisible),
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

                                    return SizedBox(
                                      height: barHeight,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: groupNameWidth,
                                            padding: EdgeInsets.only(right: 20),
                                            child: Row(
                                              children: [
                                                data?.status == "aufgestiegen"
                                                    ? SvgPicture.asset(
                                                        'assets/arrow_up.svg',
                                                        width: fontSizeLegend,
                                                        height: fontSizeLegend,
                                                        colorFilter: ColorFilter.mode(greenAccent, BlendMode.srcIn),
                                                      )
                                                    : data?.status == "abgestiegen"
                                                        ? Transform.rotate(
                                                            angle: pi,
                                                            child: SvgPicture.asset(
                                                              'assets/arrow_up.svg',
                                                              width: fontSizeLegend,
                                                              height: fontSizeLegend,
                                                              colorFilter: ColorFilter.mode(redAccent, BlendMode.srcIn),
                                                            ),
                                                          )
                                                        : SvgPicture.asset(
                                                            'assets/arrow_up.svg',
                                                            width: fontSizeLegend,
                                                            height: fontSizeLegend,
                                                            colorFilter:
                                                                ColorFilter.mode(Colors.transparent, BlendMode.srcIn),
                                                          ),
                                                Text(
                                                  data?.group != null ? "  ${index + 1}.  " : '',
                                                  style: TextStyle(
                                                    fontSize: fontSizeLegend,
                                                    fontWeight: FontWeight.bold,
                                                    color: fontColor,
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    data?.group != null ? "${data?.group}" : '',
                                                    style: TextStyle(
                                                      fontSize: fontSizeLegend,
                                                      fontWeight: FontWeight.bold,
                                                      color: fontColor,
                                                    ),
                                                    softWrap: true,
                                                    overflow: TextOverflow.visible,
                                                  ),
                                                ),
                                              ],
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
                                                    padding: EdgeInsetsGeometry.symmetric(
                                                        vertical: constraints.maxHeight * 0.15),
                                                    child: Stack(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              height: double.infinity,
                                                              width: totalWidth * longdrink / maximumValue,
                                                              color: sunsetRed,
                                                            ),
                                                            Container(
                                                              height: double.infinity,
                                                              width: totalWidth * beer / maximumValue,
                                                              color: westernGold,
                                                            ),
                                                            Container(
                                                              height: double.infinity,
                                                              width: totalWidth * shot / maximumValue,
                                                              color: cactusGreen,
                                                            ),
                                                            Container(
                                                              height: double.infinity,
                                                              width: totalWidth * lutz / maximumValue,
                                                              color: lightRusticBrown,
                                                            ),
                                                          ],
                                                        ),
                                                        /* : Row(children: [
                                                                Container(
                                                                  height: double.infinity,
                                                                  width: totalWidth *
                                                                      (longdrink + beer + shot + lutz) /
                                                                      maximumValue,
                                                                  color: Colors.grey,
                                                                )
                                                              ]), */
                                                        Container(
                                                          height: double.infinity,
                                                          width: frameLineWidth,
                                                          color: defaultOnScroll,
                                                        )
                                                      ],
                                                    ));
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
            ),
          ]),
        )
      ],
    );
  }
}

class RacePopupWidget extends StatefulWidget {
  final String initialImageUrl;
  final String initialLeader;
  final String initialChaser;
  final int initialPointsOfLeader;

  const RacePopupWidget({
    required this.initialImageUrl,
    required this.initialLeader,
    required this.initialChaser,
    required this.initialPointsOfLeader,
    super.key,
  });

  @override
  State<RacePopupWidget> createState() => _RacePopupWidgetState();
}

class _RacePopupWidgetState extends State<RacePopupWidget> {
  late String imageUrl;
  late String leader;
  late String chaser;
  late int pointsOfLeader;

  @override
  void initState() {
    super.initState();
    imageUrl = widget.initialImageUrl;
    leader = widget.initialLeader;
    chaser = widget.initialChaser;
    pointsOfLeader = widget.initialPointsOfLeader;
  }

  void updateData(String newImageUrl, String newLeader, String newChaser, int newPointsOfLeader) {
    setState(() {
      imageUrl = newImageUrl;
      leader = newLeader;
      chaser = newChaser;
      pointsOfLeader = newPointsOfLeader;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent, // make dialog itself transparent
      contentPadding: EdgeInsets.zero, // remove default padding
      content: Container(
        height: MySize(context).h * 0.9,
        width: MySize(context).w * 0.42,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/parchment.png'),
            fit: BoxFit.cover, // cover entire container
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MySize(context).w * 0.05,
            vertical: MySize(context).h * 0.03,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WANTED',
                style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 80)),
              ),
              Divider(thickness: 2),
              Text(
                'DEAD OR ALIVE',
                style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 25)),
              ),
              Divider(thickness: 2),
              SizedBox(height: MySize(context).h * 0.03),
              Container(
                padding: EdgeInsets.only(top: MySize(context).w * 0.01, right: MySize(context).w * 0.01),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.brown.shade900,
                    width: 4,
                  ),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Stack(
                    children: [
                      Image.asset('assets/cowboy_chasing.gif', fit: BoxFit.cover, width: MySize(context).w * 0.18),
                      /* Positioned(
                        top: MySize(context).h * 0.037,
                        left: MySize(context).w * 0.065,
                        child: Image.asset('assets/placeholder_group.png', width: MySize(context).w * 0.03),
                      ), */
                    ],
                  ),
                  Image.network(
                    imageUrl,
                    width: MySize(context).w * 0.1,
                    errorBuilder: (context, _, __) =>
                        Image.asset('assets/placeholder_group.png', width: MySize(context).w * 0.1),
                  )
                ]),
              ),
              SizedBox(height: MySize(context).h * 0.007),
              SizedBox(
                height: MySize(context).h * 0.1,
                child: Center(
                  child: Text(
                    leader,
                    style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 30)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: MySize(context).h * 0.005),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Mit ",
                    style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 30)),
                  ),
                  Text(
                    pointsOfLeader.toString(),
                    style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 30)),
                  ),
                  Text(
                    " Punkten",
                    style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 30)),
                  ),
                ],
              ),
              Divider(thickness: 2),
              Text(
                "Gejagt von ",
                style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 30)),
              ),
              SizedBox(height: MySize(context).h * 0.005),
              SizedBox(
                height: MySize(context).h * 0.1,
                child: Center(
                  child: Text(
                    chaser,
                    style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 30)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
