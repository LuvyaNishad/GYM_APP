import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/core/widgets/muscle_spider_chart.dart';
import 'package:leon/features/history/models/training_coverage.dart';
import 'package:leon/features/workout_builder/widgets/muscle_radar_chart.dart';
import 'package:leon/models/muscle_radar_data.dart';
import 'package:leon/models/progress_model.dart';
import 'package:leon/shared/widgets/training_coverage_radar.dart';

MuscleSpiderPainter painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('training-coverage-web')),
            )
            .painter!
        as MuscleSpiderPainter;

void main() {
  test(
    'anatomical groups combine without dropping leg, arm, or core volume',
    () {
      final totals = muscleRadarTotals({
        'Lats': 4,
        'Mid back': 2,
        'Upper traps': 1,
        'Quads': 3,
        'Hamstrings': 2,
        'Glutes': 4,
        'Calves': 1,
        'Chest': 5,
        'Biceps': 2,
        'Triceps': 3,
        'Forearms': 1,
        'Abs': 2,
        'Obliques': 1,
        'Front delts': 1,
        'Rear delts': 2,
        'Cardio': 100,
      });
      expect(totals.keys, muscleRadarCategories);
      expect(totals.values, [7, 10, 5, 6, 3, 3]);
      expect(radarMuscleCategory('biceps femoris'), 'Legs');
      expect(
        muscleRadarTotals({'Chest': double.nan, 'Core': -3}).values,
        everyElement(0),
      );
    },
  );

  test(
    'six-category snapshots serialize without reallocating old PPL totals',
    () {
      final snapshot = RadarSnapshot(
        weekStart: DateTime(2026, 10, 26),
        backVolume: 1,
        legsVolume: 2,
        chestVolume: 3,
        armsVolume: 4,
        coreVolume: 5,
        shouldersVolume: 6,
      );
      expect(RadarSnapshot.fromJson(snapshot.toJson()).muscleVolumes.values, [
        1,
        2,
        3,
        4,
        5,
        6,
      ]);
      final legacy = RadarSnapshot.fromJson({
        'week_start': '2026-10-26',
        'push_volume': 100,
        'pull_volume': 200,
      });
      expect(legacy.muscleVolumes.values, everyElement(0));
    },
  );

  testWidgets(
    'fixed axes use an absolute scale and replay only when data changes',
    (tester) async {
      const data = [
        MuscleCoverage(name: 'Lats', planned: 4, completed: 4),
        MuscleCoverage(name: 'Mid back', planned: 2, completed: 0),
        MuscleCoverage(name: 'Biceps', planned: 2, completed: 1),
        MuscleCoverage(name: 'Triceps', planned: 3, completed: 2),
        MuscleCoverage(name: 'Quads', planned: 3, completed: 2),
        MuscleCoverage(name: 'Hamstrings', planned: 2, completed: 0),
      ];
      Widget host(List<MuscleCoverage> muscles) => MaterialApp(
        home: Scaffold(body: TrainingCoverageRadar(muscles: muscles)),
      );
      await tester.pumpWidget(host(data));
      final initial = painter(tester);
      expect(initial.series.last.values, [4 / 20, 2 / 20, 0, 3 / 20, 0, 0]);
      expect(
        initial.pointsFor(initial.series.last),
        everyElement(initial.center),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final intermediate = initial.pointsFor(initial.series.last);
      await tester.pumpAndSettle();
      final finalPoints = initial.pointsFor(initial.series.last);
      for (var i = 0; i < finalPoints.length; i++) {
        expect(
          (intermediate[i] - initial.center).distance,
          lessThanOrEqualTo((finalPoints[i] - initial.center).distance),
        );
        expect(
          (finalPoints[i] - initial.center).distance,
          closeTo(
            initial.radius * math.sqrt(initial.series.last.values[i]),
            .001,
          ),
        );
      }
      await tester.pumpWidget(host(List.of(data)));
      expect(painter(tester).reveal.value, 1);
      await tester.pumpWidget(
        host([
          ...data,
          const MuscleCoverage(name: 'Core', planned: 3, completed: 2),
        ]),
      );
      expect(painter(tester).reveal.value, 0);
      await tester.pumpAndSettle();
      for (final category in muscleRadarCategories) {
        expect(find.text(category), findsOneWidget);
      }
    },
  );

  testWidgets('a single muscle has filled area proportional to its workload', (
    tester,
  ) async {
    final data = SpiderChartSeries(values: [.25, .5, 0, 0, 0, 0]);
    final web = MuscleSpiderPainter(
      reveal: const AlwaysStoppedAnimation(1),
      center: const Offset(100, 100),
      radius: 90,
      series: [data],
    );
    final segment = web.sectorPath(data, 0).computeMetrics().first;
    expect(
      web
          .sectorPath(data, 0)
          .contains(web.center + MuscleSpiderPainter.directions[0] * 20),
      true,
      reason: 'One trained muscle must form a filled sector, not a line',
    );
    expect(web.sectorArea(data, 1), closeTo(2 * web.sectorArea(data, 0), .001));
    expect(web.sectorArea(data, 2), 0);
    expect(web.sectorPath(data, 2).computeMetrics(), isEmpty);
    expect(segment.isClosed, true);
  });

  testWidgets('renders center, growing, and final web previews', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final outfit = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'));
    final mono = FontLoader('JetBrainsMono')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));
    await tester.runAsync(() async {
      await outfit.load();
      await mono.load();
    });
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFF0F131B),
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  Text('WORKOUT MUSCLE COVERAGE'),
                  TrainingCoverageRadar(
                    muscles: [
                      MuscleCoverage(name: 'Back', planned: 10, completed: 8),
                      MuscleCoverage(name: 'Legs', planned: 10, completed: 5),
                      MuscleCoverage(name: 'Chest', planned: 10, completed: 7),
                      MuscleCoverage(name: 'Arms', planned: 10, completed: 9),
                      MuscleCoverage(name: 'Core', planned: 10, completed: 4),
                      MuscleCoverage(
                        name: 'Shoulders',
                        planned: 10,
                        completed: 6,
                      ),
                    ],
                  ),
                  Text('WEEKLY MUSCLE BALANCE'),
                  MuscleRadarChart(
                    size: 320,
                    plannedVolume: {
                      'Back': 18,
                      'Quads': 10,
                      'Hamstrings': 8,
                      'Chest': 16,
                      'Biceps': 6,
                      'Triceps': 6,
                      'Core': 8,
                      'Shoulders': 12,
                    },
                    loggedVolume: {
                      'Back': 14,
                      'Quads': 8,
                      'Hamstrings': 5,
                      'Chest': 12,
                      'Biceps': 5,
                      'Triceps': 4,
                      'Core': 4,
                      'Shoulders': 10,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> capture(String name) => tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/verification').create(recursive: true);
      await File(
        'build/verification/spider_graph_$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await capture('start');
    await tester.pump(const Duration(milliseconds: 250));
    await capture('growing');
    await tester.pumpAndSettle();
    await capture('final');
    expect(tester.takeException(), isNull);
  });
}
