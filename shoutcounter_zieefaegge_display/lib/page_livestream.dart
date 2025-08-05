import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:typed_data';

class PageLivestream extends StatefulWidget {
  const PageLivestream({super.key});

  @override
  State<PageLivestream> createState() => _PageLivestreamState();
}

class _PageLivestreamState extends State<PageLivestream> {
  /* RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _remoteRenderer = RTCVideoRenderer();

  @override
  void dispose() {
    _localStream?.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _remoteRenderer.initialize();
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // Send this to other peer via signaling
    };
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // Add media tracks
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      // Send to signaling server
      print('Send ICE candidate: ${candidate.toMap()}');
    };
  }

  Future<void> _setRemoteOffer(String sdp) async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    });

    _peerConnection!.onTrack = (event) {
      // Attach to remote video view
      _remoteRenderer.srcObject = event.streams.first;
    };

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );

    await _createAndSendAnswer();
  }

  Future<void> _createAndSendAnswer() async {
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Send answer.sdp and answer.type back to sender
    print('Send answer SDP to sender: ${answer.sdp}');
  }

  Future<void> _addRemoteIceCandidate(String candidate, String sdpMid, int sdpMLineIndex) async {
    await _peerConnection!.addCandidate(
      RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
    );
  } */

  final RTCVideoRenderer localVideo = RTCVideoRenderer();
  final RTCVideoRenderer remoteVideo = RTCVideoRenderer();
  late final MediaStream localStream;
  late final WebSocketChannel channel;
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;

  // Connecting with websocket Server
  void connectToServer() {
    try {
      channel = WebSocketChannel.connect(Uri.parse("ws://192.168.2.49:8080"));

      // Listening to the socket event as a stream
      channel.stream.listen(
        (message) async {
          // Convert Uint8List to String
          final decodedMessage = utf8.decode(message as Uint8List);

          // Now decode JSON
          final Map<String, dynamic> decoded = jsonDecode(decodedMessage);
          // If the client receive an offer
          if (decoded["event"] == "offer") {
            // Set the offer SDP to remote description
            await peerConnection?.setRemoteDescription(
              RTCSessionDescription(
                decoded["data"]["sdp"],
                decoded["data"]["type"],
              ),
            );

            // Create an answer
            RTCSessionDescription answer = await peerConnection!.createAnswer();

            // Set the answer as an local description
            await peerConnection!.setLocalDescription(answer);

            // Send the answer to the other peer
            channel.sink.add(
              jsonEncode(
                {
                  "event": "answer",
                  "data": answer.toMap(),
                },
              ),
            );
          }
          // If client receive an Ice candidate from the peer
          else if (decoded["event"] == "ice") {
            // It add to the RTC peer connection
            peerConnection?.addCandidate(RTCIceCandidate(
                decoded["data"]["candidate"], decoded["data"]["sdpMid"], decoded["data"]["sdpMLineIndex"]));
          }
          // If Client recive an reply of their offer as answer

          else if (decoded["event"] == "answer") {
            await peerConnection
                ?.setRemoteDescription(RTCSessionDescription(decoded["data"]["sdp"], decoded["data"]["type"]));
          }
          // If no condition fulfilled? printout the message
          else {
            print(decoded);
          }
        },
      );
    } catch (e) {
      throw "ERROR $e";
    }
  }

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
    // Getting video feed from the user camera
    localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': false});

