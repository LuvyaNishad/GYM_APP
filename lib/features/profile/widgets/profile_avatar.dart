import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/avatar_service.dart';
import '../models/avatar_reference.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.reference,
    required this.name,
    this.size = 64,
    this.bytes,
  });
  final String? reference;
  final String name;
  final double size;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = AvatarReference.presetId(reference);
    final photo = AvatarReference.photoId(reference);
    final fallback = ColoredBox(
      color: AppColors.surfaceSecondary,
      child: Center(
        child: Text(
          name.isEmpty ? 'G' : name.characters.first.toUpperCase(),
          style: AppTypography.headlineMedium.copyWith(
            fontSize: (size * .34).clamp(11, 44),
          ),
        ),
      ),
    );
    Widget child = fallback;
    if (preset != null) {
      child = CustomPaint(
        painter: PortraitPainter(AvatarReference.presets.indexOf(preset)),
      );
    } else if (bytes != null) {
      child = Image.memory(
        bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (photo != null) {
      final data = ref.watch(avatarBytesProvider(photo));
      child = data.when(
        data: (value) => value == null
            ? fallback
            : Image.memory(
                value,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
        error: (_, _) => fallback,
        loading: () => fallback,
      );
    } else if (Uri.tryParse(reference ?? '')?.scheme == 'https') {
      child = Image.network(
        reference!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(child: child),
      ),
    );
  }
}

/// Small, deterministic vector portraits; no network, fonts or raster decoding.
class PortraitPainter extends CustomPainter {
  const PortraitPainter(this.index);
  final int index;
  static const _backgrounds = [
    0xFF71836F,
    0xFF505C68,
    0xFF7A8060,
    0xFF859198,
    0xFF9C9384,
    0xFF414D60,
    0xFF91A09B,
    0xFF777579,
  ];
  static const _skins = [
    0xFFE3C5A9,
    0xFFAB7959,
    0xFFC89875,
    0xFFF0D1B7,
    0xFF8F614A,
    0xFFDFB48D,
    0xFFC08C69,
    0xFFE5BEA0,
  ];
  static const _hair = [
    0xFF303934,
    0xFF27282C,
    0xFF33322D,
    0xFF5C5048,
    0xFF222A29,
    0xFF312F32,
    0xFF3E3934,
    0xFF62564C,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final bg = Color(_backgrounds[index]);
    final skin = Color(_skins[index]);
    final hair = Color(_hair[index]);
    final paint = Paint();
    void oval(Rect r, Color color) => canvas.drawOval(r, paint..color = color);
    void path(Path p, Color color) => canvas.drawPath(p, paint..color = color);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      paint
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(bg, Colors.white, .18)!,
            bg,
            Color.lerp(bg, Colors.black, .15)!,
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    paint.shader = null;
    // Quiet concentric detailing gives the portraits a shared collection style.
    canvas.drawCircle(
      const Offset(77, 21),
      37,
      paint..color = const Color(0x16FFFFFF),
    );
    final longHair = index == 2 || index == 3 || index == 6;
    if (longHair) oval(const Rect.fromLTWH(23, 19, 55, 71), hair);
    path(
      Path()
        ..moveTo(8, 104)
        ..cubicTo(12, 76, 28, 73, 41, 72)
        ..lineTo(59, 72)
        ..cubicTo(77, 73, 90, 80, 94, 104)
        ..close(),
      Color.lerp(bg, const Color(0xFF19232B), .72)!,
    );
    path(
      Path()
        ..moveTo(41, 61)
        ..lineTo(59, 61)
        ..lineTo(61, 75)
        ..quadraticBezierTo(50, 86, 39, 75)
        ..close(),
      Color.lerp(skin, Colors.black, .07)!,
    );
    oval(const Rect.fromLTWH(28, 42, 10, 15), skin);
    oval(const Rect.fromLTWH(63, 42, 10, 15), skin);
    path(
      Path()
        ..moveTo(33, 35)
        ..cubicTo(33, 19, 66, 19, 67, 35)
        ..lineTo(66, 53)
        ..cubicTo(65, 64, 56, 72, 50, 72)
        ..cubicTo(43, 72, 34, 63, 33, 53)
        ..close(),
      skin,
    );
    if (index == 1 || index == 4) {
      path(
        Path()
          ..moveTo(31, 41)
          ..lineTo(30, 30)
          ..cubicTo(33, 14, 62, 14, 69, 31)
          ..lineTo(68, 42)
          ..lineTo(62, 31)
          ..quadraticBezierTo(49, 34, 37, 31)
          ..close(),
        hair,
      );
    } else if (longHair) {
      path(
        Path()
          ..moveTo(28, 53)
          ..lineTo(28, 31)
          ..cubicTo(27, 12, 71, 13, 73, 34)
          ..lineTo(72, 64)
          ..lineTo(65, 43)
          ..lineTo(59, 28)
          ..quadraticBezierTo(49, 43, 34, 39)
          ..close(),
        hair,
      );
    } else {
      path(
        Path()
          ..moveTo(31, 43)
          ..lineTo(27, 31)
          ..lineTo(34, 26)
          ..lineTo(32, 21)
          ..cubicTo(41, 17, 56, 17, 66, 23)
          ..lineTo(71, 35)
          ..lineTo(67, 44)
          ..lineTo(61, 34)
          ..quadraticBezierTo(44, 40, 35, 34)
          ..close(),
        hair,
      );
    }
    final ink = Color.lerp(hair, skin, .15)!;
    // Brows, eyes, nose and a restrained smile.
    paint
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(39, 45), const Offset(45, 44), paint);
    canvas.drawLine(const Offset(56, 44), const Offset(62, 45), paint);
    paint.style = PaintingStyle.fill;
    oval(const Rect.fromLTWH(41, 48, 2.5, 3), ink);
    oval(const Rect.fromLTWH(57, 48, 2.5, 3), ink);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Color.lerp(skin, hair, .3)!;
    canvas.drawPath(
      Path()
        ..moveTo(50, 49)
        ..lineTo(48, 56)
        ..lineTo(52, 56),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(45, 61)
        ..quadraticBezierTo(50, 64, 55, 61),
      paint,
    );
    if (index == 1 || index == 7) {
      paint
        ..color = hair
        ..strokeWidth = 1.7;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(36, 46, 12, 9),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(53, 46, 12, 9),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawLine(const Offset(48, 49), const Offset(53, 49), paint);
    }
    paint
      ..style = PaintingStyle.stroke
      ..color = Color.lerp(bg, Colors.white, .32)!
      ..strokeWidth = 1.4;
    canvas.drawPath(
      Path()
        ..moveTo(36, 78)
        ..quadraticBezierTo(50, 91, 65, 78),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PortraitPainter oldDelegate) => oldDelegate.index != index;
}
