import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'dart:ui' as ui;

class PageLivestream extends StatefulWidget {
  const PageLivestream({super.key});

  @override
  State<PageLivestream> createState() => _PageLivestreamState();
}

class _PageLivestreamState extends State<PageLivestream> {
  @override
  Widget build(BuildContext context) {
    bool isKiss = false;
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.biggest.shortestSide;
        return Center(
          child: isKiss
              ? ClipPath(
                  clipper: HeartClipper(),
                  child: Container(
                    width: size,
                    height: size,
                    color: Colors.greenAccent,
                  ),
                )
              : Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.symmetric(vertical: MySize(context).h * 0.1),
                  child: BeerGlassImageStack(size: size),
                ),
        );
      },
    );
  }
}

class BeerGlassImageStack extends StatefulWidget {
  const BeerGlassImageStack({super.key, required this.size});
  final double size;

  @override
  State<BeerGlassImageStack> createState() => _BeerGlassImageStackState();
}

class _BeerGlassImageStackState extends State<BeerGlassImageStack> {
  ui.Image? backgroundImage;

  @override
  void initState() {
    super.initState();
    _loadImage('assets/mock_logo.png');
  }

  Future<void> _loadImage(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      backgroundImage = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          backgroundImage == null
              ? CircularProgressIndicator()
              : CustomPaint(
                  painter: BeerGlassBorder(image: backgroundImage!),
                  child: Container(
                    width: widget.size * 0.5,
                    height: widget.size,
                    alignment: Alignment.center,
                  ),
                ),
          Container(
            width: widget.size * 0.2,
            height: widget.size * 0.4,
            color: Colors.greenAccent,
          ),
        ],
      )
    ]);
  }
}

class BeerGlassBorder extends CustomPainter {
  final ui.Image image;

  BeerGlassBorder({required this.image});
  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 6;

    final outerPaint = Paint()
      ..color = const Color.fromARGB(172, 255, 255, 255)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final innerPaint = Paint()
      ..color = const Color.fromARGB(172, 255, 255, 255)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final innerBorderRect = Rect.fromLTWH(
      strokeWidth * 2,
      strokeWidth * 2,
      size.width - strokeWidth * 4,
      size.height - strokeWidth * 4,
    );

    // Image goes slightly *inside* the inner border area
    final imagePadding = strokeWidth / 2; // adjust this value as needed
    final imageRect = Rect.fromLTWH(
      innerBorderRect.left + imagePadding,
      innerBorderRect.top + imagePadding,
      innerBorderRect.width - imagePadding * 2,
      innerBorderRect.height - imagePadding * 2,
    );

    // Draw the image (inside inner border)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );

    // Draw borders last
    canvas.drawRect(outerRect, outerPaint);
    canvas.drawRect(innerBorderRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant BeerGlassBorder oldDelegate) {
    return oldDelegate.image != image;
  }
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();

    // Start at top center
    path.moveTo(w * 0.5, h * 0.25);

    // Left lobe
    path.cubicTo(
      w * 0.1, h * -0.1, // control point 1 (pull up to make taller)
      w * -0.3, h * 0.5, // control point 2 (left outward)
      w * 0.5, h * 0.9, // bottom center
    );

    path.moveTo(w * 0.5, h * 0.25);

    // Right lobe
    path.cubicTo(
      w * 0.9, h * -0.1, // control point 3 (right lobe top)
      w * 1.3, h * 0.5, // control point 4 (right outward)
      w * 0.5, h * 0.9, // bottom center
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
