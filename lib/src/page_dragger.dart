import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fancy_on_boarding/src/pager_indicator.dart';

class PageDragger extends StatefulWidget {
  final int currentIndex;
  final bool canDragLeftToRight;
  final bool canDragRightToLeft;
  final int pageLength;
  final StreamController<SlideUpdate> slideUpdateStream;
  final bool gestureEnabled;
  final double opacity;
  final double bottomMargin;
  final String previousButtonText;
  final ShapeBorder previousButtonShape;
  final TextStyle previousButtonTextStyle;
  final Color previousButtonColor;
  final String nextButtonText;
  final ShapeBorder nextButtonShape;
  final TextStyle nextButtonTextStyle;
  final Color nextButtonColor;
  final Function(Function(int)) setPageController;

  PageDragger({
    this.pageLength,
    this.currentIndex,
    this.canDragLeftToRight,
    this.canDragRightToLeft,
    this.slideUpdateStream,
    this.gestureEnabled,
    this.opacity,
    this.bottomMargin,
    this.previousButtonText,
    this.previousButtonShape,
    this.previousButtonTextStyle,
    this.previousButtonColor,
    this.nextButtonText,
    this.nextButtonShape,
    this.nextButtonTextStyle,
    this.nextButtonColor,
    this.setPageController,
  });

  @override
  _PageDraggerState createState() {
    var state = _PageDraggerState();

    if (setPageController != null) {
      var updatePage = (int direction) {
        if (direction == -1) {
          state.onChangePage(SlideDirection.leftToRight);
        } else if (direction == 1) {
          state.onChangePage(SlideDirection.rightToLeft);
        }
      };

      setPageController(updatePage);
    }
    return state;
  }
}

class _PageDraggerState extends State<PageDragger> {
  static const FULL_TRANSITION_PX = 300.0;

  int nextPageIndex;
  Offset dragStart;
  SlideDirection slideDirection;
  double slidePercent = 0.0;

  onDragStart(DragStartDetails details) {
    dragStart = details.globalPosition;
  }

  onDragUpdate(DragUpdateDetails details) {
    if (dragStart != null) {
      final newPosition = details.globalPosition;
      final dx = dragStart.dx - newPosition.dx;
      if (dx > 0.0 && widget.canDragRightToLeft) {
        slideDirection = SlideDirection.rightToLeft;
      } else if (dx < 0.0 && widget.canDragLeftToRight) {
        slideDirection = SlideDirection.leftToRight;
      } else {
        slideDirection = SlideDirection.none;
      }

      if (slideDirection != SlideDirection.none) {
        slidePercent = (dx / FULL_TRANSITION_PX).abs().clamp(0.0, 1.0);
      } else {
        slidePercent = 0.0;
      }

      widget.slideUpdateStream.add(SlideUpdate(UpdateType.dragging, slideDirection, slidePercent));
    }
  }

  onDragEnd(DragEndDetails details) {
    widget.slideUpdateStream.add(SlideUpdate(
      UpdateType.doneDragging,
      SlideDirection.none,
      0.0,
    ));
    dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      if (widget.gestureEnabled)
        GestureDetector(
          onHorizontalDragStart: onDragStart,
          onHorizontalDragUpdate: onDragUpdate,
          onHorizontalDragEnd: onDragEnd,
        ),
      if (widget.canDragLeftToRight && widget.previousButtonText != null)
        Positioned(
          top: 8,
          left: 5,
          child: FlatButton(
            shape: widget.previousButtonShape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            color: widget.previousButtonColor,
            child: Text(
              widget.previousButtonText,
              style: widget.previousButtonTextStyle ??
                  const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w800),
            ),
            onPressed: () => onChangePage(SlideDirection.leftToRight),
          ),
        ),
      if (widget.canDragRightToLeft && widget.nextButtonText != null)
        Positioned(
          top: 8,
          right: 5,
          child: FlatButton(
            shape: widget.nextButtonShape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            color: widget.nextButtonColor,
            child: Text(
              widget.nextButtonText,
              style: widget.nextButtonTextStyle ??
                  const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w800),
            ),
            onPressed: () => onChangePage(SlideDirection.rightToLeft),
          ),
        ),
    ]);
  }

  void onChangePage(SlideDirection direction) {
    const PERCENT_PER_MILLISECOND = 1.0 / 32.0;
    Timer.periodic(const Duration(milliseconds: 1), (Timer t) {
      slidePercent += PERCENT_PER_MILLISECOND;
      if (slidePercent >= 1.0) {
        slidePercent = 0.0;
        t.cancel();
        widget.slideUpdateStream.add(SlideUpdate(
          UpdateType.doneDragging,
          SlideDirection.none,
          0.0,
        ));
      } else {
        widget.slideUpdateStream.add(SlideUpdate(
          UpdateType.dragging,
          direction,
          slidePercent,
        ));
      }
    });
  }
}

class AnimatedPageDragger {
  static const PERCENT_PER_MILLISECOND = 0.005;

  final slideDirection;
  final transitionGoal;

  AnimationController completionAnimationController;

  AnimatedPageDragger({
    this.slideDirection,
    this.transitionGoal,
    slidePercent,
    StreamController<SlideUpdate> slideUpdateStream,
    TickerProvider vsync,
  }) {
    final startSlidePercent = slidePercent;
    var endSlidePercent;
    var duration;

    if (transitionGoal == TransitionGoal.open) {
      endSlidePercent = 1.0;
      final slideRemaining = 1.0 - slidePercent;
      duration = Duration(milliseconds: (slideRemaining / PERCENT_PER_MILLISECOND).round());
    } else {
      endSlidePercent = 0.0;
      duration = Duration(milliseconds: (slidePercent / PERCENT_PER_MILLISECOND).round());
    }

    completionAnimationController = AnimationController(duration: duration, vsync: vsync)
      ..addListener(() {
        slidePercent = lerpDouble(
          startSlidePercent,
          endSlidePercent,
          completionAnimationController.value,
        );

        slideUpdateStream.add(SlideUpdate(
          UpdateType.animating,
          slideDirection,
          slidePercent,
        ));
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          slideUpdateStream.add(SlideUpdate(
            UpdateType.doneAnimating,
            slideDirection,
            endSlidePercent,
          ));
        }
      });
  }

  run() {
    completionAnimationController.forward(from: 0.0);
  }

  dispose() {
    completionAnimationController.dispose();
  }
}

enum TransitionGoal {
  open,
  close,
}

enum UpdateType {
  dragging,
  doneDragging,
  animating,
  doneAnimating,
}

class SlideUpdate {
  final updateType;
  final direction;
  final slidePercent;

  SlideUpdate(
    this.updateType,
    this.direction,
    this.slidePercent,
  );
}
