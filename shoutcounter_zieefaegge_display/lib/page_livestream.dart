import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'package:shotcounter_zieefaegge/server_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class PageLivestream extends StatefulWidget {
  const PageLivestream({super.key});

  @override
  State<PageLivestream> createState() => _PageLivestreamState();
}

class _PageLivestreamState extends State<PageLivestream> {
  final RTCVideoRenderer remoteVideo = RTCVideoRenderer();
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;

  bool videoIsRunning = false;
  bool isKiss = false;

  // STUN server configuration
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302']
      }
    ]
  };

  // This must be done as soon as app loads
  void initialization() async {
    // Initializing the peer connecion
    peerConnection = await createPeerConnection(configuration);
    setState(() {});

    registerPeerConnectionListeners();
  }

  // Help to debug our code
  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      ServerManager().send(
        {"event": "ice", "data": candidate.toMap()},
      );
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onTrack = ((tracks) {
      tracks.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    });

    // When stream is added from the remote peer
    peerConnection?.onAddStream = (MediaStream stream) {
      remoteVideo.srcObject = stream;
      setState(() {});
    };
  }

  void handleSocketMessage(Map<String, dynamic> decoded) async {
    if (decoded["event"] == "offer") {
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(decoded["data"]["sdp"], decoded["data"]["type"]),
      );
      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);
      ServerManager().send({"event": "answer", "data": answer.toMap()});
    } else if (decoded["event"] == "ice") {
      peerConnection?.addCandidate(RTCIceCandidate(
        decoded["data"]["candidate"],
        decoded["data"]["sdpMid"],
        decoded["data"]["sdpMLineIndex"],
      ));
    } else if (decoded["event"] == "paused") {
      setState(() => videoIsRunning = false);
    } else if (decoded["event"] == "resumed") {
      setState(() => videoIsRunning = true);
    } else if (decoded["selectedCam"] == 0) {
      setState(() => isKiss = false);
    } else if (decoded["selectedCam"] == 1) {
      setState(() => isKiss = true);
    }
  }

  @override
  void initState() {
    super.initState();
    remoteVideo.initialize();
    initialization();
    ServerManager().addListener(handleSocketMessage);
  }

  @override
  void dispose() {
    ServerManager().removeListener(handleSocketMessage);
    peerConnection?.close();
    remoteVideo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.biggest.shortestSide;
        return Center(
          child: videoIsRunning
              ? isKiss
                  ? ClipPath(
                      clipper: HeartClipper(),
                      child: Container(
                        width: size,
                        height: size,
                        child: RTCVideoView(
                          remoteVideo,
                          mirror: false,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    )
                  : Container(
                      width: size,
                      height: size,
                      padding: EdgeInsets.symmetric(vertical: MySize(context).h * 0.05),
                      child: BeerGlassStack(
                        size: size,
                        videoRenderer: remoteVideo,
                      ),
                    )
              : isKiss
                  ? ClipPath(
                      clipper: HeartClipper(),
                      child: Container(
                        width: size,
                        height: size,
                        color: Color.fromARGB(172, 255, 255, 255),
                        child: Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 8,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: size,
                      height: size,
                      padding: EdgeInsets.symmetric(vertical: MySize(context).h * 0.05),
                      child: BeerGlassStack(size: size, videoRenderer: null),
                    ),
        );
      },
    );
  }
}

class BeerGlassStack extends StatelessWidget {
  final double size;
  final RTCVideoRenderer? videoRenderer;

  const BeerGlassStack({
    super.key,
    required this.size,
    required this.videoRenderer,
  });

  @override
  Widget build(BuildContext context) {
    double beerGlassWidth = size * 0.6;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Glass border and clipping
        if (videoRenderer != null)
          Positioned(
            top: size * 0.11, // adjust to match foam position
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20), // match your inner glass radius
              child: SizedBox(
                width: beerGlassWidth,
                height: size * 0.78,
                child: RTCVideoView(
                  videoRenderer!,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
        if (videoRenderer == null)
          Positioned(
            top: size * 0.45,
            child: CircularProgressIndicator(
              color: Color.fromARGB(172, 255, 255, 255),
              strokeWidth: 8,
            ),
          ),

        // Beer glass border overlay
        Positioned(
          top: size * 0.11,
          child: CustomPaint(
            painter: BeerGlassBorderPainter(), // adjust painter to only paint border
            child: Container(
              width: beerGlassWidth,
              height: size * 0.78,
            ),
          ),
        ),

        // Foam on top
        Positioned(
          top: -size * 0.24,
          child: SvgPicture.asset(
            'assets/beer_foam.svg',
            width: beerGlassWidth * 1.2,
          ),
        ),
      ],
    );
  }
}

class BeerGlassBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 6;
    double cornerRadius = 20;

    final outerPaint = Paint()
      ..color = const Color.fromARGB(172, 255, 255, 255)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final innerPaint = Paint()
      ..color = const Color.fromARGB(172, 255, 255, 255)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final borderFillPaint = Paint()
      ..color = const Color.fromARGB(106, 255, 255, 255)
      ..style = PaintingStyle.fill;

    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );

    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth * 2,
        strokeWidth * 2,
        size.width - strokeWidth * 4,
        size.height - strokeWidth * 4,
      ),
      Radius.circular(cornerRadius - strokeWidth),
    );

    // Create outer path and add handle shape
    final outerPath = Path()..addRRect(outerRRect);

    // 👉 Handle path (right side of glass)

    final handleWidth = size.width * 0.1;

    final handleLeft = size.width;
    final handleRight = handleLeft + size.width * 0.3;
    final handleTop = size.height * 0.15;
    final handleBottom = size.height * 0.85;
    final arcMidY = (handleTop + handleBottom) / 2;

// Transition offsets
    final topBump = size.height * 0.055;
    final bottomDip = size.height * 0.055;

    final handlePath = Path();

// Start at the glass edge (top flat point)
    handlePath.moveTo(handleLeft, handleTop);

// Slight upward before curving out
    handlePath.lineTo(handleLeft, handleTop - topBump);

// Outer top curve
    handlePath.quadraticBezierTo(
      handleRight, handleTop - topBump, // control point out and up
      handleRight, arcMidY, // meet halfway down
    );

// Outer bottom curve
    handlePath.quadraticBezierTo(
      handleRight, handleBottom + bottomDip, // control point out and down
      handleLeft, handleBottom + bottomDip, // curve inward
    );

// Slight downward before returning up (bottom flat point)
    handlePath.lineTo(handleLeft, handleBottom);

    handlePath.lineTo(handleLeft, handleBottom - handleWidth);

    handlePath.quadraticBezierTo(
      handleRight - handleWidth, handleBottom + bottomDip - handleWidth, // control point out and down
      handleRight - handleWidth, arcMidY, // meet halfway up
    );

    handlePath.quadraticBezierTo(
      handleRight - handleWidth, handleTop - topBump + handleWidth, // control point out and up
      handleLeft, handleTop + handleWidth, // curve inward
    );

    outerPath.addPath(handlePath, Offset.zero);

    final innerPath = Path()..addRRect(innerRRect);

    // 🟡 Fill area between outer glass and inner (excluding image)
    final borderPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );
    canvas.drawPath(borderPath, borderFillPaint);

    // 🧱 Draw outer borders (glass + handle)
    canvas.drawPath(outerPath, outerPaint);
    canvas.drawRRect(innerRRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant BeerGlassBorderPainter oldDelegate) {
    return false;
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