    // Set the local video to display
    localVideo.srcObject = localStream;
    // Initializing the peer connecion
    peerConnection = await createPeerConnection(configuration);
    setState(() {});
    // Adding the local media to peer connection
    // When connection establish, it send to the remote peer
    localStream.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream);
    });
  }

  void makeCall() async {
    // Creating a offer for remote peer
    RTCSessionDescription offer = await peerConnection!.createOffer();

    // Setting own SDP as local description
    await peerConnection?.setLocalDescription(offer);

    // Sending the offer
    channel.sink.add(
      jsonEncode(
        {"event": "offer", "data": offer.toMap()},
      ),
    );
  }

  // Help to debug our code
  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      channel.sink.add(
        jsonEncode({"event": "ice", "data": candidate.toMap()}),
      );
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };
    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteVideo.srcObject = event.streams.first;
        print("✅ Remote stream received and attached");
        setState(() {});
      } else {
        print("⚠️ Track received, but no stream available");
      }
    };
    /* peerConnection?.onTrack = ((tracks) {
      tracks.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    });

    // When stream is added from the remote peer
    peerConnection?.onAddStream = (MediaStream stream) {
      remoteVideo.srcObject = stream;
      setState(() {});
    }; */
  }

  @override
  void initState() {
    connectToServer();
    localVideo.initialize();
    remoteVideo.initialize();
    initialization();
    super.initState();
  }

  @override
  void dispose() {
    peerConnection?.close();
    localVideo.dispose();
    remoteVideo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isKiss = false;
    return Column(children: [
      Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            width: MediaQuery.of(context).size.width,
            child: RTCVideoView(
              remoteVideo,
              mirror: false,
            ),
          ),
          Positioned(
            right: 10,
            child: SizedBox(
              height: 200,
              width: 200,
              child: RTCVideoView(
                localVideo,
                mirror: true,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.amberAccent,
                onPressed: () => registerPeerConnectionListeners(),
                child: const Icon(Icons.settings_applications_rounded),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () => {makeCall()},
                child: const Icon(Icons.call_outlined),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  channel.sink.add(
                    jsonEncode(
                      {
                        "event": "msg",
                        "data": "Hi this is an offer",
                      },
                    ),
                  );
                },
                child: const Icon(
                  Icons.call_end_outlined,
                ),
              ),
            ],
          )
        ],
      ),
    ]);

    /* return LayoutBuilder(
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
                  padding: EdgeInsets.symmetric(vertical: MySize(context).h * 0.05),
                  child: BeerGlassImageStack(size: size),
                ),
        );
      },
    ); */
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
    double beerGlassWidth = widget.size * 0.6;
    return backgroundImage == null
        ? CircularProgressIndicator()
        : Stack(alignment: Alignment.topCenter, children: [
            // Beer glass body (custom painter)
            Positioned(
              top: widget.size * 0.11, // Adjust to fit under foam
              child: CustomPaint(
                painter: BeerGlassBorderPainter(image: backgroundImage!),
                child: Container(
                  width: beerGlassWidth,
                  height: widget.size * 0.78,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Positioned(
              top: -widget.size * 0.24,
              child: SvgPicture.asset('assets/beer_foam.svg', width: beerGlassWidth * 1.2),
            )
          ]);
  }
}

class BeerGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glassPaint = Paint()
      ..color = Colors.amber.shade200
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();

    // Main beer glass (rectangle with rounded corners)
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 20, size.width - 60, size.height - 40),
      Radius.circular(16),
    ));

    // Handle path (semi-oval curve on the right)
    final handlePath = Path();
    final handleLeft = size.width - 40;
    final handleTop = size.height * 0.25;
    final handleBottom = size.height * 0.75;

    handlePath.moveTo(handleLeft, handleTop);
    handlePath.cubicTo(
      size.width, handleTop, //
      size.width, handleBottom, //
      handleLeft, handleBottom,
    );

    handlePath.cubicTo(
      size.width - 10,
      handleBottom - 10,
      size.width - 10,
      handleTop + 10,
      handleLeft,
      handleTop,
    );

    path.addPath(handlePath, Offset.zero);

    // Draw
    canvas.drawPath(path, glassPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BeerGlassBorderPainter extends CustomPainter {
  final ui.Image image;

  BeerGlassBorderPainter({required this.image});

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

    // 🖼️ Draw image inside the inner glass
    final imagePadding = strokeWidth / 2;
    final imageRect = Rect.fromLTWH(
      innerRRect.left + imagePadding,
      innerRRect.top + imagePadding,
      innerRRect.width - imagePadding * 2,
      innerRRect.height - imagePadding * 2,
    );
    final imageRRect = RRect.fromRectAndRadius(
      imageRect,
      Radius.circular(cornerRadius - strokeWidth * 2),
    );

    canvas.save();
    canvas.clipRRect(imageRRect);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );
    canvas.restore();

    // 🧱 Draw outer borders (glass + handle)
    canvas.drawPath(outerPath, outerPaint);
    canvas.drawRRect(innerRRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant BeerGlassBorderPainter oldDelegate) {
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
