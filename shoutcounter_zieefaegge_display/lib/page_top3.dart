import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';

import 'dart:math';

import 'package:shotcounter_zieefaegge/globals.dart';

class PieChartData {
  final int value;
  final Color color;
  final bool showAmountInsteadOfPoints;

  PieChartData({required this.value, required this.color, this.showAmountInsteadOfPoints = false});
}

class PageTop3 extends StatefulWidget {
  const PageTop3({super.key});

  @override
  State<PageTop3> createState() => _PageTop3State();
}

/* TODO Wanted poster 
 Staatsfeind Nr. 1/2/3
 Gesucht für 166 Punkte 
  20 Bargetränke, 10 Bier usw.
*/

class _PageTop3State extends State<PageTop3> {
  List<PieChartData> _chartData1 = [];
  List<PieChartData> _chartData2 = [];
  List<PieChartData> _chartData3 = [];
  String groupName1 = "";
  String groupName2 = "";
  String groupName3 = "";
  String groupLogo1 = "";
  String groupLogo2 = "";
  String groupLogo3 = "";
  late Timer _chartDataReloadTimer;

  @override
  void initState() {
    super.initState();

    _loadChartData();
    _startAutoReloadChartData();
  }

  void _startAutoReloadChartData() {
    _chartDataReloadTimer = Timer.periodic(Duration(seconds: CustomDurations().reloadDataTop3), (_) {
      _loadChartData();
    });
  }

  Future<void> _loadChartData() async {
    try {
      List<Map> newDataMapList = await MockDataPage1().getData();
      newDataMapList.sort((a, b) {
        final aSum = (a["longdrink"] ?? 0) + (a["beer"] ?? 0) + (a["shot"] ?? 0) + (a["lutz"] ?? 0);
        final bSum = (b["longdrink"] ?? 0) + (b["beer"] ?? 0) + (b["shot"] ?? 0) + (b["lutz"] ?? 0);
        return bSum.compareTo(aSum);
      });

      if (mounted) {
        setState(() {
          groupName1 = newDataMapList[0]["groupName"];
          groupLogo1 = newDataMapList[0]["groupLogo"];
          _chartData1 = [
            PieChartData(value: newDataMapList[0]["longdrink"], color: sunsetRed, showAmountInsteadOfPoints: true),
            PieChartData(value: newDataMapList[0]["beer"], color: westernGold),
            PieChartData(value: newDataMapList[0]["shot"], color: cactusGreen),
            PieChartData(value: newDataMapList[0]["lutz"], color: lightRusticBrown),
          ];

          groupName2 = newDataMapList[1]["groupName"];
          groupLogo2 = newDataMapList[1]["groupLogo"];

          _chartData2 = [
            PieChartData(value: newDataMapList[1]["longdrink"], color: sunsetRed, showAmountInsteadOfPoints: true),
            PieChartData(value: newDataMapList[1]["beer"], color: westernGold),
            PieChartData(value: newDataMapList[1]["shot"], color: cactusGreen),
            PieChartData(value: newDataMapList[1]["lutz"], color: lightRusticBrown),
          ];

          groupName3 = newDataMapList[2]["groupName"];
          groupLogo3 = newDataMapList[2]["groupLogo"];

          _chartData3 = [
            PieChartData(value: newDataMapList[2]["longdrink"], color: sunsetRed, showAmountInsteadOfPoints: true),
            PieChartData(value: newDataMapList[2]["beer"], color: westernGold),
            PieChartData(value: newDataMapList[2]["shot"], color: cactusGreen),
            PieChartData(value: newDataMapList[2]["lutz"], color: lightRusticBrown),
          ];
        });
      }
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
    }
  }

