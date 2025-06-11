import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PageSchedule extends StatefulWidget {
  const PageSchedule({super.key});

  @override
  State<PageSchedule> createState() => _PageScheduleState();
}

class _PageScheduleState extends State<PageSchedule> {
  bool imageLoaded = false;

  late Timer _dataReloadTimer;

  @override
  void initState() {
    super.initState();

    _loadImage();
    _startAutoReloadImage();
  }

  void _startAutoReloadImage() {
    _dataReloadTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _loadImage();
    });
  }

  Future<void> _loadImage() async {
    try {
      Map data = await MockDataPage3().getImage();

      if (mounted) {
        setState(() {
          //Set image variable: image = data["image"];
          imageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching page 3 schedule image: $e');
    }
  }

  @override
  void dispose() {
    _dataReloadTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(MySize(context).h * 0.08),
      child: !imageLoaded
          ? Center(
              child: CircularProgressIndicator(color: defaultOnPrimary),
            )
          : Image.asset('assets/mock_logo.png'),
    );
  }
}
