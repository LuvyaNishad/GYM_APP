import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/core/utils/strength_math.dart';
import 'package:leon/features/dashboard/widgets/recovery_status_widget.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/history/widgets/muscle_radar_tab_view.dart';
import 'package:leon/features/history/widgets/overload_tab_view.dart';
import 'package:leon/features/history/widgets/workout_history_card.dart';
import 'package:leon/features/history/models/exercise_progress_model.dart';
import 'package:leon/models/workout_model.dart';

class _TestHistoryWorkoutsNotifier extends HistoryWorkoutsNotifier {
  _TestHistoryWorkoutsNotifier(this.initial);
  final List<WorkoutModel> initial;

  @override
  List<WorkoutModel> build() => initial;
}

final _testWorkoutFixture = WorkoutModel(
  id: 'fixture_w1',
  userId: 'u1',
  name: 'PUSH DAY FOCUS',
  date: DateTime(2026, 10, 20),
  durationSeconds: 3600,
  totalVolumeKg: 8500,
  exercises: const [
    WorkoutExercise(
      exerciseId: 'ex_bench_press',
      exerciseName: 'Barbell Bench Press',
      muscleGroup: 'Chest',
      sets: [
        WorkoutSet(reps: 8, weightKg: 80.0),
        WorkoutSet(reps: 6, weightKg: 90.0, isPr: true),
      ],
    ),
  ],
);

