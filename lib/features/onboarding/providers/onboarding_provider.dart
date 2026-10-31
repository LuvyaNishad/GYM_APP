import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../state/app_providers.dart';
import '../../../services/hive_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../workout_builder/models/programme_configuration.dart';
import '../models/onboarding_state.dart';
import '../models/training_goal_config.dart';

export '../models/onboarding_state.dart';
export '../models/training_goal_config.dart';

/// Whether the user has already finished onboarding, read straight from
/// storage.
final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider)?.onboardingComplete ??
      ref
          .watch(hiveServiceProvider)
          .getSetting<bool>(
            AppConstants.settingOnboardingComplete,
            fallback: false,
          ) ??
      false;
});

/// Manages the step-by-step progression through the 16-screen onboarding flow.
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    ref.keepAlive();
    final user = ref.read(userProfileProvider);
    return OnboardingState(
      isCompleted: ref.read(onboardingCompleteProvider),
      agentName: user?.displayName ?? '',
      age: user?.age ?? 24,
      ageProvided: user?.age != null,
      height: user?.heightCm ?? 178,
      heightProvided: user?.heightCm != null,
      isHeightCm: user?.heightUnit != 'ft',
      weight: user?.currentWeight ?? 78,
      weightProvided: user?.currentWeight != null,
      isWeightKg: user?.weightUnit != 'lbs',
      targetWeight: user?.targetWeight ?? 74,
      targetProvided: user?.targetWeight != null,
      preferredSplit: resolveSplitId(user?.preferredSplit ?? 'PPL'),
      experienceLevel: user?.experienceLevel ?? 'Not set',
      primaryGoal: user?.primaryGoal ?? 'BUILD MUSCLE',
      trainingDaysPerWeek: user?.trainingDaysPerWeek ?? 5,
      equipment: user?.trainingDaysPerWeek == null
          ? const ['Dumbbells', 'Barbell', 'Bench', 'Pull-up Bar']
          : user!.equipment,
      injuries: user?.injuries ?? const [],
    );
  }

  void setPage(int page) {
    if (page >= 0 && page < OnboardingState.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  void nextPage() {
    if (!state.isLastPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void setAgentName(String name) {
    state = state.copyWith(agentName: name);
  }

  void setAge(int? age) {
    state = state.copyWith(age: age, ageProvided: age != null);
  }

  void clearBiometric(String field) {
    state = state.copyWith(
      heightProvided: field == 'height' ? false : null,
      weightProvided: field == 'weight' ? false : null,
      targetProvided: field == 'target' ? false : null,
    );
  }

  void setHeight(double height, {bool? isCm}) {
    state = state.copyWith(
      height: height,
      heightProvided: true,
      isHeightCm: isCm ?? state.isHeightCm,
    );
  }

  void setHeightUnit(bool isCm) {
    state = state.copyWith(isHeightCm: isCm);
  }

  void setWeight(double weight, {bool? isKg}) {
    state = state.copyWith(
      weight: weight,
      weightProvided: true,
      isWeightKg: isKg ?? state.isWeightKg,
    );
  }

  void setWeightUnit(bool isKg) {
    state = state.copyWith(isWeightKg: isKg);
  }

  void setTargetWeight(double weight) {
    state = state.copyWith(targetWeight: weight, targetProvided: true);
  }

  void setExperienceLevel(String level) {
    state = state.copyWith(experienceLevel: level);
  }

  void setPrimaryGoal(String goal) {
    state = state.copyWith(primaryGoal: goal);
  }

  void setTrainingDays(int days) {
    state = state.copyWith(trainingDaysPerWeek: days);
  }

  void setPreferredSplit(String split) {
    state = state.copyWith(preferredSplit: resolveSplitId(split));
  }

  void toggleEquipment(String item) {
    final list = List<String>.from(state.equipment);
    if (item == 'Bodyweight Only') {
      state = state.copyWith(equipment: const ['Bodyweight Only']);
      return;
    }
    list.remove('Bodyweight Only');
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    state = state.copyWith(equipment: list);
  }

  void toggleInjury(String item) {
    if (item == 'NONE') {
      state = state.copyWith(injuries: const []);
      return;
    }
    final list = List<String>.from(state.injuries);
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    state = state.copyWith(injuries: list);
  }

  /// Mark onboarding as completed and persist user profile.
  Future<void> complete() async {
    await ref
        .read(accountProfileProvider.notifier)
        .applySetup(
          displayName: state.agentName.trim(),
          splitId: state.preferredSplit,
          experience: state.experienceLevel,
          days: state.trainingDaysPerWeek,
          equipment: state.equipment,
          injuries: state.injuries,
          primaryGoal: state.primaryGoal,
          age: state.ageProvided ? state.age : null,
          heightCm: state.heightProvided ? state.height : null,
          weightKg: state.weightProvided ? state.weight : null,
          targetKg: state.targetProvided ? state.targetWeight : null,
          weightUnit: state.isWeightKg ? 'kg' : 'lbs',
          heightUnit: state.isHeightCm ? 'cm' : 'ft',
        );
    state = state.copyWith(isCompleted: true);
  }

  Future<void> updatePrimaryGoal(String goal) async {
    await ref.read(accountProfileProvider.notifier).updatePrimaryGoal(goal);
    state = state.copyWith(primaryGoal: goal);
  }

  /// Replay only resets the draft; saved data and completion remain intact.
  Future<void> reset() async {
    ref.invalidateSelf();
  }
}

/// Global provider for [OnboardingNotifier].
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

/// Global provider returning the user's active training goal string (e.g. 'BUILD MUSCLE', 'STRENGTH').
final trainingGoalProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider)?.primaryGoal ??
      ref.watch(onboardingProvider.select((s) => s.primaryGoal));
});

/// Global provider exposing the active [TrainingGoalConfig] based on the user's primary goal.
final trainingGoalConfigProvider = Provider<TrainingGoalConfig>((ref) {
  final goal = ref.watch(trainingGoalProvider);
  return TrainingGoalConfig.fromGoal(goal);
});
