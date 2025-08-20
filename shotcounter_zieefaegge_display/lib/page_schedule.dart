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
  String imageUrl = "";

  @override
  void initState() {
    super.initState();

    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      Map data = await MockDataPage3().getImage();

      if (mounted) {
        setState(() {
          imageUrl = data["imageUrl"];
          imageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching page 3 schedule image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(MySize(context).h * 0.08),
      child: !imageLoaded
          ? Center(
              child: CircularProgressIndicator(color: defaultOnPrimary),
            )
          : Image.network(
              imageUrl,
              errorBuilder: (context, _, __) => AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image,
                    size: MySize(context).h * 0.7,
                  ),
                ),
              ),
            ),
    );
  }
}
