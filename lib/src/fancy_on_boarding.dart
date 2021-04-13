library fancy_on_boarding;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:fancy_on_boarding/src/fancy_page.dart';
import 'package:fancy_on_boarding/src/page_dragger.dart';
import 'package:fancy_on_boarding/src/page_model.dart';
import 'package:fancy_on_boarding/src/page_reveal.dart';
import 'package:fancy_on_boarding/src/pager_indicator.dart';
import 'package:flutter/material.dart';

class FancyOnBoarding extends StatefulWidget {
  final List<PageModel> pageList;
  final VoidCallback onDoneButtonPressed;
  final VoidCallback onSkipButtonPressed;
  final String doneButtonText;
  final ShapeBorder doneButtonShape;
  final TextStyle doneButtonTextStyle;
  final Color doneButtonBackgroundColor;
  final String skipButtonText;
  final TextStyle skipButtonTextStyle;
  final Color skipButtonColor;
  final bool showSkipButton;
  final double bottomMargin;
  final Widget doneButton;
  final Widget skipButton;
  final String previousButtonText;
  final ShapeBorder previousButtonShape;
  final TextStyle previousButtonTextStyle;
  final Color previousButtonColor;
  final String nextButtonText;
  final ShapeBorder nextButtonShape;
  final TextStyle nextButtonTextStyle;
  final Color nextButtonColor;
  final bool gestureEnabled;
  final Function(bool Function(int)) setPageController;

  FancyOnBoarding({
    @required this.pageList,
    this.onDoneButtonPressed,
    this.onSkipButtonPressed,
    this.doneButtonText = "Done",
    this.doneButtonShape,
    this.doneButtonTextStyle,
    this.doneButtonBackgroundColor,
    this.skipButtonText = "Skip",
    this.skipButtonTextStyle,
    this.skipButtonColor,
    this.showSkipButton = false,
    this.bottomMargin = 8.0,
    this.doneButton,
    this.skipButton,
    this.previousButtonText,
    this.previousButtonShape,
    this.previousButtonTextStyle,
    this.previousButtonColor,
    this.nextButtonText,
    this.nextButtonShape,
    this.nextButtonTextStyle,
    this.nextButtonColor,
    this.gestureEnabled = true,
    this.setPageController,
  }) : assert(pageList.length != 0);

  @override
  _FancyOnBoardingState createState() => _FancyOnBoardingState();
}

class _FancyOnBoardingState extends State<FancyOnBoarding> with TickerProviderStateMixin {
  StreamController<SlideUpdate> slideUpdateStream;
  AnimatedPageDragger animatedPageDragger;
  List<PageModel> pageList;
  int activeIndex = 0;
  int nextPageIndex = 0;
  SlideDirection slideDirection = SlideDirection.none;
  double slidePercent = 0.0;

  bool get isRTL => ui.window.locale.languageCode.toLowerCase() == "ar";

  @override
  void initState() {
    super.initState();
    this.pageList = widget.pageList;
    this.slideUpdateStream = StreamController<SlideUpdate>();
    _listenSlideUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          FancyPage(
            constraints: constraints,
            model: pageList[activeIndex],
            percentVisible: 1.0,
          ),
          PageReveal(
            revealPercent: slidePercent,
            child: FancyPage(
              constraints: constraints,
              model: pageList[nextPageIndex],
              percentVisible: slidePercent,
            ),
          ),
          Positioned(
            bottom: widget.bottomMargin,
            child: PagerIndicator(
              isRtl: isRTL,
              viewModel: PagerIndicatorViewModel(
                pageList,
                activeIndex,
                slideDirection,
                slidePercent,
              ),
            ),
          ),
          PageDragger(
            pageLength: pageList.length - 1,
            currentIndex: activeIndex,
            canDragLeftToRight: activeIndex > 0,
            canDragRightToLeft: activeIndex < pageList.length - 1,
            slideUpdateStream: this.slideUpdateStream,
            gestureEnabled: widget.gestureEnabled,
            opacity: opacity,
            bottomMargin: widget.bottomMargin,
            previousButtonText: widget.previousButtonText,
            previousButtonShape: widget.previousButtonShape,
            previousButtonTextStyle: widget.previousButtonTextStyle,
            previousButtonColor: widget.previousButtonColor,
            nextButtonText: widget.nextButtonText,
            nextButtonShape: widget.nextButtonShape,
            nextButtonTextStyle: widget.nextButtonTextStyle,
            nextButtonColor: widget.nextButtonColor,
            setPageController: widget.setPageController,
          ),
          if (widget.onDoneButtonPressed != null)
            Positioned(
              bottom: widget.bottomMargin,
              right: isRTL ? null : 8,
              left: isRTL ? 8 : null,
              child: Opacity(
                opacity: opacity,
                child: widget.doneButton ??
                    FlatButton(
                      shape:
                          widget.doneButtonShape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                      color: widget.doneButtonBackgroundColor ?? const Color(0x88FFFFFF),
                      child: Text(
                        widget.doneButtonText,
                        style: widget.doneButtonTextStyle ??
                            const TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w800),
                      ),
                      onPressed: opacity == 1.0 ? widget.onDoneButtonPressed : () {},
                    ),
              ),
            ),
          widget.showSkipButton
              ? Positioned(
                  top: MediaQuery.of(context).padding.top,
                  right: isRTL ? null : 0,
                  left: isRTL ? 0 : null,
                  child: widget.skipButton ??
                      FlatButton(
                        color: widget.skipButtonColor,
                        child: Text(
                          widget.skipButtonText,
                          style: widget.skipButtonTextStyle ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        onPressed: widget.onSkipButtonPressed,
                      ),
                )
              : Offstage()
        ],
      );
    });
  }

  _listenSlideUpdate() {
    slideUpdateStream.stream.listen((SlideUpdate event) {
      setState(() {
        if (event.updateType == UpdateType.dragging) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;

          if (slideDirection == SlideDirection.leftToRight && activeIndex > 0) {
            nextPageIndex = activeIndex - 1;
          } else if (slideDirection == SlideDirection.rightToLeft && activeIndex < pageList.length - 1) {
            nextPageIndex = activeIndex + 1;
          } else {
            nextPageIndex = activeIndex;
          }
        } else if (event.updateType == UpdateType.doneDragging) {
          if (slidePercent > 0.5) {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.open,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          } else {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.close,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
            nextPageIndex = activeIndex;
          }

          animatedPageDragger.run();
        } else if (event.updateType == UpdateType.animating) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;
        } else if (event.updateType == UpdateType.doneAnimating) {
          activeIndex = nextPageIndex;

          slideDirection = SlideDirection.none;
          slidePercent = 0.0;

          animatedPageDragger.dispose();
        }
      });
    });
  }

  double get opacity {
    if (pageList.length - 2 == activeIndex && slideDirection == SlideDirection.rightToLeft) return slidePercent;
    if (pageList.length - 1 == activeIndex && slideDirection == SlideDirection.leftToRight) return 1 - slidePercent;
    if (pageList.length - 1 == activeIndex) return 1.0;
    return 0.0;
  }

  @override
  void dispose() {
    slideUpdateStream?.close();
    super.dispose();
  }
}
