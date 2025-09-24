import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shotcounter_zieefaegge/theme.dart';
import 'package:shotcounter_zieefaegge/globals.dart';
import 'package:shotcounter_zieefaegge/backend_connection.dart';

class PageQuote extends StatelessWidget {
  const PageQuote({super.key});

  Future<Map> _fetchQuoteData() async {
    try {
      return await SalesforceService().getPageQuote();
    } catch (e) {
      debugPrint('Error fetching page 4 quote: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(MySize(context).h * 0.08),
      child: FutureBuilder<Map>(
        future: _fetchQuoteData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: defaultOnPrimary),
            );
          } else {
            SalesforceService().setPageQuoteQueryUsed(snapshot.data!["recordId"], DateTime.now());
            final username = snapshot.data!["name"] ?? "";
            final handle = snapshot.data!["handle"] ?? "";
            final quotes = snapshot.data!["quotes"] ?? [] as List<String>;
            final imageUrl = snapshot.data!["image"] ?? "";
            return AspectRatio(
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
                      SizedBox(width: MySize(context).w * 0.05),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 60,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "@$handle",
                              style: const TextStyle(
                                fontSize: 30,
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
            );
          }
        },
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
