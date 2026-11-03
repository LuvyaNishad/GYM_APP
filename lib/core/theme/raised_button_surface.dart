import 'package:flutter/material.dart';

/// A shallow bevel over the button's own fill, preserving its semantic colour.
/// Native buttons continue to own input, focus, ink feedback and disabled state.
ButtonStyle withRaisedButtonSurface(ButtonStyle style) => style.copyWith(
  backgroundBuilder: raisedButtonBackground,
  elevation: WidgetStateProperty.resolveWith<double>(
    (states) =>
        states.contains(WidgetState.disabled) ||
            states.contains(WidgetState.pressed)
        ? 0
        : 1,
  ),
  shadowColor: const WidgetStatePropertyAll(Color(0x50000000)),
  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
);

Widget plainButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => child ?? const SizedBox.shrink();

Widget raisedButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  if (states.contains(WidgetState.disabled)) {
    return child ?? const SizedBox.shrink();
  }
  final pressed = states.contains(WidgetState.pressed);
  final button = context.widget;
  final style = button is ButtonStyleButton ? button.style : null;
  final themeStyle = switch (button) {
    FilledButton() => FilledButtonTheme.of(context).style,
    ElevatedButton() => ElevatedButtonTheme.of(context).style,
    _ => null,
  };
  final shape =
      style?.shape?.resolve(states) ??
      themeStyle?.shape?.resolve(states) ??
      const StadiumBorder();
  return Ink(
    decoration: ShapeDecoration(
      shape: shape,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: pressed ? .055 : .16),
          Colors.white.withValues(alpha: pressed ? .02 : .05),
          Colors.transparent,
          Colors.black.withValues(alpha: pressed ? .045 : .095),
        ],
        stops: const [0, .33, .58, 1],
      ),
    ),
    child: CustomPaint(
      painter: _ButtonBevelPainter(
        shape: shape,
        pressed: pressed,
        textDirection: Directionality.of(context),
      ),
      child: child,
    ),
  );
}

class _ButtonBevelPainter extends CustomPainter {
  const _ButtonBevelPainter({
    required this.shape,
    required this.pressed,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final bool pressed;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: pressed ? .18 : .42),
          Colors.white.withValues(alpha: .06),
          Colors.transparent,
          Colors.black.withValues(alpha: pressed ? .12 : .24),
        ],
        stops: const [0, .24, .55, 1],
      ).createShader(rect);
    canvas.drawPath(
      shape.getOuterPath(rect.deflate(.75), textDirection: textDirection),
      rim,
    );
  }

  @override
  bool shouldRepaint(covariant _ButtonBevelPainter oldDelegate) =>
      shape != oldDelegate.shape ||
      pressed != oldDelegate.pressed ||
      textDirection != oldDelegate.textDirection;
}
