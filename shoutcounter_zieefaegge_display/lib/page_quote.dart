import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/backend_mockdata.dart';
import 'package:shotcounter_zieefaegge/colors.dart';
import 'package:shotcounter_zieefaegge/globals.dart';

class PageQuote extends StatefulWidget {
  const PageQuote({super.key});

  @override
  State<PageQuote> createState() => _PageQuoteState();
}

class _PageQuoteState extends State<PageQuote> {
  bool dataLoaded = false;

  late Timer _dataReloadTimer;

  String username = "";
  String quote = "";
  String imageUrl = "";

  @override
  void initState() {
    super.initState();

    _loadImage();
    _startAutoReloadImage();
  }

  void _startAutoReloadImage() {
    _dataReloadTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _loadImage();
    });
  }

  Future<void> _loadImage() async {
    try {
      Map data = await MockDataPage4().getData();

      if (mounted) {
        setState(() {
          username = data["name"];
          quote = data["quote"];
          imageUrl = data["image"];
          dataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching page 3 schedule image: $e');
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
                            errorBuilder: (context, _, __) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.person, size: MySize(context).h * 0.4),
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
                              quotes: [
                                "The best way to predict the future is to invent it.",
                                "Flutter lets you build beautiful apps fast.",
                                "Don’t watch the clock; do what it does — keep going.",
                                "Creativity is intelligence having fun.",
                              ],
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

class FadingQuoteCarousel extends StatefulWidget {
  final List<String> quotes;
  final Duration switchDuration;
  final Duration fadeDuration;

  const FadingQuoteCarousel({
    super.key,
    required this.quotes,
    this.switchDuration = const Duration(seconds: 4),
    this.fadeDuration = const Duration(milliseconds: 800),
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
    _timer = Timer.periodic(widget.switchDuration, (_) {
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
      duration: widget.fadeDuration,
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
