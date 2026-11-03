import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/providers/home_workout_view_provider.dart';
import 'package:leon/features/dashboard/widgets/daily_workout_bento_card.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/services/hive_service.dart';
import '../helpers/memory_hive_service.dart';

void main() {
  testWidgets(
    'Home primary paints press on first frame and scroll cancellation cannot start',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = MemoryHiveService();
      final frame = GlobalKey();
      var starts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(storage),
            homeWorkoutViewProvider.overrideWith(
              (ref) => HomeWorkoutView(
                date: DateTime.now(),
                day: const SplitWorkoutDay(
                  id: 'press-test',
                  name: 'Push Day',
                  targetMuscles: ['Chest'],
                ),
                logged: const [],
                isToday: true,
                isPast: false,
              ),
            ),
          ],
          child: RepaintBoundary(
            key: frame,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      DailyWorkoutBentoCard(
                        compact: true,
                        onStartWorkout: () => starts++,
                      ),
                      const SizedBox(height: 1400),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      Future<List<int>> pixels() async {
        final bytes = await tester.runAsync(() async {
          final boundary =
              frame.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final result = data!.buffer.asUint8List().toList();
          image.dispose();
          return result;
        });
        return bytes!;
      }

      final button = find.widgetWithText(FilledButton, 'START WORKOUT');
      final idle = await pixels();
      final time = tester.binding.clock.now();
      final finger = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      final pressed = await pixels();
      expect(tester.binding.clock.now(), time);
      expect(
        listEquals(idle, pressed),
        isFalse,
        reason:
            'The first pointer frame must visibly change before the native tap timeout.',
      );
      expect(starts, 0);
      await finger.moveBy(const Offset(0, -90));
      await tester.pump();
      await finger.up();
      await tester.pump();
      expect(starts, 0);
      expect(storage.documentWrites, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
