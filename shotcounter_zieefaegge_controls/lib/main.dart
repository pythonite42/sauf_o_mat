import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge_controls/colors.dart';

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
        padding: EdgeInsetsGeometry.only(top: 50),
        child: Column(
          children: <Widget>[
            FutureBuilder<int>(
              future: getCurrentNavigationIndex(),
              builder: (context, AsyncSnapshot<int> snapshot) {
                if (snapshot.hasData) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Seite:", style: TextStyle(fontSize: 20)),
                      Container(
                        width: 200,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: darkAccent),
                        child: DropdownButtonFormField(
                          value: pages[snapshot.data!],
                          icon: const Icon(Icons.expand_more),
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                          ),
                          onChanged: (String? newValue) async {
                            await Future.delayed(Duration(seconds: 2));
                            setState(() {
                              currentNavigationIndex = 1;
                            });
                          },
                          items: pages.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container();
                }
              },
            ),
            SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                const double borderWidth = 1.0;
                double totalInternalBorders = borderWidth * 3; // 1 border between 2 buttons + border left and right
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
                  color: Colors.white, // Unselected text/icon color
                  selectedColor: Colors.white, // Selected text/icon color (for contrast)
                  fillColor: darkAccent, // Selected background
                  splashColor: transparentWhite, // Ripple effect on tap
                  highlightColor: transparentWhite, // Pressed color effect
                  borderColor: transparentWhite, // Border for unselected buttons
                  selectedBorderColor: transparentWhite, // Border when selected
                  disabledColor: Colors.grey.shade600,
                  disabledBorderColor: Colors.grey.shade800,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: Center(
                        child: Text(
                          "Ex-Cam",
                          style: TextStyle(
                            fontSize: selected.first == true ? 20 : 16,
                            fontWeight: selected.first == true ? FontWeight.bold : FontWeight.normal,
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
                            fontSize: selected.last == true ? 20 : 16,
                            fontWeight: selected.last == true ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Expanded(child: Center(child: Text('Kamera erscheint wenn Livestream ausgewählt ist'))),
          ],
        ),
      ),
    );
  }
}
