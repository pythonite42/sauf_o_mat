import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shotcounter_zieefaegge/backend_connection.dart';
import 'package:shotcounter_zieefaegge/theme.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PageAdvertising extends StatelessWidget {
  const PageAdvertising({super.key});

  Future<Map> _fetchAdvertisingData() async {
    try {
      return await SalesforceService().getPageAdvertising();
    } catch (e) {
      debugPrint('Error fetching page 5 advertising image: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map>(
      future: _fetchAdvertisingData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: defaultOnPrimary),
          );
        } else {
          SalesforceService().setPageAdvertisingVisualizedAt(snapshot.data!["id"], DateTime.now());
          final headline = snapshot.data!["headline"] ?? "";
          final text = snapshot.data!["text"] ?? "";
          final imageUrl = snapshot.data!["image"] ?? "";
          final imageWidth = MySize(context).w * 0.32;
          return Stack(
            children: [
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
                  left: MySize(context).w * 0.18,
                  top: MySize(context).h * 0.1,
                  child: Column(
                    children: [
                      Text(
                        GlobalSettings.newspaperTitle,
                        style: NewspaperTextTheme.title,
                      ),
                      SizedBox(height: MySize(context).h * 0.03),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              imageUrl,
                              width: imageWidth,
                              errorBuilder: (context, _, __) => Container(
                                width: imageWidth,
                                height: imageWidth,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image,
                                  size: MySize(context).w * 0.3 / 2,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: MySize(context).w * 0.03), // spacing between image and content
                          SizedBox(
                            width: MySize(context).w * 0.25,
                            child: Column(
                              children: [
                                Text(
                                  headline,
                                  textAlign: TextAlign.center,
                                  style: NewspaperTextTheme.headline,
                                ),
                                SizedBox(height: MySize(context).h * 0.03),
                                Text(text, textAlign: TextAlign.justify, style: NewspaperTextTheme.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
            ],
          );
        }
      },
    );
  }
}
