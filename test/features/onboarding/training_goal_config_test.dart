import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('TrainingGoalConfig & Goal Engine Tests', () {
    test('TrainingGoalType.fromString maps all standard and alias goal strings', () {
      expect(TrainingGoalType.fromString('BUILD MUSCLE'), TrainingGoalType.buildMuscle);
      expect(TrainingGoalType.fromString('bulk'), TrainingGoalType.buildMuscle);
      expect(TrainingGoalType.fromString('STRENGTH'), TrainingGoalType.strength);
      expect(TrainingGoalType.fromString('INCREASE STRENGTH'), TrainingGoalType.strength);
      expect(TrainingGoalType.fromString('LOSE FAT'), TrainingGoalType.loseFat);
      expect(TrainingGoalType.fromString('cut'), TrainingGoalType.loseFat);
      expect(TrainingGoalType.fromString('FAT LOSS'), TrainingGoalType.loseFat);
      expect(TrainingGoalType.fromString('ATHLETIC'), TrainingGoalType.athletic);
      expect(TrainingGoalType.fromString('CONDITIONING'), TrainingGoalType.athletic);
      expect(TrainingGoalType.fromString(null), TrainingGoalType.buildMuscle);
    });

    test('TrainingGoalConfig assigns goal-specific rest durations', () {
      final strength = TrainingGoalConfig.fromGoal('STRENGTH');
      expect(strength.defaultRestSeconds, 180);
      expect(strength.targetRepRange, '3 - 6 Reps');

      final muscle = TrainingGoalConfig.fromGoal('BUILD MUSCLE');
      expect(muscle.defaultRestSeconds, 120);
      expect(muscle.targetRepRange, '8 - 12 Reps');

      final cut = TrainingGoalConfig.fromGoal('LOSE FAT');
      expect(cut.defaultRestSeconds, 60);
      expect(cut.targetRepRange, '10 - 15 Reps');

      final athletic = TrainingGoalConfig.fromGoal('ATHLETIC');
      expect(athletic.defaultRestSeconds, 90);
      expect(athletic.targetRepRange, '6 - 10 Reps');
    });

    test('trainingGoalConfigProvider reactively provides config from provider container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(trainingGoalConfigProvider);
      expect(config.type, isNotNull);
      expect(config.defaultRestSeconds, greaterThanOrEqualTo(60));
    });
  });
}
