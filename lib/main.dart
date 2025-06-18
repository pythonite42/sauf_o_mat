import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'package:shotcounter_zieefaegge/page_diagram.dart';
import 'package:shotcounter_zieefaegge/page_prize.dart';
import 'package:shotcounter_zieefaegge/page_quote.dart';
import 'package:shotcounter_zieefaegge/page_schedule.dart';
import 'package:shotcounter_zieefaegge/page_top3.dart';
import 'package:window_manager/window_manager.dart';

//TODO alle durations checken
//TODO backend durations checken: statusDisplay

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(1000, 700),
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
  late Timer _pageIndexReloadTimer;

  int pageIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadPageIndex();
    _startAutoReloadPageIndex();
  }

  void _startAutoReloadPageIndex() {
    _pageIndexReloadTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _loadPageIndex();
    });
  }

  Future<void> _loadPageIndex() async {
    try {
      int index = await MockDataNavigation().getPageIndex();
      if (index != pageIndex && _navigatorKey.currentContext != null) {
        setState(() {
          pageIndex = index;
        });
        _navigatorKey.currentState!.pushReplacementNamed('/page$index');
      }
    } catch (e) {
      debugPrint('Error fetching page index: $e');
    }
  }

  @override
  void dispose() {
    _pageIndexReloadTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: fullscreenIconSize,
            child: Row(
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
                        padding: EdgeInsets.all(0),
                        icon: Icon(
                          Icons.open_in_full,
                          size: fullscreenIconSize,
                        ),
                      )
                    : IconButton(
                        onPressed: () async {
                          windowManager.setTitleBarStyle(TitleBarStyle.normal);
                          setState(() {
                            titleBarVisible = true;
                          });
                          await windowManager.setFullScreen(false);
                        },
                        padding: EdgeInsets.all(0),
                        icon: Icon(
                          Icons.close_fullscreen,
                          color: Color(0xFF1b31d1),
                          size: fullscreenIconSize,
                        ),
                      ),
              ],
            ),
          ),
          Expanded(
            child: Navigator(
              key: _navigatorKey,
              initialRoute: '/page0',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/page0':
                    return _createRoute(Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: PageDiagram(),
                    ));
                  case '/page1':
                    return _createRoute(Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: PageTop3(),
                    ));
                  case '/page2':
                    return _createRoute(Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: PagePrize(),
                    ));
                  case '/page3':
                    return _createRoute(Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: PageSchedule(),
                    ));
                  case '/page4':
                    return _createRoute(Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: PageQuote(),
                    ));
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