  @override
  void dispose() {
    _chartDataReloadTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double size1 = MySize(context).w * 0.3;
    double size2 = MySize(context).w * 0.2;
    double size3 = MySize(context).w * 0.175;
    double legendBoxSize = MySize(context).h * 0.04;
    return Stack(
      children: [
        Positioned(
          top: MySize(context).h * 0.1,
          left: MySize(context).w * 0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(height: legendBoxSize, width: legendBoxSize, color: sunsetRed),
                  SizedBox(width: 15),
                  Text("Bargetränk", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
                ],
              ),
              SizedBox(width: 50),
              Row(
                children: [
                  Container(height: legendBoxSize, width: legendBoxSize, color: westernGold),
                  SizedBox(width: 15),
                  Text("Bier", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: MySize(context).h * 0.1,
          right: MySize(context).w * 0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(height: legendBoxSize, width: legendBoxSize, color: cactusGreen),
                  SizedBox(width: 15),
                  Text("Shot", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
                ],
              ),
              SizedBox(width: 50),
              Row(
                children: [
                  Container(height: legendBoxSize, width: legendBoxSize, color: lightRusticBrown),
                  SizedBox(width: 15),
                  Text("Lutz", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
                ],
              ),
            ],
          ),
        ),
        (_chartData1.isEmpty)
            ? Positioned(
                top: MySize(context).h * 0.5,
                left: MySize(context).w * 0.5,
                child: CircularProgressIndicator(color: defaultOnPrimary),
              )
            : Stack(
                children: [
                  Positioned(
                    top: MySize(context).h * 0.1,
                    left: (MySize(context).w / 2) - (size1 / 2),
                    child: PieChartWithImage(
                      chartData: _chartData1,
                      place: 1,
                      badge: '🥇 ',
                      groupName: groupName1,
                      groupLogo: groupLogo1,
                      size: size1,
                    ),
                  ),
                  Positioned(
                    top: MySize(context).h * 0.4,
                    left: MySize(context).w * 0.1,
                    child: PieChartWithImage(
                      chartData: _chartData2,
                      place: 2,
                      badge: '🥈 ',
                      groupName: groupName2,
                      groupLogo: groupLogo2,
                      size: size2,
                    ),
                  ),
                  Positioned(
                    bottom: MySize(context).h * 0.1,
                    right: MySize(context).w * 0.1,
                    child: PieChartWithImage(
                      chartData: _chartData3,
                      place: 3,
                      badge: '🥉 ',
                      groupName: groupName3,
                      groupLogo: groupLogo3,
                      size: size3,
                    ),
                  ),
                ],
              )
      ],
    );
  }
}

class PieChartWithImage extends StatelessWidget {
  const PieChartWithImage(
      {super.key,
      required this.chartData,
      required this.place,
      required this.badge,
      required this.groupName,
      required this.groupLogo,
      required this.size});

  final List<PieChartData> chartData;
  final int place;
  final String badge;
  final String groupName;
  final String groupLogo;
  final double size;

  @override
  Widget build(BuildContext context) {
    var total = 0;
    for (var element in chartData) {
      total += element.value;
    }
    var centerSize = size * 0.55;

    return Column(children: [
      Text(
        "$badge $place. Platz",
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 20),
      SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: PieChartPainter(data: chartData),
            ),
            ClipOval(
              child: SizedBox(
                width: centerSize,
                height: centerSize,
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Image.network(
                      groupLogo,
                      width: centerSize,
                      height: centerSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: MySize(context).h * 0.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(centerSize, centerSize),
                      painter: CenteredTextPainter(
                        text: "$total",
                        fontSize: total < 999
                            ? size * 0.3
                            : total < 9999
                                ? size * 0.22
                                : size * 0.18,
                        color: transparentWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 20),
      Text(
        groupName,
        style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
      )
    ]);
  }
}

class CenteredTextPainter extends CustomPainter {
  final String text;
  final double fontSize;
  final Color color;

  CenteredTextPainter({
    required this.text,
    required this.fontSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.0,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final List<PieChartData> data;

  PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final total = data.fold(0.0, (sum, item) => sum + item.value);
    final center = size.center(Offset.zero);
    final radius = min(size.width / 2, size.height / 2);

    double startAngle = -pi / 2;

    for (var item in data) {
      final sweepAngle = (item.value / total) * 2 * pi;
      final midAngle = startAngle + sweepAngle / 2;

      // Draw slice
      paint.color = item.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw value text inside the slice
      final labelRadius = radius * 0.76;
      final labelX = center.dx + labelRadius * cos(midAngle);
      final labelY = center.dy + labelRadius * sin(midAngle);

      double showValue = item.value.toDouble();
      if (item.showAmountInsteadOfPoints) {
        showValue = showValue / 2;
      }

      final textSpan = TextSpan(
        text: '${showValue.toInt()}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final arcLength = sweepAngle * radius;
      if (arcLength > textPainter.width + 6) {
        final offset = Offset(
          labelX - textPainter.width / 2,
          labelY - textPainter.height / 2,
        );
        textPainter.paint(canvas, offset);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
