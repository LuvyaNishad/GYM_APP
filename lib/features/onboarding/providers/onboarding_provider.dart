import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../services/hive_service.dart';
import '../models/onboarding_state.dart';

export '../models/onboarding_state.dart';

/// Whether the user has already finished onboarding, read straight from
/// storage.
final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(hiveServiceProvider).getSetting<bool>(
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
      email: 'agent@leon.tactical',
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

    ref.invalidate(onboardingCompleteProvider);
    state = state.copyWith(isCompleted: true);
  }

  /// Reset the onboarding flow (for re-onboarding / testing).
  Future<void> reset() async {
    await ref
        .read(hiveServiceProvider)
        .deleteSetting(AppConstants.settingOnboardingComplete);
    ref.invalidate(onboardingCompleteProvider);
    state = const OnboardingState();
  }
}

/// Global provider for [OnboardingNotifier].
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
