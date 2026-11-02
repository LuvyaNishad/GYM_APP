import 'package:flutter/material.dart';

/// Animate only the incoming retained branch, keeping navigation stationary.
class TabReveal extends StatefulWidget {
  const TabReveal({
    required this.index,
    required this.child,
    this.sliver = false,
    super.key,
  });
  final int index;
  final Widget child;
  final bool sliver;

  @override
  State<TabReveal> createState() => _TabRevealState();
}

class _TabRevealState extends State<TabReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  double _direction = 1;

  @override
  void didUpdateWidget(TabReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _direction = widget.index > oldWidget.index ? 1 : -1;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.sliver
      ? SliverFadeTransition(
          opacity: Tween<double>(begin: .94, end: 1).animate(_curve),
          sliver: widget.child,
        )
      : SlideTransition(
          position: Tween<Offset>(
            begin: Offset(.018 * _direction, 0),
            end: Offset.zero,
          ).animate(_curve),
          child: RepaintBoundary(child: widget.child),
        );
}
