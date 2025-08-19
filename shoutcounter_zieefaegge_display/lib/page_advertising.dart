import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PageAdvertising extends StatefulWidget {
  const PageAdvertising({super.key});

  @override
  State<PageAdvertising> createState() => _PageAdvertisingState();
}

class _PageAdvertisingState extends State<PageAdvertising> {
  bool dataLoaded = false;

  late Timer _dataReloadTimer;

  String text = "";
  String imageUrl = "";

  //TODO im Stil einer alten Zeitung
  //TODO "Newspaper" abgeschnitten oben angezeigt, Headline rechts, Text rechts
  //TODO last modified, patch wurdeBereitsAngezeigt

  @override
  void initState() {
    super.initState();

    _loadImage();
    _startAutoReloadImage();
  }

//TODO reload braucht es nicht
  void _startAutoReloadImage() {
    _dataReloadTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _loadImage();
    });
  }

  Future<void> _loadImage() async {
    try {
      Map data = await MockDataPage5().getData();

      if (mounted) {
        setState(() {
          text = data["text"];
          imageUrl = data["image"];
          dataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching page 5 advertising image: $e');
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
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: MySize(context).h * 0.4),
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
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(vertical: MySize(context).h * 0.05),
                        child: Text(
                          text,
                          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