void main() {
  group('Epic 4: StrengthMath Scientific Formula Tests', () {
    test('calculateEpley1RM computes exact weight for 1 rep and correct math for multi-rep', () {
      expect(StrengthMath.calculateEpley1RM(100.0, 1), 100.0);
      // 100 * (1 + 10 / 30) = 100 * 1.3333333333 = 133.3333...
      expect(StrengthMath.calculateEpley1RM(100.0, 10), closeTo(133.33, 0.01));
      // 80 * (1 + 5 / 30) = 80 * (1.166666667) = 93.3333...
      expect(StrengthMath.calculateEpley1RM(80.0, 5), closeTo(93.33, 0.01));
      // Zero or negative handling
      expect(StrengthMath.calculateEpley1RM(0.0, 5), 0.0);
      expect(StrengthMath.calculateEpley1RM(100.0, 0), 0.0);
    });

    test('calculateBrzycki1RM computes expected values and guards rep limits', () {
      expect(StrengthMath.calculateBrzycki1RM(100.0, 1), 100.0);
      // 100 * (36 / (37 - 5)) = 100 * (36 / 32) = 112.5
      expect(StrengthMath.calculateBrzycki1RM(100.0, 5), 112.5);
      // 37 reps or more prevents division by zero
      expect(StrengthMath.calculateBrzycki1RM(100.0, 40), 200.0);
    });

    test('calculateLombardi1RM computes expected power values', () {
      expect(StrengthMath.calculateLombardi1RM(100.0, 1), 100.0);
      // 100 * (10 ^ 0.1) = ~125.89
      expect(StrengthMath.calculateLombardi1RM(100.0, 10), closeTo(125.89, 0.1));
    });

    test('repMaxTable generates 7 standard training percentage intervals', () {
      final table = StrengthMath.repMaxTable(100.0);
      expect(table.length, 7);
      expect(table.first['percent'], 100);
      expect(table.first['weightKg'], 100.0);
      expect(table.first['reps'], 1);

      final hypertrophy = table.firstWhere((e) => e['percent'] == 80);
      expect(hypertrophy['reps'], 8);
      expect(hypertrophy['weightKg'], 80.0);
    });
  });

  group('Epic 4: HistoryWorkoutsNotifier Tests', () {
    test('updateWorkout modifies workout in state and preserves order', () async {
      final container = ProviderContainer(
        overrides: [
          historyWorkoutsProvider.overrideWith(() => _TestHistoryWorkoutsNotifier([_testWorkoutFixture])),
        ],
      );
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      expect(workouts, isNotEmpty);

      final original = workouts.first;
      final updated = original.copyWith(name: 'UPDATED BENCH FOCUS');

      await container.read(historyWorkoutsProvider.notifier).updateWorkout(updated);

      final newWorkouts = container.read(historyWorkoutsProvider);
      expect(newWorkouts.first.name, 'UPDATED BENCH FOCUS');
      expect(newWorkouts.first.id, original.id);
    });

    test('deleteWorkout removes workout from state', () async {
      final container = ProviderContainer(
        overrides: [
          historyWorkoutsProvider.overrideWith(() => _TestHistoryWorkoutsNotifier([_testWorkoutFixture])),
        ],
      );
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      final initialCount = workouts.length;
      final targetId = workouts.first.id;

      await container.read(historyWorkoutsProvider.notifier).deleteWorkout(targetId);

      final afterDelete = container.read(historyWorkoutsProvider);
      expect(afterDelete.length, initialCount - 1);
      expect(afterDelete.any((w) => w.id == targetId), isFalse);
    });
  });

  group('Epic 4: Widget Interactive Tests', () {
    testWidgets('OverloadTabView shows empty state when no workouts recorded', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OverloadTabView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NO OVERLOAD DATA YET'), findsOneWidget);
    });

    testWidgets('OverloadTabView displays time range filter chips and opens Epley formula dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testExerciseProgress = [
        ExerciseProgressModel(
          exerciseId: 'ex_bench_press',
          exerciseName: 'Barbell Bench Press',
          muscleGroup: 'Chest',
          allTimeBest1RM: 110.0,
          recentDeltaPercent: 5.0,
          dataPoints: [
            StrengthDataPoint(
              date: DateTime.now().subtract(const Duration(days: 14)),
              weightKg: 90.0,
              reps: 6,
              estimated1RM: 108.0,
              volumeKg: 2700.0,
            ),
            StrengthDataPoint(
              date: DateTime.now().subtract(const Duration(days: 2)),
              weightKg: 95.0,
              reps: 5,
              estimated1RM: 110.8,
              volumeKg: 2850.0,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableOverloadExercisesProvider.overrideWithValue(testExerciseProgress),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OverloadTabView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check range chips exist
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);

      // Tap '1M' chip
      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      // Tap Epley footnote to open dialog
      final footnoteFinder = find.textContaining('Estimated 1RM calculated via Epley formula');
      expect(footnoteFinder, findsOneWidget);
      await tester.tap(footnoteFinder);
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('SCIENTIFIC 1RM FORMULA'), findsOneWidget);
      expect(find.text('EPLEY EQUATION'), findsOneWidget);
      expect(find.text('1RM = Weight × (1 + Reps / 30)'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.text('SCIENTIFIC 1RM FORMULA'), findsNothing);
    });

    testWidgets('WorkoutHistoryCard expands and exposes EDIT WORKOUT button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testWorkout = WorkoutModel(
        id: 'test_w1',
        userId: 'u1',
        name: 'UPPER BODY STRENGTH',
        date: DateTime.now(),
        durationSeconds: 3200,
        totalVolumeKg: 8500,
        exercises: const [
          WorkoutExercise(
            exerciseId: 'ex_bench',
            exerciseName: 'Barbell Bench Press',
            muscleGroup: 'Chest',
            sets: [
              WorkoutSet(reps: 8, weightKg: 80.0),
              WorkoutSet(reps: 8, weightKg: 82.5),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutHistoryCard(
                workout: testWorkout,
                initiallyExpanded: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, action buttons are hidden
      expect(find.text('EDIT'), findsNothing);
      expect(find.text('REPEAT WORKOUT'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('UPPER BODY STRENGTH'));
      await tester.pumpAndSettle();

      // In expanded state, REPEAT WORKOUT and EDIT are visible
      expect(find.text('REPEAT WORKOUT'), findsOneWidget);
      expect(find.text('EDIT'), findsOneWidget);

      // Tap EDIT to open sheet
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();

      expect(find.text('EDIT WORKOUT LOG'), findsOneWidget);
      expect(find.text('SAVE CHANGES'), findsOneWidget);
    });

    testWidgets('MuscleRadarTabView info icon opens MUSCLE BALANCE SCIENCE dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MuscleRadarTabView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the info icon next to MUSCLE SYMMETRY RADAR
      final infoIconFinder = find.byIcon(Icons.info_outline_rounded).first;
      await tester.tap(infoIconFinder);
      await tester.pumpAndSettle();

      expect(find.text('MUSCLE BALANCE SCIENCE'), findsOneWidget);
      expect(find.textContaining('total direct sets completed across Push, Pull, and Leg'), findsOneWidget);

      await tester.tap(find.text('UNDERSTOOD'));
      await tester.pumpAndSettle();
      expect(find.text('MUSCLE BALANCE SCIENCE'), findsNothing);
    });

    testWidgets('RecoveryStatusWidget info icon opens RECOVERY READINESS dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecoveryStatusWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap info icon
      final infoIconFinder = find.byIcon(Icons.info_outline_rounded);
      expect(infoIconFinder, findsOneWidget);
      await tester.tap(infoIconFinder);
      await tester.pumpAndSettle();

      expect(find.text('RECOVERY READINESS'), findsWidgets);
      expect(find.textContaining('Self-reported readiness estimate based on workout frequency'), findsOneWidget);

      await tester.tap(find.text('UNDERSTOOD'));
      await tester.pumpAndSettle();
    });
  });
}
