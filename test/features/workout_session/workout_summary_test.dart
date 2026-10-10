import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/widgets/workout_summary_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutSummaryDialog Widget', () {
    testWidgets('renders duration, volume, sets, and triggers onConfirmedSave', (tester) async {
      bool saved = false;

      final session = ActiveSessionState(
        workoutId: 'test_wkt',
        splitName: 'PUSH DAY // WORKOUT A',
        startTime: DateTime.now(),
        elapsedSeconds: 2540, // 42m 20s
        isActive: true,
        exercises: [
          const ActiveExerciseState(
            exerciseId: 'ex1',
            name: 'Barbell Bench Press',
            muscleGroup: 'Chest',
            sets: [
              ActiveSetState(setNumber: 1, weightKg: 80, reps: 8, isCompleted: true),
              ActiveSetState(setNumber: 2, weightKg: 80, reps: 8, isCompleted: true),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutSummaryDialog(
              session: session,
              onConfirmedSave: () {
                saved = true;
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('WORKOUT RECAP'), findsOneWidget);
      expect(find.textContaining('PUSH DAY // WORKOUT A'), findsOneWidget);
      expect(find.textContaining('1,280 KG'), findsOneWidget);
      expect(find.textContaining('2 / 2 SETS'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('SAVE WORKOUT'));
      await tester.pump();

      expect(saved, isTrue);
    });
  });
}
