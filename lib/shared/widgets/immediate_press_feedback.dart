import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Supplies native controls with a pressed state on the first pointer event.
/// Tap recognition, keyboard focus and semantics still belong to the control.
class ImmediatePressFeedback extends StatefulWidget {
  const ImmediatePressFeedback({
    required this.builder,
    this.enabled = true,
    super.key,
  });

  final bool enabled;
  final Widget Function(BuildContext, WidgetStatesController) builder;

  @override
  State<ImmediatePressFeedback> createState() => _ImmediatePressFeedbackState();
}

class _ImmediatePressFeedbackState extends State<ImmediatePressFeedback> {
  final _states = WidgetStatesController();
  int? _pointer;
  Offset? _origin;

  void _clear() {
    _pointer = null;
    _origin = null;
    _states.update(WidgetState.pressed, false);
  }

  @override
  void didUpdateWidget(ImmediatePressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _clear();
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (event) {
      if (!widget.enabled ||
          _pointer != null ||
          event.buttons & kPrimaryButton == 0) {
        return;
      }
      _pointer = event.pointer;
      _origin = event.localPosition;
      _states.update(WidgetState.pressed, true);
    },
    onPointerMove: (event) {
      if (_pointer != event.pointer) return;
      final slop =
          MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;
      final size = context.size;
      final position = event.localPosition;
      if ((position - _origin!).distanceSquared > slop * slop ||
          (size != null && !(Offset.zero & size).contains(position))) {
        _clear();
      }
    },
    onPointerUp: (event) {
      if (_pointer == event.pointer) _clear();
    },
    onPointerCancel: (event) {
      if (_pointer == event.pointer) _clear();
    },
    child: widget.builder(context, _states),
  );
}
