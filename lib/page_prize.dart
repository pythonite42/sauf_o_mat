import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PagePrize extends StatefulWidget {
  const PagePrize({super.key});

  @override
  State<PagePrize> createState() => _PagePrizeState();
}

class _PagePrizeState extends State<PagePrize> with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _remainingTime = Duration(hours: 0, minutes: 1, seconds: 7);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
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
      child: Column(
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
            'Gewinne eine Biersäule!',
            style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: MySize(context).h * 0.02),
          Text(
            'Sauft Sauft Sauft, eine Säule geht auf uns',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MySize(context).h * 0.05),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: (_remainingTime.inSeconds > 300)
                    ? _buildTimerBox(greenAccent)
                    : (_remainingTime.inSeconds > 60)
                        ? _buildTimerBox(redAccent)
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildTimerBox(redAccent),
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
                        Text('Aktuell führend', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text(
                          'SuperUser_42',
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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

  Widget _buildTimerBox(Color color) {
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
          Icon(Icons.timer, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            'Noch ${_formatDuration(_remainingTime)}',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
