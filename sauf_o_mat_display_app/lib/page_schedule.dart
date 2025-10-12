import 'package:flutter/material.dart';
import 'package:sauf_o_mat_display_app/globals.dart';

class PageSchedule extends StatelessWidget {
  const PageSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MySize(context).h * 0.08),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 8),
          ),
          child: Image.asset("assets/placeholder_timetable.png"),
        ),
      ),
    );
  }
}
