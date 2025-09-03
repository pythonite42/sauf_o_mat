import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_connection.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
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
    return Padding(
      padding: EdgeInsetsGeometry.all(MySize(context).h * 0.08),
      child: FutureBuilder<Map>(
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
            return Row(
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
                  child: Padding(
                    padding: EdgeInsetsGeometry.symmetric(vertical: MySize(context).h * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          headline,
                          style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          text,
                          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
