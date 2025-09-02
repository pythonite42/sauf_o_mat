import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'package:shotcounter_zieefaegge/backend_connection.dart';

class PageQuote extends StatefulWidget {
  const PageQuote({super.key});

  @override
  State<PageQuote> createState() => _PageQuoteState();
}

class _PageQuoteState extends State<PageQuote> {
  bool dataLoaded = false;

  late Timer _dataReloadTimer;

  String username = "";
  List<String> quotes = [];
  String imageUrl = "";
  String recordId = "";

  @override
  void initState() {
    super.initState();

    _loadData();
    _startAutoReloadData();
  }

  void _startAutoReloadData() {
    _dataReloadTimer = Timer.periodic(Duration(seconds: CustomDurations.reloadDataQuote), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      //Map data = await MockDataPage4().getData();
      Map data = await SalesforceService().getPageQuote();

      if (mounted) {
        setState(() {
          recordId = data["recordId"];
          username = data["name"];
          quotes = data["quotes"] as List<String>;
          imageUrl = data["image"];
          dataLoaded = true;
        });
        if (recordId.isNotEmpty) {
          await SalesforceService().setPageQuoteQueryUsed(recordId, DateTime.now());
        }
      }
    } catch (e) {
      debugPrint('Error fetching page 4 quote: $e');
    }
  }

  @override
  void dispose() {
    _dataReloadTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(MySize(context).h * 0.08),
      child: !dataLoaded
          ? Center(
              child: CircularProgressIndicator(color: defaultOnPrimary),
            )
          : AspectRatio(
              aspectRatio: 16 / 9,
              child: Card(
                color: Color(0xFFF8F9FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(MySize(context).h * 0.08),
                  child: Row(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipOval(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Image.asset(
                              'assets/placeholder_single.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: MySize(context).w * 0.1),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: MySize(context).h * 0.1),
                            Text(
                              "@$username",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 50,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: MySize(context).h * 0.1),

                            /*
                            // Slide Transition: 
 
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.5),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                quote,
                                key: ValueKey(quote), 

                                style: const TextStyle(
                                  fontSize: 35,
                                  color: Colors.black87,
                                ),
                              ),
                            ), */

                            /* 
                            // Carousel Transition:

                            Expanded(
                              child: QuoteCarousel(
                                quotes: [
                                  "Flutter makes building apps delightful.",
                                  "Write once, run anywhere.",
                                  "Smooth animations make great UX.",
                                  "Build beautiful UIs, fast.",
                                ],
                              ),
                            ), */

                            // Fade Transition:
                            FadingQuoteCarousel(
                              quotes: quotes,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/*
class QuoteCarousel extends StatefulWidget {
  final List<String> quotes;
  final Duration switchDuration;
  final Duration animationDuration;

  const QuoteCarousel({
    super.key,
    required this.quotes,
    this.switchDuration = const Duration(seconds: 4),
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<QuoteCarousel> {
  late final PageController _controller;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();

    _timer = Timer.periodic(widget.switchDuration, (timer) {
      _currentPage = (_currentPage + 1) % widget.quotes.length;
      _controller.animateToPage(
        _currentPage,
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.quotes.length,
      itemBuilder: (context, index) {
        return Text(
          widget.quotes[index],
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 35,
            color: Colors.black87,
          ),
        );
      },
    );
  }
}
*/

class FadingQuoteCarousel extends StatefulWidget {
  final List<String> quotes;

  const FadingQuoteCarousel({
    super.key,
    required this.quotes,
  });

  @override
  State<FadingQuoteCarousel> createState() => _FadingQuoteCarouselState();
}

class _FadingQuoteCarouselState extends State<FadingQuoteCarousel> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: CustomDurations.switchQuote), (_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.quotes.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: CustomDurations.fadeTransistion),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        widget.quotes[_currentIndex],
        key: ValueKey(widget.quotes[_currentIndex]),
        textAlign: TextAlign.start,
        style: const TextStyle(
          fontSize: 35,
          color: Colors.black87,
        ),
      ),
    );
  }
}
