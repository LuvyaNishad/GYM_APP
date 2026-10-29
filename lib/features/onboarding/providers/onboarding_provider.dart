import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../services/hive_service.dart';
import '../../workout_builder/data/split_presets.dart';
import '../../workout_builder/models/training_schedule.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../models/onboarding_state.dart';
import '../models/training_goal_config.dart';

export '../models/onboarding_state.dart';
export '../models/training_goal_config.dart';

/// Whether the user has already finished onboarding, read straight from
/// storage.
final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref
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
    return OnboardingState(isCompleted: ref.watch(onboardingCompleteProvider));
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

  void setAge(int age) {
    state = state.copyWith(age: age);
  }

  void setHeight(double height, {bool? isCm}) {
    state = state.copyWith(
      height: height,
      isHeightCm: isCm ?? state.isHeightCm,
    );
  }

  void setHeightUnit(bool isCm) {
    state = state.copyWith(isHeightCm: isCm);
  }

  void setWeight(double weight, {bool? isKg}) {
    state = state.copyWith(
      weight: weight,
      isWeightKg: isKg ?? state.isWeightKg,
    );
  }

  void setWeightUnit(bool isKg) {
    state = state.copyWith(isWeightKg: isKg);
  }

  void setTargetWeight(double weight) {
    state = state.copyWith(targetWeight: weight);
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
    state = state.copyWith(preferredSplit: split);
  }

  void toggleEquipment(String item) {
    final list = List<String>.from(state.equipment);
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
    final hive = ref.read(hiveServiceProvider);

    final displayName = state.agentName.trim().isNotEmpty
        ? state.agentName.trim()
        : 'Leon';

    final user = UserModel(
      id: AppConstants.hiveKeyLocalProfile,
      email: 'athlete@leon.fit',
      displayName: displayName,
      currentWeight: state.weight,
      targetWeight: state.targetWeight,
      preferredSplit: state.preferredSplit,
      weightUnit: state.isWeightKg ? 'kg' : 'lbs',
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    await hive.put(
      AppConstants.hiveBoxUser,
      AppConstants.hiveKeyLocalProfile,
      user.toJson(),
    );

    await hive.putSetting(AppConstants.settingOnboardingComplete, true);
    await hive.putSetting(
      AppConstants.settingWeightUnit,
      state.isWeightKg ? 'kg' : 'lbs',
    );
    await hive.putSetting(
      AppConstants.settingActiveSplitId,
      state.preferredSplit,
    );
    final split = kPresetSplits.firstWhere(
      (split) => split.id == state.preferredSplit,
      orElse: () => kPresetSplits.first,
    );
    await hive.putSetting(
      AppConstants.settingTrainingSchedules,
      TrainingSchedule.encode([
        TrainingSchedule.fromSplit(split, DateTime.now()),
      ]),
    );
    await hive.putSetting(AppConstants.settingPrimaryGoal, state.primaryGoal);
    await hive.putSetting(AppConstants.settingTargetWeight, state.targetWeight);

    ref.invalidate(onboardingCompleteProvider);
    ref.invalidate(trainingGoalProvider);
    ref.invalidate(splitsProvider);
    state = state.copyWith(isCompleted: true);
  }

  /// Update the active primary goal and persist immediately (e.g. from Profile screen).
  Future<void> updatePrimaryGoal(String goal) async {
    state = state.copyWith(primaryGoal: goal);
    await ref
        .read(hiveServiceProvider)
        .putSetting(AppConstants.settingPrimaryGoal, goal);
    ref.invalidate(trainingGoalProvider);
  }

  /// Reset the onboarding flow (for re-onboarding / testing).
  Future<void> reset() async {
    await ref
        .read(hiveServiceProvider)
        .deleteSetting(AppConstants.settingOnboardingComplete);
    await ref
        .read(hiveServiceProvider)
        .deleteSetting(AppConstants.settingPrimaryGoal);
    ref.invalidate(onboardingCompleteProvider);
    ref.invalidate(trainingGoalProvider);
    state = const OnboardingState();
  }
}

/// Global provider for [OnboardingNotifier].
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

/// Global provider returning the user's active training goal string (e.g. 'BUILD MUSCLE', 'STRENGTH').
final trainingGoalProvider = Provider<String>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  final savedGoal = hive.getSetting<String>(AppConstants.settingPrimaryGoal);
  if (savedGoal != null && savedGoal.isNotEmpty) {
    return savedGoal;
  }
  return ref.watch(onboardingProvider.select((s) => s.primaryGoal));
});

/// Global provider exposing the active [TrainingGoalConfig] based on the user's primary goal.
final trainingGoalConfigProvider = Provider<TrainingGoalConfig>((ref) {
  final goal = ref.watch(trainingGoalProvider);
  return TrainingGoalConfig.fromGoal(goal);
});
