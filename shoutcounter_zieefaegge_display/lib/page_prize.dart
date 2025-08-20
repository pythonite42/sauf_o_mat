import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PagePrize extends StatefulWidget {
  const PagePrize({super.key});

  @override
  State<PagePrize> createState() => _PagePrizeState();
}

//TODO 1 kurz vor Gewinn leader öfter abfragen, vorher 10 Sekunden und ab 20 sekunden vorher sekündlich

//TODO 2 überschrift größer,
//TODO 1 Infos ins Bild: uhrzeit vom Gewinn, was es zu gewinnen gibt
//TODO 1 der Text sind die Regeln (wie viele Punkte pro Getränk, wie kauf ich für meine Gruppe)
//TODO 2 Zettel als Hintergrund für rechte Seite
//TODO 2 wenn timer <60 Minuten dann stunden nicht anzeigen

class _PagePrizeState extends State<PagePrize> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Timer _dataReloadTimer;
  Duration? _remainingTime;

  bool dataLoaded = false;
  bool _dataReloadTimerIsFast = false;
  DateTime? nextPrize;

  String groupName = "";
  String headline = "";
  String subline = "";
  String imagePrize = "";
  String groupLogo = "";

  @override
  void initState() {
    super.initState();

    List<DateTime> prizeTimes = [
      GlobalSettings().timeFirstPrize,
      GlobalSettings().timeSecondPrize,
      GlobalSettings().timeThirdPrize
    ];

    for (DateTime prizeTime in prizeTimes) {
      if (prizeTime.isAfter(DateTime.now())) {
        setState(() {
          nextPrize = prizeTime;
        });
        break;
      }
    }

    _loadData();
    _startAutoReloadChartData();

    _startCountdown();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: CustomDurations().flashSpeed),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  void _startAutoReloadChartData() {
    _dataReloadTimerIsFast = false;
    _dataReloadTimer = Timer.periodic(Duration(seconds: CustomDurations().reloadDataPrize), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      Map data = await MockDataPage2().getPrizePageData();

      if (mounted) {
        setState(() {
          groupName = data["groupName"];
          headline = data["headline"];
          subline = data["subline"];
          imagePrize = data["imagePrize"];
          groupLogo = data["groupLogo"];

          dataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching prize page settings: $e');
    }
  }

  void _startCountdown() {
    if (_remainingTime == null) {
      setState(() {
        _remainingTime = nextPrize?.difference(DateTime.now()) ?? Duration();
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingTime!.inSeconds > 0) {
          _remainingTime = nextPrize?.difference(DateTime.now()) ?? Duration();
          if (_remainingTime!.inSeconds < 20 && !_dataReloadTimerIsFast) {
            _dataReloadTimer.cancel();
            _dataReloadTimer = Timer.periodic(Duration(seconds: CustomDurations().reloadDataPrizeUnder20sec), (_) {
              _loadData();
            });
            _dataReloadTimerIsFast = true;
          }
        } else if (dataLoaded) {
          _dataReloadTimer.cancel();
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _dataReloadTimer.cancel();
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes % 60)}:${twoDigits(duration.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    final padding = MySize(context).h * 0.08;

    return Padding(
      padding: EdgeInsetsGeometry.all(padding),
      child: !dataLoaded
          ? Center(
              child: CircularProgressIndicator(color: defaultOnPrimary),
            )
          : Row(
              children: [
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imagePrize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: MySize(context).h * 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MySize(context).w * 0.05), // spacing between image and content

                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: MySize(context).h * 0.02),
                      Text(
                        headline,
                        style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: MySize(context).h * 0.02),
                      Text(
                        subline,
                        style: TextStyle(fontSize: 20),
                        maxLines: 4,
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: MySize(context).h * 0.03),
                      Container(
                        height: MySize(context).h * 0.23,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: MySize(context).w * 0.01),
                            //TODO 2 Name weg machen, nur Bild mit "aktuell führend" als column
                            CircleAvatar(
                              radius: MySize(context).h * 0.07,
                              child: ClipOval(
                                child: Image.network(
                                  groupLogo,
                                  errorBuilder: (context, _, __) => AspectRatio(
                                    aspectRatio: 1,
                                    child: Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        size: MySize(context).h * 0.08,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Aktuell führend', style: TextStyle(fontSize: 18, color: defaultOnPrimary)),
                                  Text(
                                    groupName,
                                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            /* SizedBox(width: MySize(context).w * 0.02),
                            Text(
                              "123",
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                            ) */
                          ],
                        ),
                      ),
                      SizedBox(height: MySize(context).h * 0.05),
                      if (_remainingTime != null)
                        (_remainingTime!.inSeconds > GlobalSettings().redThreshold)
                            ? _buildTimerBox(greenAccent, 25)
                            : (_remainingTime!.inSeconds > GlobalSettings().flashThreshold ||
                                    _remainingTime!.inSeconds == 0)
                                ? _buildTimerBox(redAccent, 25)
                                : FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: _buildTimerBox(redAccent, 25),
                                  ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTimerBox(Color color, double fontsize) {
    return Container(
      height: MySize(context).h * 0.15,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: MySize(context).h * 0.05,
          ),
          const SizedBox(width: 10),
          if (_remainingTime != null)
            Text(
              'Noch ${_formatDuration(_remainingTime!)}',
              style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
