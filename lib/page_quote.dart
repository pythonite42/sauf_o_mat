import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PageQuote extends StatefulWidget {
  const PageQuote({super.key});

  @override
  State<PageQuote> createState() => _PageQuoteState();
}

class _PageQuoteState extends State<PageQuote> {
  bool dataLoaded = false;

  late Timer _dataReloadTimer;

  String username = "";
  String quote = "";
  String imageUrl = "";

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
      Map data = await MockDataPage4().getData();

      if (mounted) {
        setState(() {
          username = data["name"];
          quote = data["quote"];
          imageUrl = data["image"];
          dataLoaded = true;
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
      child: !dataLoaded
          ? Center(
              child: CircularProgressIndicator(color: defaultOnPrimary),
            )
          : AspectRatio(
              aspectRatio: 16 / 9,
              child: Card(
                color: Color(0xFFF8F9FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(MySize(context).h * 0.08),
                  child: Row(
                    children: [
                      // Profile Image
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipOval(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.person, size: MySize(context).h * 0.4),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: MySize(context).w * 0.1),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: MySize(context).h * 0.1),

                            // Username
                            Text(
                              "@$username",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 50,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: MySize(context).h * 0.1),
                            // Post Text
                            Text(
                              quote,
                              style: const TextStyle(
                                fontSize: 35,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
