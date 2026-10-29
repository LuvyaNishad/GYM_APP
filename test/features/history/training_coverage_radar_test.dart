import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/core/widgets/muscle_spider_chart.dart';
import 'package:leon/models/muscle_radar_data.dart';
import 'package:leon/features/history/models/training_coverage.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/history/providers/training_coverage_provider.dart';
import 'package:leon/features/history/widgets/muscle_radar_tab_view.dart';
import 'package:leon/features/history/widgets/muscle_workload_chart.dart';
import 'package:leon/features/dashboard/providers/home_workout_view_provider.dart';
import 'package:leon/features/dashboard/widgets/training_recommendation_card.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/shared/widgets/training_coverage_radar.dart';
import 'training_coverage_test.dart' as fixtures;

const muscles = [
  MuscleCoverage(name: 'Biceps', planned: 5.1, completed: 2.1),
  MuscleCoverage(name: 'Lats', planned: 4.05, completed: 4.05),
  MuscleCoverage(name: 'Mid back', planned: 3, completed: 2),
];

MuscleSpiderPainter web(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('training-coverage-web')),
            )
            .painter!
        as MuscleSpiderPainter;

Widget host(Widget child, {bool reduced = false, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

class HistoryFixture extends HistoryWorkoutsNotifier {
  HistoryFixture(this.workouts);
  final List<WorkoutModel> workouts;
  @override
  List<WorkoutModel> build() => workouts;
}

void main() {
  testWidgets(
    'web unfolds once with isolated paint and stops scheduling frames',
    (tester) async {
      await tester.pumpWidget(
        host(const TrainingCoverageRadar(muscles: muscles)),
      );
      final initial = web(tester);
      expect(initial.reveal.value, 0);
      expect(
        initial.pointsFor(initial.series.last),
        everyElement(initial.center),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        identical(initial, web(tester)),
        true,
        reason: 'Ticks must not rebuild chart widgets',
      );
      expect(initial.reveal.value, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 800));
      expect(initial.reveal.value, 1);
      expect(tester.binding.hasScheduledFrame, false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'reduced motion shows final web immediately and sparse data remains honest',
    (tester) async {
      await tester.pumpWidget(
        host(TrainingCoverageRadar(muscles: [muscles.first]), reduced: true),
      );
      expect(web(tester).reveal.value, 1);
      expect(MuscleSpiderPainter.directions.length, 6);
      expect(web(tester).series.last.values.where((v) => v > 0).length, 1);
      for (final category in muscleRadarCategories) {
        expect(find.text(category), findsOneWidget);
      }
      expect(find.text('Biceps'), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, false);
      await tester.pumpWidget(
        host(const TrainingCoverageRadar(muscles: []), reduced: true),
      );
      expect(web(tester).series.last.values, everyElement(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('background pauses outward reveal; resuming finishes it', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      host(const TrainingCoverageRadar(muscles: muscles)),
    );
    await tester.pump(const Duration(milliseconds: 220));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = web(tester).reveal.value;
    await tester.pump(const Duration(seconds: 2));
    expect(web(tester).reveal.value, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(web(tester).reveal.value, 1);
  });

  testWidgets(
    'Home mounts recommendation without a chart; Radar releases chart on leaving',
    (tester) async {
      final index = TrainingCoverageIndex(fixtures.split, fixtures.catalog);
      final partial = fixtures.workout(
        exercises: [
          fixtures.logged(fixtures.row, 3),
          fixtures.logged(fixtures.pulldown, 3),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          trainingCoverageIndexProvider.overrideWithValue(index),
          historyWorkoutsProvider.overrideWith(() => HistoryFixture([partial])),
          homeWorkoutViewProvider.overrideWithValue(
            HomeWorkoutView(
              date: DateTime(2026, 10, 29),
              day: fixtures.pull,
              logged: const [],
              isToday: true,
              isPast: false,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: host(const TrainingRecommendationCard()),
        ),
      );
      expect(find.textContaining('Prioritize Biceps Curl'), findsOneWidget);
      expect(find.byType(TrainingCoverageRadar), findsNothing);
      expect(container.exists(sessionCoverageProvider(partial)), false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: host(const MuscleRadarTabView()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MuscleWorkloadChart), findsOneWidget);
      expect(container.exists(sessionCoverageProvider(partial)), true);
      expect(find.text('Rear delts'), findsNothing);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: host(const TrainingRecommendationCard()),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.exists(sessionCoverageProvider(partial)), false);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, false);
    },
  );

  testWidgets(
    'compact Radar at larger text has readable labels and renders a clean preview',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final outfit = FontLoader('Outfit')
        ..addFont(rootBundle.load('assets/fonts/Outfit-Regular.ttf'));
      final mono = FontLoader('JetBrainsMono')
        ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await tester.runAsync(() async {
        await outfit.load();
        await mono.load();
        await icons.load();
      });
      final index = TrainingCoverageIndex(fixtures.split, fixtures.catalog);
      final partial = fixtures.workout(
        exercises: [
          fixtures.logged(fixtures.row, 2),
          fixtures.logged(fixtures.pulldown, 3),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          trainingCoverageIndexProvider.overrideWithValue(index),
          historyWorkoutsProvider.overrideWith(() => HistoryFixture([partial])),
        ],
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: host(
            RepaintBoundary(
              key: key,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: MuscleRadarTabView(),
              ),
            ),
            scale: 1.5,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        if (text.style?.fontSize != null) {
          expect(text.style!.fontSize, greaterThanOrEqualTo(11));
        }
      }
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/verification').create(recursive: true);
        await File(
          'build/verification/adaptive_radar_preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
    },
  );
}
