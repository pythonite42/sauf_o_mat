import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge_controls/colors.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Shotcounter Zieefaegge Controls', theme: appTheme, home: const MyHomePage());
  }
}

class NavigationPage {
  final String name;
  final int index;
  final bool isLivestream;

  NavigationPage({required this.name, required this.index, this.isLivestream = false});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

List<NavigationPage> pages = [
  NavigationPage(name: "Balkendiagramm", index: 0),
  NavigationPage(name: "Top 3", index: 1),
  NavigationPage(name: "Gewinn", index: 2),
  NavigationPage(name: "Ablaufplan", index: 3),
  NavigationPage(name: "Kommentare", index: 4),
  NavigationPage(name: "Werbung", index: 5),
  NavigationPage(name: "Ex-Cam", index: 6, isLivestream: true),
  NavigationPage(name: "Kiss-Cam", index: 7, isLivestream: true),
];

class MySize {
  double h = 0.0;
  double w = 0.0;
  BuildContext context;

  MySize(this.context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  NavigationPage currentNavigationPage = pages.first;
  bool indexFrozen = false;

  bool _showCamera = false;
  bool _isRecordingRunning = false;

  RTCVideoRenderer localVideo = RTCVideoRenderer();
  MediaStream? localStream;
  WebSocketChannel? channel;
  RTCPeerConnection? peerConnection;

  void connectToServer() {
    try {
      channel = WebSocketChannel.connect(Uri.parse("ws://192.168.2.49:8080"));

      // Listening to the socket event as a stream
      channel?.stream.listen((message) async {
        // Convert Uint8List to String
        try {
          final decodedMessage = utf8.decode(message as Uint8List);

          // Now decode JSON
          final Map<String, dynamic> decoded = jsonDecode(decodedMessage);

          // If the client receive an offer
          if (decoded["event"] == "offer") {
            // Set the offer SDP to remote description
            await peerConnection?.setRemoteDescription(
              RTCSessionDescription(decoded["data"]["sdp"], decoded["data"]["type"]),
            );

            // Create an answer
            RTCSessionDescription answer = await peerConnection!.createAnswer();

            // Set the answer as an local description
            await peerConnection!.setLocalDescription(answer);

            // Send the answer to the other peer
            channel?.sink.add(jsonEncode({"event": "answer", "data": answer.toMap()}));
          }
          // If client receive an Ice candidate from the peer
          else if (decoded["event"] == "ice") {
            // It add to the RTC peer connection
            peerConnection?.addCandidate(
              RTCIceCandidate(
                decoded["data"]["candidate"],
                decoded["data"]["sdpMid"],
                decoded["data"]["sdpMLineIndex"],
              ),
            );
          }
          // If Client recive an reply of their offer as answer
          else if (decoded["event"] == "answer") {
            await peerConnection?.setRemoteDescription(
              RTCSessionDescription(decoded["data"]["sdp"], decoded["data"]["type"]),
            );
          }
          // If no condition fulfilled? printout the message
          else {
            debugPrint(decoded.toString());
          }
        } catch (e) {
          debugPrint("ERROR $e");
        }
      });
    } catch (e) {
      debugPrint("ERROR $e");
    }
  }

  // STUN server configuration
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302'],
      },
    ],
  };

  // This must be done as soon as app loads
  void initialization() async {
    try {
      await localVideo.dispose();
      localStream = null;

      // Getting video feed from the user camera
      localStream = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': 'environment'},
        'audio': false,
      });
      localVideo = RTCVideoRenderer();
      await localVideo.initialize();

      // Set the local video to display
      localVideo.srcObject = localStream;
      // Initializing the peer connecion
      peerConnection = await createPeerConnection(configuration);
      setState(() {});
      // Adding the local media to peer connection
      // When connection establish, it send to the remote peer
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      debugPrint("initialization");
      registerPeerConnectionListeners();
      setState(() {
        _showCamera = true;
      });
    } catch (_) {}
  }

  void makeCall() async {
    // Creating a offer for remote peer
    RTCSessionDescription offer = await peerConnection!.createOffer();

    // Setting own SDP as local description
    await peerConnection?.setLocalDescription(offer);

    // Sending the offer
    channel?.sink.add(jsonEncode({"event": "offer", "data": offer.toMap()}));
  }

  // Help to debug our code
  void registerPeerConnectionListeners() {
    debugPrint("registerPeerConnectionListeners");
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('ICE gathering state changed: $state');
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      channel?.sink.add(jsonEncode({"event": "ice", "data": candidate.toMap()}));
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('Signaling state change: $state');
    };
    peerConnection?.onTrack = (RTCTrackEvent event) {
      debugPrint("⚠️ Track received, but no stream available");
    };
  }

  Future<void> pauseCamera() async {
    try {
      if (localStream != null) {
        for (var track in localStream!.getVideoTracks()) {
          track.enabled = false; // Stop sending frames
          channel?.sink.add(jsonEncode({"event": "paused"}));
        }
        debugPrint("📷 Camera paused");
      }
    } catch (e) {
      debugPrint("❌ Error pausing camera: $e");
    }
  }

  Future<void> resumeCamera() async {
    try {
      if (localStream != null) {
        for (var track in localStream!.getVideoTracks()) {
          track.enabled = true; // Resume sending frames
          channel?.sink.add(jsonEncode({"event": "resumed"}));
        }
        debugPrint("📷 Camera resumed");
      }
    } catch (e) {
      debugPrint("❌ Error resuming camera: $e");
    }
  }

  Future<void> cleanupLivestream() async {
    try {
      // Close peer connection
      await peerConnection?.close();
      peerConnection = null;

      // Stop and release local stream
      if (localStream != null) {
        for (var track in localStream!.getTracks()) {
          track.stop();
        }
        await localStream!.dispose();
        localStream = null;
      }

      // Dispose and re-create the renderer so it's fresh next time
      await localVideo.dispose();
      channel = null;
      debugPrint("✅ Livestream cleaned up");
    } catch (e) {
      debugPrint("❌ Error cleaning up livestream: $e");
    }
  }

  Future<void> reloadApp() async {
    await pauseCamera();
    await cleanupLivestream();
    await peerConnection?.close();
    peerConnection = null;

    try {
      await localVideo.dispose();
    } catch (_) {}

    channel?.sink.close();
    channel = null;

    connectToServer();
    setState(() {
      _showCamera = false;
      _isRecordingRunning = false;
      if (currentNavigationPage.isLivestream) {
        localVideo.initialize();
        initialization();
      }
    });
  }

  @override
  void initState() {
    connectToServer();
    super.initState();
  }

  @override
  void dispose() {
    peerConnection?.close();
    localVideo.dispose();
    super.dispose();
  }

  Widget myDropDownButtonFormField(double widthFactor, double paddingFactor) {
    return Container(
      width: MySize(context).w * widthFactor,
      padding: EdgeInsets.symmetric(horizontal: MySize(context).h * paddingFactor),
      decoration: BoxDecoration(color: darkAccent),
      child: DropdownButtonFormField<String>(
        initialValue: currentNavigationPage.name,
        icon: const Icon(Icons.expand_more),
        decoration: const InputDecoration(
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
        ),
        onChanged: (String? newValue) async {
          NavigationPage newPage = pages.firstWhere((page) => page.name == newValue);

          debugPrint("send event pageIndex with index ${newPage.index}");
          channel?.sink.add(jsonEncode({"event": "pageIndex", "index": newPage.index}));

          setState(() {
            if (indexFrozen || newPage.isLivestream) {
              channel?.sink.add(jsonEncode({"event": "freeze", "freeze": true}));
              indexFrozen = true;
            }
            if (currentNavigationPage.isLivestream && newPage.isLivestream == false) {
              channel?.sink.add(jsonEncode({"event": "freeze", "freeze": false}));
              indexFrozen = false;
            }
            currentNavigationPage = newPage;
            _isRecordingRunning = false;

            if (newPage.isLivestream) {
              localVideo.initialize();
              initialization();
            } else {
              _showCamera = false;
            }
          });
        },
        items: pages.map((NavigationPage page) {
          return DropdownMenuItem<String>(value: page.name, child: Text(page.name));
        }).toList(),
      ),
    );
  }

  Widget reloadAppButton() {
    return ElevatedButton(onPressed: reloadApp, child: const Text("Neu verbinden"));
  }

  Widget freezeSwitch() {
    return Row(
      children: [
        Text("Page freeze: "),
        Switch(
          value: indexFrozen,
          activeThumbColor: Colors.green,

          onChanged: (bool newFrozenValue) {
            setState(() {
              indexFrozen = newFrozenValue;
              debugPrint("freeze page: $newFrozenValue");
              channel?.sink.add(jsonEncode({"event": "freeze", "freeze": newFrozenValue}));
            });
          },
        ),
      ],
    );
  }

  Widget reloadDataButton() {
    return currentNavigationPage.isLivestream
        ? ElevatedButton(
            onPressed: () async {
              channel?.sink.add(
                jsonEncode({"event": "pageIndex", "index": currentNavigationPage.index, "reset": true}),
              );
              await pauseCamera();
              localVideo.initialize();
              initialization();

              setState(() {
                _isRecordingRunning = false;
              });
            },
            child: const Text("Kamera neu starten"),
          )
        : ElevatedButton(
            onPressed: () {
              debugPrint("send event reset");
              channel?.sink.add(
                jsonEncode({"event": "pageIndex", "index": currentNavigationPage.index, "reset": true}),
              );
            },
            child: const Text("Seiten-Daten neu laden"),
          );
  }

  Widget cameraWidget({
    required double controlBarHeight,
    required double height,
    required double width,
    Widget exCamLimiter = const SizedBox(),
    required double roseWreathWidthFactor,
    required double roseWreathTopPositionFactor,
    Widget kissCamLimiter = const SizedBox(),
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: width, height: height, child: RTCVideoView(localVideo, mirror: false)),
                currentNavigationPage.index != 7 ? exCamLimiter : kissCamLimiter,
              ],
            ),
            Container(
              width: width,
              height: controlBarHeight,
              color: Colors.black,
              child: IconButton(
                onPressed: () async {
                  if (_isRecordingRunning) {
                    await pauseCamera();
                  } else {
                    await resumeCamera();
                    makeCall();
                  }

                  setState(() {
                    _isRecordingRunning = !_isRecordingRunning;
                  });
                },
                icon: Icon(
                  _isRecordingRunning ? Icons.stop_circle : Icons.play_circle,
                  color: _isRecordingRunning ? Colors.red : Colors.white,
                ),
                iconSize: controlBarHeight * 0.7,
              ),
            ),
          ],
        ),
        if (currentNavigationPage.index == 7)
          Positioned(
            top: height * roseWreathTopPositionFactor,
            child: Image.asset(
              'assets/rose_wreath.png',
              width: width * roseWreathWidthFactor,
              height: width * roseWreathWidthFactor * 0.8,
              fit: BoxFit.fill,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediaQuery.of(context).orientation == Orientation.portrait
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: MySize(context).h * 0.06, horizontal: MySize(context).w * 0.03),
              child: Column(
                children: <Widget>[
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [reloadAppButton(), myDropDownButtonFormField(0.6, 0.02)],
                      ),
                      SizedBox(height: MySize(context).h * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [freezeSwitch(), reloadDataButton()],
                      ),
                    ],
                  ),
                  SizedBox(height: MySize(context).h * 0.02),
                  Expanded(
                    child: _showCamera
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              var controlBarHeight = constraints.maxHeight * 0.13;
                              var height = constraints.maxHeight - controlBarHeight;
                              var width = height * 9 / 16;
                              return cameraWidget(
                                controlBarHeight: controlBarHeight,
                                height: height,
                                width: width,
                                exCamLimiter: SizedBox(
                                  height: height,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(width: width, height: height * 0.2, color: Colors.black),
                                      Container(width: width, height: height * 0.16, color: Colors.black),
                                    ],
                                  ),
                                ),
                                roseWreathWidthFactor: 1.3,
                                roseWreathTopPositionFactor: 0.22,
                                kissCamLimiter: SizedBox(
                                  height: height,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(width: width, height: height * 0.25, color: Colors.black),
                                      Container(width: width, height: height * 0.22, color: Colors.black),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              "Kamera wird aktiviert wenn Livestream ausgewählt ist",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                  SizedBox(height: MySize(context).h * 0.02),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(vertical: MySize(context).h * 0.06, horizontal: MySize(context).w * 0.05),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _showCamera
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              var controlBarHeight = constraints.maxHeight * 0.2;
                              var height = (constraints.maxWidth * 9 / 16) - controlBarHeight;
                              var width = height * 16 / 9;
                              return cameraWidget(
                                controlBarHeight: controlBarHeight,
                                height: height,
                                width: width,
                                exCamLimiter: SizedBox(
                                  width: width,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(width: width * 0.30, height: height, color: Colors.black),
                                      Container(width: width * 0.30, height: height, color: Colors.black),
                                    ],
                                  ),
                                ),
                                roseWreathWidthFactor: 0.75,
                                roseWreathTopPositionFactor: 0.01,
                                kissCamLimiter: SizedBox(
                                  width: width,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(width: width * 0.14, height: height, color: Colors.black),
                                      Container(width: width * 0.14, height: height, color: Colors.black),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              "Kamera wird aktiviert wenn Livestream ausgewählt ist",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                  SizedBox(height: MySize(context).w * 0.02),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      reloadAppButton(),
                      myDropDownButtonFormField(0.23, 0.03),
                      freezeSwitch(),
                      reloadDataButton(),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
