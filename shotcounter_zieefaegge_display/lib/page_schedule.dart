import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PageSchedule extends StatelessWidget {
  const PageSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(MySize(context).h * 0.08),
      child: Image.asset(
        "assets/placeholder_timetable.png",
      ),
    );
  }
}
