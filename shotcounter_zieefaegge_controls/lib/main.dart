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

  @override
  Widget build(BuildContext context) {
    final List<bool> selected = [false, false];
    selected[selectedIndex] = true;

    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(top: 50),
        child: Column(
          children: <Widget>[
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
                  color: defaultOnPrimary, // Unselected text/icon color
                  selectedColor: defaultOnPrimary, // Selected text/icon color (for contrast)
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

            Text('You have pushed the button this many times:'),
          ],
        ),
      ),
    );
  }
}
