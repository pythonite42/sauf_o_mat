import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge_controls/colors.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shotcounter Zieefaegge Controls',
      theme: appTheme,
      debugShowCheckedModeBanner: false,

      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  int currentNavigationIndex = 0;
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
            print(decoded);
          }
        } catch (e) {
          print("ERROR $e");
        }
      });
    } catch (e) {
      print("ERROR $e");
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

    print("initialization");
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
    print("registerPeerConnectionListeners");
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      channel?.sink.add(jsonEncode({"event": "ice", "data": candidate.toMap()}));
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };
    peerConnection?.onTrack = (RTCTrackEvent event) {
      print("⚠️ Track received, but no stream available");
    };
  }

  Future<void> pauseCamera() async {
    try {
      if (localStream != null) {
        for (var track in localStream!.getVideoTracks()) {
          track.enabled = false; // Stop sending frames
          channel?.sink.add(jsonEncode({"event": "paused"}));
        }
        print("📷 Camera paused");
      }
    } catch (e) {
      print("❌ Error pausing camera: $e");
    }
  }

  Future<void> resumeCamera() async {
    try {
      if (localStream != null) {
        for (var track in localStream!.getVideoTracks()) {
          track.enabled = true; // Resume sending frames
          channel?.sink.add(jsonEncode({"event": "resumed"}));
        }
        print("📷 Camera resumed");
      }
    } catch (e) {
      print("❌ Error resuming camera: $e");
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
      print("✅ Livestream cleaned up");
    } catch (e) {
      print("❌ Error cleaning up livestream: $e");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    peerConnection?.close();
    localVideo.dispose();
    super.dispose();
  }

  Future<int> getCurrentNavigationIndex() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      currentNavigationIndex = 0;
    });
    return currentNavigationIndex;
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
            FutureBuilder<int>(
              future: getCurrentNavigationIndex(),
              builder: (context, AsyncSnapshot<int> snapshot) {
                if (snapshot.hasData) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text("Seite:", style: TextStyle(fontSize: 20)),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: darkAccent),
                        child: DropdownButtonFormField<String>(
                          value: pages[snapshot.data!],
                          icon: const Icon(Icons.expand_more),
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                          ),
                          onChanged: (String? newValue) async {
                            final newIndex = pages.indexOf(newValue!);
                            setState(() {
                              currentNavigationIndex = newIndex;
                            });

                            if (newValue == "Livestream") {
                              connectToServer();
                              localVideo.initialize();
                              initialization();
                            } else {
                              await cleanupLivestream();
                              setState(() {
                                _showCamera = false;
                                _isRecordingRunning = false;
                              });
                            }
                          },
                          items: pages.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            const SizedBox(height: 10),
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
                            SizedBox(width: width, height: height, child: RTCVideoView(localVideo, mirror: false)),
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
