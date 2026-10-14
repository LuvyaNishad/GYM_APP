import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_session/models/tempo_pacer_state.dart';
import 'package:leon/features/workout_session/providers/tempo_pacer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise-Aware Tempo Pacer Biomechanical Tests', () {
    test('isConcentricFirst correctly detects bottom-start vs top-start exercises', () {
      // Bottom-start movements (pull / curl / deadlift / raise)
      expect(const TempoPacerState(exerciseName: 'Barbell Deadlift').isConcentricFirst, isTrue);
      expect(const TempoPacerState(exerciseName: 'Bicep Curl').isConcentricFirst, isTrue);
      expect(const TempoPacerState(exerciseName: 'Lat Pulldown').isConcentricFirst, isTrue);
      expect(const TempoPacerState(exerciseName: 'Barbell Bent Over Row').isConcentricFirst, isTrue);
      expect(const TempoPacerState(exerciseName: 'Lateral Raise').isConcentricFirst, isTrue);

      // Top-start movements (squat / bench / press)
      expect(const TempoPacerState(exerciseName: 'Barbell Back Squat').isConcentricFirst, isFalse);
      expect(const TempoPacerState(exerciseName: 'Flat Barbell Bench Press').isConcentricFirst, isFalse);
      expect(const TempoPacerState(exerciseName: 'Overhead Shoulder Press').isConcentricFirst, isFalse);
    });

    test('startSession initializes with concentric phase for deadlift and eccentric for squat', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Squat (top-start) -> starts in Eccentric (descent)
      container.read(tempoPacerProvider.notifier).startSession(
            exerciseName: 'Barbell Back Squat',
            exerciseId: 'squat_1',
            setIndex: 0,
            targetReps: 5,
            skipCountdown: true,
          );
      expect(container.read(tempoPacerProvider).phase, equals(TempoPhase.eccentric));
      expect(container.read(tempoPacerProvider).phaseLabel, contains('ECCENTRIC'));

      // 2. Deadlift (bottom-start) -> starts in Concentric (lift/pull)
      container.read(tempoPacerProvider.notifier).startSession(
            exerciseName: 'Conventional Barbell Deadlift',
            exerciseId: 'deadlift_1',
            setIndex: 0,
            targetReps: 5,
            skipCountdown: true,
          );
      expect(container.read(tempoPacerProvider).phase, equals(TempoPhase.concentric));
      expect(container.read(tempoPacerProvider).phaseLabel, contains('CONCENTRIC'));
    });
  });
}
