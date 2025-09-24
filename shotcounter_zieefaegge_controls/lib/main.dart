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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  int currentNavigationIndex = 0;
  bool indexFrozen = false;
  List<String> pages = ["Balkendiagramm", "Top 3", "Gewinn", "Ablaufplan", "Kommentare", "Werbung", "Livestream"];
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
      if (currentNavigationIndex == 6) {
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

  @override
  Widget build(BuildContext context) {
    final List<bool> selected = [false, false];
    selected[selectedIndex] = true;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(onPressed: reloadApp, child: const Text("Neu verbinden")),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: darkAccent),
                        child: DropdownButtonFormField<String>(
                          initialValue: pages[currentNavigationIndex],
                          icon: const Icon(Icons.expand_more),
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                          ),
                          onChanged: (String? newValue) async {
                            final newIndex = pages.indexOf(newValue!);
                            debugPrint("send event pageIndex with index $newIndex");
                            channel?.sink.add(jsonEncode({"event": "pageIndex", "index": newIndex}));

                            setState(() {
                              if (indexFrozen || newIndex == 6) {
                                channel?.sink.add(jsonEncode({"event": "freeze", "freeze": true}));
                                indexFrozen = true;
                              }
                              if (currentNavigationIndex == 6 && newIndex != 6) {
                                channel?.sink.add(jsonEncode({"event": "freeze", "freeze": false}));
                                indexFrozen = false;
                              }
                              currentNavigationIndex = newIndex;
                              if (newIndex == 6) {
                                localVideo.initialize();
                                initialization();
                              } else {
                                //await cleanupLivestream();
                                _showCamera = false;
                                _isRecordingRunning = false;
                              }
                            });
                          },
                          items: pages.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                      ),
                      currentNavigationIndex == 6
                          ? ElevatedButton(
                              onPressed: () async {
                                channel?.sink.add(
                                  jsonEncode({"event": "pageIndex", "index": currentNavigationIndex, "reset": true}),
                                );
                                await pauseCamera();

                                setState(() {
                                  _isRecordingRunning = !_isRecordingRunning;
                                });
                              },
                              child: const Text("Kamera neu starten"),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                debugPrint("send event reset");
                                channel?.sink.add(
                                  jsonEncode({"event": "pageIndex", "index": currentNavigationIndex, "reset": true}),
                                );
                              },
                              child: const Text("Seiten-Daten neu laden"),
                            ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_showCamera)
              LayoutBuilder(
                builder: (context, constraints) {
                  const double borderWidth = 1.0;
                  double totalInternalBorders = borderWidth * 3;
                  double buttonWidth = (constraints.maxWidth - totalInternalBorders) / 2;

                  return ToggleButtons(
                    isSelected: selected,
                    onPressed: (int index) {
                      setState(() {
                        for (int i = 0; i < selected.length; i++) {
                          selected[i] = i == index;
                        }
                        selectedIndex = index;
                      });
                      channel?.sink.add(jsonEncode({"selectedCam": index}));
                    },
                    borderWidth: borderWidth,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    selectedColor: Colors.white,
                    fillColor: darkAccent,
                    splashColor: transparentWhite,
                    highlightColor: transparentWhite,
                    borderColor: transparentWhite,
                    selectedBorderColor: transparentWhite,
                    disabledColor: Colors.grey.shade600,
                    disabledBorderColor: Colors.grey.shade800,
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: Center(
                          child: Text(
                            "Ex-Cam",
                            style: TextStyle(
                              fontSize: selected.first ? 20 : 16,
                              fontWeight: selected.first ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: Center(
                          child: Text(
                            "Kiss-Cam",
                            style: TextStyle(
                              fontSize: selected.last ? 20 : 16,
                              fontWeight: selected.last ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            SizedBox(height: 10),
            Expanded(
              child: _showCamera
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        var controlBarHeight = constraints.maxHeight * 0.13;
                        var height = constraints.maxHeight - controlBarHeight;
                        var width = (constraints.maxHeight - controlBarHeight) * 9 / 16;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            selectedIndex == 0
                                ? Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      SizedBox(
                                        width: width,
                                        height: height,
                                        child: RTCVideoView(localVideo, mirror: false),
                                      ),
                                      SizedBox(
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
                                    ],
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: width,
                                        height: height,
                                        child: RTCVideoView(localVideo, mirror: false),
                                      ),
                                      Image.asset('assets/rose_wreath.png', width: width * 1.1),
                                      SizedBox(
                                        height: height,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(width: width, height: height * 0.22, color: Colors.black),
                                            Container(width: width, height: height * 0.22, color: Colors.black),
                                          ],
                                        ),
                                      ),
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
                        );
                      },
                    )
                  : Center(child: Text("Kamera wird aktiviert wenn Livestream ausgewählt ist")),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
