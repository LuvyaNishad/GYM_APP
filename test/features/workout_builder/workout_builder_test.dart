import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_builder/data/split_presets.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/workout_builder/screens/workout_builder_screen.dart';
import 'package:leon/features/workout_builder/widgets/muscle_balance_card.dart';
import 'package:leon/features/workout_builder/widgets/muscle_radar_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splits & Models Unit Tests', () {
    test('Preset splits contains standard PPL, U/L, Arnold, and Bro Split', () {
      expect(kPresetSplits.length, greaterThanOrEqualTo(4));
      final ppl = kPresetSplits.firstWhere((s) => s.id == 'split_ppl');
      expect(ppl.daysPerWeek, 6);
      expect(ppl.workouts.length, 6);
      expect(ppl.totalWeeklySets, greaterThan(60));
    });

    test(
      'PlannedExercise toActiveExerciseState converts with sets and targets',
      () {
        const planned = PlannedExercise(
          exerciseId: 'ex_bench',
          exerciseName: 'Bench Press',
          muscleGroup: 'Chest',
          targetSets: 4,
          repRange: '8–12',
          targetWeightKg: 80.0,
        );

        final active = planned.toActiveExerciseState();
        expect(active.exerciseId, 'ex_bench');
        expect(active.sets.length, 4);
        expect(active.sets.first.weightKg, 80.0);
        expect(active.sets.first.reps, 8);
      },
    );

    test(
      'SplitsNotifier switches active split and auto-fixes lagging muscle',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final initial = container.read(splitsProvider);
        expect(initial.activeSplitId, 'split_ppl');
        expect(initial.loggedVolume['Hamstrings'], isNull);

        // Switch to Upper/Lower
        container
            .read(splitsProvider.notifier)
            .switchActiveSplit('split_upper_lower');
        expect(
          container.read(splitsProvider).activeSplitId,
          'split_upper_lower',
        );

        // Auto-tune Hamstrings deficit
        container
            .read(splitsProvider.notifier)
            .autoFixLaggingMuscle('Hamstrings');
        expect(
          container.read(splitsProvider).loggedVolume['Hamstrings'],
          isNull,
        );
      },
    );
  });

  group('MuscleRadarChart & MuscleBalanceCard Tests', () {
    testWidgets('renders MuscleRadarChart CustomPaint canvas with 6 axes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MuscleRadarChart(
              plannedVolume: {
                'Chest': 16,
                'Back': 18,
                'Shoulders': 16,
                'Quads': 14,
                'Hamstrings': 12,
                'Arms': 16,
              },
              loggedVolume: {
                'Chest': 16,
                'Back': 14,
                'Shoulders': 12,
                'Quads': 10,
                'Hamstrings': 4,
                'Arms': 14,
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'MuscleBalanceCard displays legend and thriving/lacking diagnostics',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MuscleBalanceCard(
                  plannedVolume: const {
                    'Chest': 16,
                    'Back': 18,
                    'Shoulders': 16,
                    'Quads': 14,
                    'Hamstrings': 12,
                    'Arms': 16,
                  },
                  loggedVolume: const {
                    'Chest': 16,
                    'Back': 14,
                    'Shoulders': 12,
                    'Quads': 10,
                    'Hamstrings': 4,
                    'Arms': 14,
                  },
                  onAutoTuneMuscle: (_) {},
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        expect(find.text('MUSCLE BALANCE'), findsOneWidget);
        expect(find.text('4 / 12 sets'), findsOneWidget);
        await tester.ensureVisible(find.text('REVIEW PLAN'));
        expect(find.text('REVIEW PLAN'), findsOneWidget);
        await tester.tap(find.text('Radar'));
        await tester.pumpAndSettle();
        expect(find.byType(MuscleRadarChart), findsOneWidget);
      },
    );
  });

  group('WorkoutBuilderScreen & Split Cards Widget Tests', () {
    testWidgets(
      'renders header, freestyle button, active split spotlight, and compact split cards',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: WorkoutBuilderScreen())),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        expect(find.text('WORKOUTS'), findsOneWidget);
        expect(find.text('YOUR PLAN'), findsOneWidget);
        expect(find.text('Push Pull Legs (PPL)'), findsWidgets);
        expect(find.text('Push Day A'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('START FREESTYLE WORKOUT'),
          400,
        );
        expect(find.text('Routine library'), findsOneWidget);
        expect(find.text('START FREESTYLE WORKOUT'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
