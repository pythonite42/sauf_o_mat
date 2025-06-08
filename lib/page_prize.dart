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
    _dataReloadTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      Map settings = await MockDataPrize().getPrizePageSettings();
      Map data = await MockDataPrize().getPrizePageData();

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
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/bierpokal.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: MySize(context).h * 0.05),
                Text(
                  headline,
                  style: TextStyle(fontSize: headlineSize, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: MySize(context).h * 0.02),
                Text(
                  subline,
                  style: TextStyle(fontSize: sublineSize),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MySize(context).h * 0.05),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: (_remainingTime.inSeconds > redThreshold)
                          ? _buildTimerBox(greenAccent, counterSize)
                          : (_remainingTime.inSeconds > flashThreshold || _remainingTime.inSeconds == 0)
                              ? _buildTimerBox(redAccent, counterSize)
                              : FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildTimerBox(redAccent, counterSize),
                                ),
                    ),
                    SizedBox(width: MySize(context).w * 0.05),
                    Expanded(
                        child: Container(
                      height: MySize(context).h * 0.15,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: MySize(context).h * 0.05,
                            child: ClipOval(
                              child: Image.asset('assets/mock_logo.png'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aktuell führend', style: TextStyle(fontSize: leadingSize, color: Colors.grey)),
                              Text(
                                groupName,
                                style: TextStyle(fontSize: groupNameSize, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                )
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
