import 'package:flutter/material.dart';

/// Custom painter for the tactical notched card header with a protruding
/// center notch tab and horizontal grab handle pill (inspired by Leon/RE4 HUD).
class NotchedHeaderPainter extends CustomPainter {
  const NotchedHeaderPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.handleColor,
    this.bottomRadius = 24.0,
    this.tabWidth = 76.0,
    this.tabHeight = 18.0,
    this.tabCornerRadius = 8.0,
    this.filletRadius = 10.0,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color handleColor;
  final double bottomRadius;
  final double tabWidth;
  final double tabHeight;
  final double tabCornerRadius;
  final double filletRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - tabHeight; // main card bottom baseline
    final cx = w / 2;
    final halfTab = tabWidth / 2;

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final handlePaint = Paint()
      ..color = handleColor
      ..style = PaintingStyle.fill;

    // Full closed path for solid background fill
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h - bottomRadius);
    path.quadraticBezierTo(w, h, w - bottomRadius, h);

    // Right shoulder fillet into center notch tab
    path.lineTo(cx + halfTab + filletRadius, h);
    path.quadraticBezierTo(
      cx + halfTab, h,
      cx + halfTab, h + filletRadius,
    );
    path.lineTo(cx + halfTab, h + tabHeight - tabCornerRadius);
    path.quadraticBezierTo(
      cx + halfTab, h + tabHeight,
      cx + halfTab - tabCornerRadius, h + tabHeight,
    );
    path.lineTo(cx - halfTab + tabCornerRadius, h + tabHeight);
    path.quadraticBezierTo(
      cx - halfTab, h + tabHeight,
      cx - halfTab, h + tabHeight - tabCornerRadius,
    );
    path.lineTo(cx - halfTab, h + filletRadius);
    path.quadraticBezierTo(
      cx - halfTab, h,
      cx - halfTab - filletRadius, h,
    );

    // Bottom edge to bottom-left corner
    path.lineTo(bottomRadius, h);
    path.quadraticBezierTo(0, h, 0, h - bottomRadius);
    path.close();

    canvas.drawPath(path, fillPaint);

    // Stroke along the bottom perimeter including the notch
    final borderPath = Path();
    borderPath.moveTo(0, h - bottomRadius);
    borderPath.quadraticBezierTo(0, h, bottomRadius, h);
    borderPath.lineTo(cx - halfTab - filletRadius, h);
    borderPath.quadraticBezierTo(
      cx - halfTab, h,
      cx - halfTab, h + filletRadius,
    );
    borderPath.lineTo(cx - halfTab, h + tabHeight - tabCornerRadius);
    borderPath.quadraticBezierTo(
      cx - halfTab, h + tabHeight,
      cx - halfTab + tabCornerRadius, h + tabHeight,
    );
    borderPath.lineTo(cx + halfTab - tabCornerRadius, h + tabHeight);
    borderPath.quadraticBezierTo(
      cx + halfTab, h + tabHeight,
      cx + halfTab, h + tabHeight - tabCornerRadius,
    );
    borderPath.lineTo(cx + halfTab, h + filletRadius);
    borderPath.quadraticBezierTo(
      cx + halfTab, h,
      cx + halfTab + filletRadius, h,
    );
    borderPath.lineTo(w - bottomRadius, h);
    borderPath.quadraticBezierTo(w, h, w, h - bottomRadius);

    canvas.drawPath(borderPath, strokePaint);

    // Drag handle pill centered inside the protruding tab
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h + (tabHeight / 2)),
        width: 32.0,
        height: 4.0,
      ),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(handleRect, handlePaint);
  }

  @override
  bool shouldRepaint(covariant NotchedHeaderPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.handleColor != handleColor ||
        oldDelegate.tabHeight != tabHeight ||
        oldDelegate.bottomRadius != bottomRadius;
  }
}
