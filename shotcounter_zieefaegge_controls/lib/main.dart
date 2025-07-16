import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge_controls/colors.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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

  final _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _isRecordingRunning = false;
  bool _showCamera = false;

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {'facingMode': 'environment', 'width': 1280, 'height': 720, 'frameRate': 30},
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  Future<void> _stopCamera() async {
    try {
      if (_localStream != null) {
        // Stop all media tracks (both video and audio)
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }

        // Release the stream
        _localStream = null;
      }

      // Disconnect the stream from the renderer
      _localRenderer.srcObject = null;

      // Optionally trigger a rebuild if UI depends on camera state
      setState(() {});
    } catch (e) {
      print('Error stopping camera: $e');
    }
  }

  Future<int> getCurrentNavigationIndex() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      currentNavigationIndex = 1;
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
                        width: 200,
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
                              await _startCamera();
                              setState(() {
                                _showCamera = true;
                              });
                            } else {
                              _localStream?.dispose();
                              _localRenderer.srcObject = null;
                              setState(() {
                                _showCamera = false;
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
                            SizedBox(width: width, height: height, child: RTCVideoView(_localRenderer, mirror: false)),
                            Container(
                              width: width,
                              height: controlBarHeight,
                              color: Colors.black,
                              child: IconButton(
                                onPressed: () async {
                                  if (_isRecordingRunning) {
                                    //stop sending data
                                    //await _stopCamera();
                                  } else {
                                    //send data
                                    //await _startCamera();
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
