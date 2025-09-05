import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/theme.dart';
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

  int pageIndex = 0;
  bool animateNavigation = true;
  bool overridePageIndex = false;

  late final MessageHandler socketPageIndexListener;

  Timer? _pageIndexReloadTimer;
  Timer? _prePrizeTimer;
  Timer? _unfreezeTimer;
  bool _socketFrozen = false;
  int _nextPrizeIndex = 0;

  @override
  void initState() {
    super.initState();

    socketPageIndexListener = (data) {
      debugPrint("socket event received: $data");
      if (data['event'] == 'freeze' && data["freeze"] == true) {
        //TODO wenn 5 Minuten vor Preis, dann wird auf prize page gewechselt. wenn dann per app überschrieben wird ist der freeze automatisch drin bis eine minute nach preisZeit. Das wird in der App nicht angezeigt. Ist das okay so?
        _cancelAutoTimer();
      } else if (data['event'] == 'freeze' && data["freeze"] == false) {
        _socketFrozen = false;
        _maybeStartAutoTimer();
      }
      if (data['event'] == 'pageIndex' && data['index'] is int) {
        int newIndex = data['index'];
        if (newIndex != pageIndex || data['reset'] == true) {
          animateNavigation = !(data['reset'] == true);
          overridePageIndex = true;
          _navigateToPage(newIndex);
        }
      }
    };

    ServerManager().addListener(socketPageIndexListener);

    _startPageIndexTimer();
    _schedulePrizeGuard();
  }

  void _navigateToPage(int index) {
    setState(() {
      pageIndex = index;
    });

    if (_navigatorKey.currentContext != null) {
      _navigatorKey.currentState!.pushReplacementNamed('/page$index');
    }
  }

  void _startPageIndexTimer() {
    _pageIndexReloadTimer?.cancel();
    _pageIndexReloadTimer = Timer.periodic(Duration(seconds: CustomDurations.indexNavigationChange), (_) {
      if (!overridePageIndex) {
        int nextIndex = (pageIndex + 1) % 6;
        if (nextIndex == 2 && DateTime.now().isAfter(GlobalSettings.prizeTimes.last)) {
          nextIndex++;
        }
        animateNavigation = true;
        _navigateToPage(nextIndex);
      } else {
        overridePageIndex = false;
      }
    });
  }

  void _schedulePrizeGuard() {
    _prePrizeTimer?.cancel();
    _unfreezeTimer?.cancel();

    if (_nextPrizeIndex >= GlobalSettings.prizeTimes.length) {
      return;
    }

    final prizeTime = GlobalSettings.prizeTimes[_nextPrizeIndex];
    final preStart = prizeTime.subtract(Duration(seconds: CustomDurations.changeToPrizePageBeforePrizeTime));
    final preEnd = prizeTime.add(Duration(seconds: CustomDurations.stayOnPrizePageAfterPrizeTime));
    final now = DateTime.now();

    if (now.isBefore(preStart)) {
      final wait = preStart.difference(now);
      _prePrizeTimer = Timer(wait, _enterPrizeFreeze);
    } else if (!now.isAfter(preEnd)) {
      _enterPrizeFreeze();
      final remaining = preEnd.difference(now);
      _unfreezeTimer = Timer(remaining, _exitPrizeFreeze);
    } else {
      _nextPrizeIndex++;
      _schedulePrizeGuard();
    }
  }

  void _enterPrizeFreeze() {
    animateNavigation = true;
    _navigateToPage(2);
    _cancelAutoTimer();

    _unfreezeTimer?.cancel();
    _unfreezeTimer = Timer(
        Duration(
            seconds: CustomDurations.changeToPrizePageBeforePrizeTime + CustomDurations.stayOnPrizePageAfterPrizeTime),
        _exitPrizeFreeze);
  }

  void _exitPrizeFreeze() {
    _maybeStartAutoTimer();
    _nextPrizeIndex++;
    _schedulePrizeGuard();
  }

  void _cancelAutoTimer() {
    _pageIndexReloadTimer?.cancel();
    _pageIndexReloadTimer = null;
  }

  void _maybeStartAutoTimer() {
    if (_socketFrozen) return;
    if (_pageIndexReloadTimer != null) return;
    _startPageIndexTimer();
  }

  @override
  void dispose() {
    ServerManager().removeListener(socketPageIndexListener);
    _pageIndexReloadTimer?.cancel();
    _prePrizeTimer?.cancel();
    _unfreezeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: billboardBackgroundColor,
        child: Column(
          children: [
            SizedBox(
              height: GlobalSettings.fullscreenIconSize,
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
                            size: GlobalSettings.fullscreenIconSize,
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
                            size: GlobalSettings.fullscreenIconSize,
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
    if (animateNavigation) {
      return PageRouteBuilder(
        transitionDuration: Duration(milliseconds: CustomDurations.navigationTransition),
        pageBuilder: (_, animation, secondaryAnimation) => backgroundContainer(child: page),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          const curve = Curves.ease;

          // New page slides in from right → center
          final inTween = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: curve));

          // Old page slides from center → left
          final outTween = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1.0, 0.0),
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(inTween),
            child: SlideTransition(
              position: secondaryAnimation.drive(outTween),
              child: child,
            ),
          );
        },
      );
    }

    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => backgroundContainer(child: page),
    );
  }

  Widget backgroundContainer({Widget? child}) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/billboard.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
