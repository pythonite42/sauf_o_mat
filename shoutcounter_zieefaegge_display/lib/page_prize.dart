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

class _PagePrizeState extends State<PagePrize> with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _remainingTime = Duration(hours: 0, minutes: 0, seconds: 0);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Timer _dataReloadTimer;

  bool dataLoaded = false;

  int flashSpeed = 400;
  int flashThreshold = 60;
  int redThreshold = 300;
  double headlineSize = 35;
  double sublineSize = 20;
  double leadingSize = 18;
  double groupNameSize = 25;
  double counterSize = 25;

  String groupName = "";
  String headline = "";
  String subline = "";
  String imagePrize = "";
  String groupLogo = "";

  @override
  void initState() {
    super.initState();

    _loadData();
    _startAutoReloadChartData();

    _startCountdown();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  void _startAutoReloadChartData() {
    _dataReloadTimer = Timer.periodic(Duration(seconds: 3), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      Map settings = await MockDataPage2().getPrizePageSettings();
      Map data = await MockDataPage2().getPrizePageData();

      if (mounted) {
        setState(() {
          final newDuration = Duration(milliseconds: settings["flashSpeed"]);
          if (_animationController.duration != newDuration) {
            _animationController.stop();
            _animationController.duration = newDuration;
            _animationController.repeat(reverse: true);
            flashSpeed = settings["flashSpeed"];
          }

          flashThreshold = settings["flashThreshold"];
          redThreshold = settings["redThreshold"];
          headlineSize = settings["headlineSize"];
          sublineSize = settings["sublineSize"];
          leadingSize = settings["leadingSize"];
          groupNameSize = settings["groupNameSize"];
          counterSize = settings["counterSize"];

          groupName = data["groupName"];
          headline = data["headline"];
          subline = data["subline"];
          imagePrize = data["imagePrize"];
          groupLogo = data["groupLogo"];

          int newRemainingSeconds = data["remainingTimeSeconds"];
          if ((_remainingTime.inSeconds - newRemainingSeconds).abs() > 2) {
            _remainingTime = Duration(seconds: newRemainingSeconds);
          }
          dataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching prize page settings: $e');
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= const Duration(seconds: 1);
        } else if (dataLoaded) {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _dataReloadTimer.cancel();
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
                  flex: 5,
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
                      SizedBox(height: MySize(context).h * 0.05),
                      Text(
                        headline,
                        style: TextStyle(fontSize: headlineSize, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: MySize(context).h * 0.02),
                      Text(
                        subline,
                        style: TextStyle(fontSize: sublineSize),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: MySize(context).h * 0.05),
                      Container(
                        height: MySize(context).h * 0.20,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: MySize(context).w * 0.01),
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
                                  Text('Aktuell führend',
                                      style: TextStyle(fontSize: leadingSize, color: defaultOnPrimary)),
                                  Text(
                                    groupName,
                                    style: TextStyle(fontSize: groupNameSize, fontWeight: FontWeight.bold),
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
                      (_remainingTime.inSeconds > redThreshold)
                          ? _buildTimerBox(greenAccent, counterSize)
                          : (_remainingTime.inSeconds > flashThreshold || _remainingTime.inSeconds == 0)
                              ? _buildTimerBox(redAccent, counterSize)
                              : FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildTimerBox(redAccent, counterSize),
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
          Text(
            'Noch ${_formatDuration(_remainingTime)}',
            style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
