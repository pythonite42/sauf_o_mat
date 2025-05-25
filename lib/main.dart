import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/page_diagram.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 600),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shotcounter Zieefaegge',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: MyScaffold(),
    );
  }
}

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

  @override
  State<MyScaffold> createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  bool titleBarVisible = true;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_navigatorKey.currentContext != null) {
        int index = Random().nextInt(2);
        //_navigatorKey.currentState!.pushReplacementNamed('/page$index');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              titleBarVisible
                  ? IconButton(
                      onPressed: () async {
                        windowManager.setTitleBarStyle(TitleBarStyle.hidden);
                        setState(() {
                          titleBarVisible = false;
                        });
                        await windowManager.setFullScreen(true);
                      },
                      icon: const Icon(Icons.open_in_full),
                    )
                  : IconButton(
                      onPressed: () async {
                        windowManager.setTitleBarStyle(TitleBarStyle.normal);
                        setState(() {
                          titleBarVisible = true;
                        });
                        await windowManager.setFullScreen(false);
                      },
                      icon: const Icon(
                        Icons.close_fullscreen,
                        color: Color(0xFF1b31d1),
                      ),
                    ),
            ],
          ),
          Expanded(
            child: Navigator(
              key: _navigatorKey,
              initialRoute: '/page0',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/page0':
                    return _createRoute(PageDiagram());
                  case '/page1':
                    return _createRoute(const Page1());

                  default:
                    return MaterialPageRoute(builder: (_) => const Center(child: Text('Unknown')));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0); // right to left
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Page 1"));
  }
}
