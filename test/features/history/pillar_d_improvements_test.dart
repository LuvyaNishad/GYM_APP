import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/history/widgets/workout_history_card.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/models/workout_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testWorkout = WorkoutModel(
    id: 'test-workout-1',
    userId: 'user-1',
    name: 'Pull Day Hypertrophy',
    date: DateTime(2026, 10, 16),
    durationSeconds: 2880, // 48 mins
    totalVolumeKg: 12450.0,
    exercises: [
      const WorkoutExercise(
        exerciseId: 'deadlift',
        exerciseName: 'Barbell Deadlift',
        muscleGroup: 'Back',
        sets: [
          WorkoutSet(reps: 10, weightKg: 60.0, isWarmup: true),
          WorkoutSet(reps: 5, weightKg: 120.0, isPr: true),
          WorkoutSet(reps: 5, weightKg: 120.0),
        ],
      ),
      const WorkoutExercise(
        exerciseId: 'lat-pulldown',
        exerciseName: 'Lat Pulldown',
        muscleGroup: 'Back',
        sets: [
          WorkoutSet(reps: 10, weightKg: 70.0),
        ],
      ),
    ],
  );

  group('Pillar D Improvements - Workout History Actions Tests', () {
    testWidgets('WorkoutHistoryCard displays REPEAT WORKOUT and SHARE buttons when expanded', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WorkoutHistoryCard(
                  workout: testWorkout,
                  initiallyExpanded: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify buttons exist
      expect(find.text('REPEAT WORKOUT'), findsOneWidget);
      expect(find.text('SHARE'), findsOneWidget);
      expect(find.text('EDIT'), findsOneWidget);
    });

    testWidgets('REPEAT WORKOUT starts active session with historical exercises and sets', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WorkoutHistoryCard(
                  workout: testWorkout,
                  initiallyExpanded: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap REPEAT WORKOUT
      final repeatBtn = find.text('REPEAT WORKOUT');
      await tester.tap(repeatBtn);
      await tester.pumpAndSettle();

      // Active session should now be running with testWorkout's exercises
      final session = container.read(activeSessionProvider);
      expect(session.isActive, isTrue);
      expect(session.splitName, equals('Pull Day Hypertrophy'));
      expect(session.exercises.length, equals(2));

      // Check first exercise mapped accurately
      final firstEx = session.exercises.first;
      expect(firstEx.name, equals('Barbell Deadlift'));
      expect(firstEx.sets.length, equals(3));
      expect(firstEx.sets[0].isWarmup, isTrue);
      expect(firstEx.sets[0].setType, equals(ActiveSetType.warmup));
      expect(firstEx.sets[0].weightKg, equals(60.0));
      expect(firstEx.sets[1].weightKg, equals(120.0));
      expect(firstEx.sets[1].previousWeightKg, equals(120.0));
      expect(firstEx.sets[1].isCompleted, isFalse); // Ready to be performed today

      // Clean up session ticker before test finishes
      container.read(activeSessionProvider.notifier).cancelSession();
    });

    testWidgets('SHARE copies formatted summary to clipboard and shows SnackBar', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      String? clipboardData;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardData = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WorkoutHistoryCard(
                  workout: testWorkout,
                  initiallyExpanded: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap SHARE
      final shareBtn = find.text('SHARE');
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar shown
      expect(find.text('Workout summary copied to clipboard!'), findsOneWidget);

      // Verify clipboard contents
      expect(clipboardData, isNotNull);
      expect(clipboardData, contains('LEON WORKOUT SUMMARY'));
      expect(clipboardData, contains('PULL DAY HYPERTROPHY'));
      expect(clipboardData, contains('Barbell Deadlift'));
      expect(clipboardData, contains('120.0kg × 5'));
      expect(clipboardData, contains('[Warmup]'));
      expect(clipboardData, contains('Tracked with LEON'));
    });
  });
}
