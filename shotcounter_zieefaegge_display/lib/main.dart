import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'package:shotcounter_zieefaegge/page_diagram.dart';
import 'package:shotcounter_zieefaegge/page_livestream.dart';
import 'package:shotcounter_zieefaegge/page_prize.dart';
import 'package:shotcounter_zieefaegge/page_quote.dart';
import 'package:shotcounter_zieefaegge/page_schedule.dart';
import 'package:shotcounter_zieefaegge/page_top3.dart';
import 'package:shotcounter_zieefaegge/page_advertising.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shotcounter_zieefaegge/server_manager.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(1400, 900),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await dotenv.load(fileName: ".env");

  // Connect to WebSocket before running app
  await ServerManager().connect("ws://192.168.2.49:8080");

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

  bool overridePageIndex = false;

  late final MessageHandler socketPageIndexListener;

  void _startPageIndexTimer() {
    _pageIndexReloadTimer = Timer.periodic(Duration(seconds: CustomDurations().indexNavigationChange), (_) {
      if (!overridePageIndex) {
        int nextIndex = (pageIndex + 1) % 6;
        if (nextIndex == 2 && DateTime.now().isAfter(GlobalSettings().prizeTimes.last)) {
          nextIndex++;
        }
        _navigateToPage(nextIndex);
      } else {
        overridePageIndex = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    socketPageIndexListener = (data) {
      debugPrint("socket event received: $data");
      if (data['event'] == 'freeze' && data["freeze"] == true) {
        _pageIndexReloadTimer.cancel();
      } else {
        if (!_pageIndexReloadTimer.isActive) {
          _startPageIndexTimer();
        }
      }
      if (data['event'] == 'pageIndex' && data['index'] is int) {
        int newIndex = data['index'];
        if (newIndex != pageIndex) {
          overridePageIndex = true;
          if (newIndex == 6) {
            _pageIndexReloadTimer.cancel();
          } else {
            if (!_pageIndexReloadTimer.isActive) {
              _startPageIndexTimer();
            }
          }

          _navigateToPage(newIndex);
        }
      }
    };

    ServerManager().addListener(socketPageIndexListener);

    _startPageIndexTimer();
  }

  void _navigateToPage(int index) {
    setState(() {
      pageIndex = index;
    });

    if (_navigatorKey.currentContext != null) {
      _navigatorKey.currentState!.pushReplacementNamed('/page$index');
    }
  }

  @override
  void dispose() {
    ServerManager().removeListener(socketPageIndexListener);
    _pageIndexReloadTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/billboard.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
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
                            color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.secondary,
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
                      return _createRoute(PageDiagram());
                    case '/page1':
                      return _createRoute(PageTop3());
                    case '/page2':
                      return _createRoute(PagePrize());
                    case '/page3':
                      return _createRoute(PageSchedule());
                    case '/page4':
                      return _createRoute(PageQuote());
                    case '/page5':
                      return _createRoute(PageAdvertising());
                    case '/page6':
                      return _createRoute(PageLivestream());
                    default:
                      return MaterialPageRoute(builder: (_) => const Center(child: Text('Unknown Page')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: Duration(milliseconds: CustomDurations().navigationTransition),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0); // slide in from right
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
