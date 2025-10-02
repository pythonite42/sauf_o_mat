import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sauf_o_mat_display_app/backend_connection.dart';
import 'package:sauf_o_mat_display_app/theme.dart';
import 'package:sauf_o_mat_display_app/globals.dart';

class PagePrize extends StatefulWidget {
  const PagePrize({super.key});

  @override
  State<PagePrize> createState() => _PagePrizeState();
}

class _PagePrizeState extends State<PagePrize> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Timer _dataReloadTimer;
  Duration? _remainingTime;

  bool dataLoaded = false;
  bool _dataReloadTimerIsFast = false;
  DateTime? nextPrize;

  String groupLogo = "";
  String groupName = "";
  int groupPoints = 0;

  String imagePrize = "assets/prize_0.png";

  BuildContext? _popupContext;
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < GlobalSettings.prizeTimes.length; i++) {
      var prizeTime = GlobalSettings.prizeTimes[i];
      if (prizeTime.isAfter(DateTime.now())) {
        setState(() {
          nextPrize = prizeTime;
          imagePrize = "assets/prize_$i.png";
        });
        break;
      }
    }

    _loadData();
    _startAutoReloadData();

    _startCountdown();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: CustomDurations.flashSpeed),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  void _startAutoReloadData() {
    _dataReloadTimerIsFast = false;
    _dataReloadTimer = Timer.periodic(Duration(seconds: CustomDurations.reloadDataPrize), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      Map data = await SalesforceService().getPagePrize();

      if (mounted) {
        setState(() {
          groupLogo = data["logo"];
          groupName = data["name"];
          groupPoints = data["points"];
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
            _dataReloadTimer = Timer.periodic(Duration(seconds: CustomDurations.reloadDataPrizeUnder20sec), (_) {
              _loadData();
            });
            _dataReloadTimerIsFast = true;
          }
        } else if (dataLoaded) {
          _dataReloadTimer.cancel();
          _timer.cancel();
        }
        if (_remainingTime!.inSeconds == 0 && !_popupShown && mounted) {
          _popupShown = true;
          _showPrizePopup();
        }
      });
    });
  }

  void _showPrizePopup() async {
    await Future.delayed(Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("show prize popup: ${DateTime.now()}");
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (popupCtx) {
          _popupContext = popupCtx;
          return WinnerPopupWidget(
            imageUrl: groupLogo,
            name: groupName,
            prize: "2 Säulen Bier",
            points: groupPoints,
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _dataReloadTimer.cancel();
    _timer.cancel();
    _animationController.dispose();
    try {
      Navigator.of(_popupContext!).pop();
    } catch (_) {}
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (duration.inMinutes < 60) {
      return "${twoDigits(duration.inMinutes % 60)}:${twoDigits(duration.inSeconds % 60)}";
    }
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
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(imagePrize, fit: BoxFit.cover),
                  ),
                ),
                /*
                // TODO helper button zum stylen des PopUps, darf nicht in Production!!
                ElevatedButton(
                  onPressed: () {
                    _showPrizePopup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                  child: Text("showPopUp"),
                ), */
                SizedBox(width: MySize(context).w * 0.05), // spacing between image and content

                Expanded(
                  flex: 4,
                  child: Container(
                    height: MySize(context).h * 0.83,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/parchment.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MySize(context).w * 0.05,
                        vertical: MySize(context).h * 0.05,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "How to play",
                            maxLines: 1,
                            style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 50)),
                          ),
                          SizedBox(height: MySize(context).h * 0.03),
                          Text(
                            "subline sublinesublinesubline subline subline subline subline subline  sublinesublinesubline subline v sublinsublinesubline subline  sublinesubline subline",
                            style: TextStyle(fontSize: 25),
                            maxLines: 4,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: MySize(context).h * 0.03),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Aktuell\nführend',
                                textAlign: TextAlign.end,
                                style: GoogleFonts.rye(textStyle: TextStyle(fontSize: 30)),
                              ),
                              SizedBox(width: MySize(context).w * 0.02),
                              CircleAvatar(
                                backgroundColor: Colors.transparent,
                                radius: MySize(context).h * 0.1,
                                child: ClipOval(
                                  child: Image.network(
                                    groupLogo,
                                    errorBuilder: (context, _, __) => Image.asset("assets/placeholder_group.png"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MySize(context).h * 0.05),
                          if (_remainingTime != null)
                            (_remainingTime!.inSeconds > GlobalSettings.redThreshold)
                                ? _buildTimerBox(greenAccent, 25)
                                : (_remainingTime!.inSeconds > GlobalSettings.flashThreshold ||
                                        _remainingTime!.inSeconds == 0)
                                    ? _buildTimerBox(redAccent, 25)
                                    : FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: _buildTimerBox(redAccent, 25),
                                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTimerBox(Color color, double fontsize) {
    return Container(
      height: MySize(context).h * 0.1,
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
            color: Colors.black,
            size: MySize(context).h * 0.05,
          ),
          const SizedBox(width: 10),
          if (_remainingTime != null)
            Text(
              'Noch ${_formatDuration(_remainingTime!)}',
              style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold, color: Colors.black),
            ),
        ],
      ),
    );
  }
}

class WinnerPopupWidget extends StatefulWidget {
  const WinnerPopupWidget({
    required this.imageUrl,
    required this.name,
    required this.prize,
    required this.points,
    super.key,
  });
  final String imageUrl;
  final String name;
  final String prize;
  final int points;

  @override
  State<WinnerPopupWidget> createState() => _WinnerPopupWidgetState();
}

class _WinnerPopupWidgetState extends State<WinnerPopupWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.1, 0.9, // stays small for 10% of duration, then expands fully at 90% of duration
          curve: Curves.linear,
        ),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -5, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = MySize(context).w * 0.2;
    final imageHeight = MySize(context).h * 0.35;
    final double textSize = 25;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: SizedBox(
            height: MySize(context).h * 0.75,
            width: MySize(context).w * 0.7,
            child: Stack(children: [
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  child: Image.asset(
                    'assets/newspaper.png',
                    width: MySize(context).w,
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: MySize(context).w * 0.12,
                top: MySize(context).h * 0.08,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    GlobalSettings.newspaperTitle,
                    style: NewspaperTextTheme.title.copyWith(fontSize: 70),
                  ),
                  SizedBox(height: MySize(context).h * 0.05),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        widget.imageUrl,
                        width: imageWidth,
                        height: imageHeight,
                        errorBuilder: (context, _, __) => Image.asset(
                          "assets/placeholder_group.png",
                          width: imageWidth,
                          height: imageHeight,
                        ),
                      ),
                      SizedBox(width: MySize(context).w * 0.01),
                      SizedBox(
                        width: MySize(context).w * 0.23,
                        child: Column(
                          children: [
                            Text(
                              "Verbrecher Gefasst!",
                              style: NewspaperTextTheme.headline.copyWith(fontSize: 30),
                            ),
                            SizedBox(height: MySize(context).h * 0.03),
                            Text(
                              widget.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: textSize),
                              maxLines: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  "${widget.points}",
                                  style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  " Punkte",
                                  style: TextStyle(fontSize: textSize),
                                ),
                              ],
                            ),
                            SizedBox(height: MySize(context).h * 0.03),
                            Text(
                              "Strafe:",
                              style: TextStyle(fontSize: textSize),
                            ),
                            Text(
                              widget.prize,
                              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
