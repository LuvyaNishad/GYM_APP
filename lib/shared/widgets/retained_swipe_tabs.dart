import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A nav tap can interrupt a viewport even when it selects the same branch.
class TabSelectionIntent extends InheritedWidget {
  const TabSelectionIntent({
    required this.signal,
    required super.child,
    super.key,
  });

  final ValueNotifier<int> signal;

  static ValueNotifier<int>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabSelectionIntent>()?.signal;

  @override
  bool updateShouldNotify(TabSelectionIntent oldWidget) =>
      signal != oldWidget.signal;
}

/// Keeps branch navigators mounted while only visible branches paint.
/// The pointer moves the viewport directly; route changes wait for a completed
/// swipe. A new drag or tab selection interrupts the current settle.
class RetainedSwipeTabs extends StatefulWidget {
  const RetainedSwipeTabs({
    required this.currentIndex,
    required this.children,
    required this.onSelected,
    this.selectionSignal,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;
  final ValueChanged<int> onSelected;
  final Listenable? selectionSignal;

  @override
  State<RetainedSwipeTabs> createState() => _RetainedSwipeTabsState();
}

class _RetainedSwipeTabsState extends State<RetainedSwipeTabs>
    with SingleTickerProviderStateMixin {
  late final _offset = AnimationController.unbounded(vsync: this);
  late int _displayIndex = widget.currentIndex;
  bool _moving = false;
  bool _dragging = false;
  int _gestureOriginIndex = 0;
  int _neighborDirection = 0;
  double _rawOffset = 0;
  double _width = 1;
  int _settleGeneration = 0;
  int? _pendingDestination;

  @override
  void initState() {
    super.initState();
    widget.selectionSignal?.addListener(_jumpToCurrent);
  }

  void _jumpToCurrent() {
    _settleGeneration++;
    _offset.stop();
    setState(() {
      _displayIndex = widget.currentIndex;
      _offset.value = 0;
      _rawOffset = 0;
      _moving = false;
      _dragging = false;
      _neighborDirection = 0;
      _pendingDestination = null;
    });
  }

  @override
  void didUpdateWidget(RetainedSwipeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionSignal != widget.selectionSignal) {
      oldWidget.selectionSignal?.removeListener(_jumpToCurrent);
      widget.selectionSignal?.addListener(_jumpToCurrent);
    }
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_pendingDestination == widget.currentIndex) return;
      _settleGeneration++;
      _offset.stop();
      _displayIndex = widget.currentIndex;
      _rawOffset = 0;
      _offset.value = 0;
      _moving = false;
      _dragging = false;
      _neighborDirection = 0;
      _pendingDestination = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _offset.isAnimating) {
      _settle(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _settleGeneration++;
    widget.selectionSignal?.removeListener(_jumpToCurrent);
    _offset.dispose();
    super.dispose();
  }

  void _dragStart(DragStartDetails details) {
    _settleGeneration++;
    _offset.stop();
    _pendingDestination = null;
    if (_displayIndex != widget.currentIndex) {
      _offset.value += (widget.currentIndex - _displayIndex) * _width;
      _displayIndex = widget.currentIndex;
    }
    _gestureOriginIndex = widget.currentIndex;
    _dragging = true;
    _rawOffset = _offset.value;
    if ((_displayIndex == 0 && _rawOffset > 0) ||
        (_displayIndex == widget.children.length - 1 && _rawOffset < 0)) {
      _rawOffset *= 3;
    }
    setState(() {
      _moving = true;
      _neighborDirection = -_offset.value.sign.toInt();
    });
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _rawOffset += details.delta.dx;
    final atLeadingEdge = _displayIndex == 0 && _rawOffset > 0;
    final atTrailingEdge =
        _displayIndex == widget.children.length - 1 && _rawOffset < 0;
    _offset.value = atLeadingEdge || atTrailingEdge
        ? (_rawOffset / 3).clamp(-_width / 3, _width / 3)
        : _rawOffset.clamp(-_width, _width);
    final direction = -_offset.value.sign.toInt();
    if (direction != _neighborDirection) {
      setState(() => _neighborDirection = direction);
    }
  }

  void _dragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final offset = _offset.value;
    int destination = _displayIndex;
    // Direction follows the last deliberate fling; slow gestures use distance.
    if (velocity.abs() >= 250) {
      if (offset == 0 || velocity.sign == offset.sign) {
        destination += velocity < 0 ? 1 : -1;
      }
    } else if (offset.abs() >= _width * .3) {
      destination += offset < 0 ? 1 : -1;
    }
    _settle(destination.clamp(0, widget.children.length - 1));
  }

  Future<void> _settle(int destination) async {
    final generation = ++_settleGeneration;
    final target = (_displayIndex - destination) * _width;
    _offset.stop();
    _pendingDestination = destination;
    if (destination != widget.currentIndex) {
      HapticFeedback.lightImpact();
      widget.onSelected(destination);
    }
    if (!MediaQuery.disableAnimationsOf(context) &&
        (_offset.value - target).abs() > .5) {
      try {
        await _offset
            .animateTo(
              target,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || generation != _settleGeneration) return;
    setState(() {
      _displayIndex = destination;
      _offset.value = 0;
      _rawOffset = 0;
      _moving = false;
      _neighborDirection = 0;
      _pendingDestination = null;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (_width != width && _offset.value != 0) {
        _settleGeneration++;
        _offset.stop();
        _displayIndex = widget.currentIndex;
        _offset.value = 0;
        _rawOffset = 0;
        _moving = false;
        _dragging = false;
        _neighborDirection = 0;
        _pendingDestination = null;
      }
      _width = width;
      // These subtree objects are retained by AnimatedBuilder between pointer
      // updates; only transforms and offstage flags change with the offset.
      final branches = [
        for (var i = 0; i < widget.children.length; i++)
          RepaintBoundary(
            key: ValueKey('retained-tab-$i'),
            child: ExcludeSemantics(
              excluding: i != widget.currentIndex,
              child: ExcludeFocus(
                excluding: i != widget.currentIndex,
                child: IgnorePointer(
                  ignoring: i != widget.currentIndex,
                  child: TickerMode(
                    enabled:
                        i == widget.currentIndex ||
                        i == _displayIndex ||
                        (_moving &&
                            _neighborDirection != 0 &&
                            i == _displayIndex + _neighborDirection),
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
          ),
      ];
      return GestureDetector(
        key: const ValueKey('retained-swipe-viewport'),
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onHorizontalDragStart: _dragStart,
        onHorizontalDragUpdate: _dragUpdate,
        onHorizontalDragEnd: _dragEnd,
        onHorizontalDragCancel: () {
          if (!_dragging) return;
          _dragging = false;
          _settle(_gestureOriginIndex);
        },
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _offset,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < branches.length; i++)
                  Offstage(
                    offstage:
                        i != _displayIndex &&
                        !(_offset.value < 0 && i == _displayIndex + 1) &&
                        !(_offset.value > 0 && i == _displayIndex - 1),
                    child: Transform.translate(
                      key: ValueKey('retained-tab-offset-$i'),
                      offset: Offset(
                        (i - _displayIndex) * width + _offset.value,
                        0,
                      ),
                      child: branches[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
