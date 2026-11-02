import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../models/workout_model.dart';
import '../../../services/workout_service.dart';

class WorkoutRecapService {
  static Future<void>? _fonts;
  static Future<void> _loadFonts() async {
    for (final (family, asset) in [
      ('Outfit', 'Outfit-Regular'),
      ('JetBrainsMono', 'JetBrainsMono-Regular'),
      ('ChakraPetch', 'ChakraPetch-Regular'),
    ]) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$asset.ttf'))).load();
    }
  }

  static Future<Uint8List> png(
    WorkoutModel workout, {
    MeasurementUnits units = const MeasurementUnits(),
    bool includeDetails = false,
  }) async {
    await (_fonts ??= _loadFonts());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1080, 1920),
      Paint()..color = const Color(0xff141722),
    );
    void text(
      String value,
      double y, {
      double size = 36,
      Color color = Colors.white,
      bool mono = false,
      int lines = 2,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: mono ? 'JetBrainsMono' : 'Outfit',
            fontFamilyFallback: const ['JetBrainsMono', 'ChakraPetch'],
            fontSize: size,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: lines,
        ellipsis: '…',
      )..layout(maxWidth: 936);
      painter.paint(canvas, Offset(72, y));
    }

    text(AppConstants.appName, 80, size: 54, color: const Color(0xff00e5ff));
    text('WORKOUT COMPLETE', 190, size: 62);
    if (includeDetails) {
      text(workout.name, 300, size: 44);
      text(
        workout.date.toLocal().toString().split(' ').first,
        410,
        size: 30,
        color: const Color(0xff94a3b8),
        mono: true,
      );
    } else {
      text('Training recap', 320, size: 44);
    }
    final sets = workout.exercises.fold(
      0,
      (sum, e) =>
          sum + (e.isWarmup ? 0 : e.sets.where((s) => !s.isWarmup).length),
    );
    text(
      '${workout.durationSeconds ~/ 60} MIN  ·  $sets SETS',
      500,
      size: 44,
      mono: true,
    );
    text(
      '${units.weight(WorkoutService.totalVolumeKg(workout))} LIFTED',
      585,
      size: 44,
      mono: true,
    );
    text(
      'Working sets only · includes each recorded side',
      690,
      size: 28,
      color: const Color(0xff94a3b8),
    );
    final exercises = workout.exercises
        .where((e) => !e.isWarmup && e.sets.any((s) => !s.isWarmup))
        .toList();
    if (includeDetails) {
      for (final (i, e) in exercises.take(7).indexed) {
        text(e.exerciseName, 800 + i * 125, size: 34, lines: 1);
        text(
          '${e.sets.where((s) => !s.isWarmup).length} working sets',
          865 + i * 125,
          size: 28,
          color: const Color(0xff94a3b8),
        );
      }
      if (exercises.length > 7) {
        text('+ ${exercises.length - 7} more exercises', 1700, size: 30);
      }
    } else {
      text('${exercises.length} EXERCISES', 840, size: 42, mono: true);
      text('Keep showing up.', 1100, size: 58);
    }
    text(
      'Profile name, notes and body measurements omitted',
      1800,
      size: 26,
      color: const Color(0xff94a3b8),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1080, 1920);
    try {
      final data = await image
          .toByteData(format: ui.ImageByteFormat.png)
          .timeout(const Duration(seconds: 10));
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}
