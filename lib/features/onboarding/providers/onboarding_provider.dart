import 'dart:async';
import 'dart:convert';
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

/// Local entry state is excluded from cloud and backup preferences.
final accountChoicePendingProvider = Provider<bool>(
  (ref) =>
      ref
          .watch(hiveServiceProvider)
          .getSetting<bool>(
            AppConstants.settingAccountChoicePending,
            fallback: false,
          ) ??
      false,
);

/// Saves the questionnaire independently of the finished training profile.
class OnboardingNotifier extends Notifier<OnboardingState> {
  Future<void> _pendingDraft = Future.value();
  int _progressRevision = 0;

  Future<void> _persist(OnboardingState draft) {
    final hive = ref.read(hiveServiceProvider);
    final json = jsonEncode(draft.toJson());
    _pendingDraft = _pendingDraft
        .catchError((Object _) {})
        .then(
          (_) => hive.putSettingChecked(AppConstants.settingSetupDraft, json),
        );
    // Writes stay ordered without restoring a stale UI snapshot on completion.
    unawaited(_pendingDraft.catchError((Object _) {}));
    return _pendingDraft;
  }

  void _update(OnboardingState next) {
    if (next.currentPage != state.currentPage) _progressRevision++;
    state = next;
    if (!next.isCompleted) _persist(next);
  }

  Future<void> saveProgress(int page) async {
    if (page < 0 || page >= OnboardingState.totalPages) return;
    final previousPage = state.currentPage;
    final revision = ++_progressRevision;
    final next = state.copyWith(currentPage: page);
    // Show the question immediately, even while disk/cloud reconciliation is busy.
    state = next;
    try {
      await _persist(next);
    } catch (_) {
      if (ref.mounted && revision == _progressRevision) {
        // Keep newer answers and allow retry from the previous step.
        state = state.copyWith(currentPage: previousPage);
      }
      rethrow;
    }
  }

  @override
  OnboardingState build() {
    ref.keepAlive();
    if (!ref.read(onboardingCompleteProvider)) {
      final raw = ref
          .read(hiveServiceProvider)
          .getSetting<String>(AppConstants.settingSetupDraft);
      if (raw != null) {
        try {
          return OnboardingState.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        } catch (_) {
          /* Recover a malformed draft from the saved profile. */
        }
      }
    }
    return _fromSavedProfile();
  }

  OnboardingState _fromSavedProfile() {
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
      _update(state.copyWith(currentPage: page));
    }
  }

  void nextPage() {
    if (!state.isLastPage) {
      _update(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      _update(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void setAgentName(String name) {
    _update(state.copyWith(agentName: name));
  }

  void setAge(int? age) {
    _update(state.copyWith(age: age, ageProvided: age != null));
  }

  void clearBiometric(String field) {
    _update(
      state.copyWith(
        heightProvided: field == 'height' ? false : null,
        weightProvided: field == 'weight' ? false : null,
        targetProvided: field == 'target' ? false : null,
      ),
    );
  }

  void setHeight(double height, {bool? isCm}) {
    _update(
      state.copyWith(
        height: height,
        heightProvided: true,
        isHeightCm: isCm ?? state.isHeightCm,
      ),
    );
  }

  void setHeightUnit(bool isCm) {
    _update(state.copyWith(isHeightCm: isCm));
  }

  void setWeight(double weight, {bool? isKg}) {
    _update(
      state.copyWith(
        weight: weight,
        weightProvided: true,
        isWeightKg: isKg ?? state.isWeightKg,
      ),
    );
  }

  void setWeightUnit(bool isKg) {
    _update(state.copyWith(isWeightKg: isKg));
  }

  void setTargetWeight(double weight) {
    _update(state.copyWith(targetWeight: weight, targetProvided: true));
  }

  void setExperienceLevel(String level) {
    _update(state.copyWith(experienceLevel: level));
  }

  void setPrimaryGoal(String goal) {
    _update(state.copyWith(primaryGoal: goal));
  }

  void setTrainingDays(int days) {
    _update(state.copyWith(trainingDaysPerWeek: days));
  }

  void setPreferredSplit(String split) {
    _update(state.copyWith(preferredSplit: resolveSplitId(split)));
  }

  void toggleEquipment(String item) {
    final list = List<String>.from(state.equipment);
    if (item == 'Bodyweight Only') {
      _update(state.copyWith(equipment: const ['Bodyweight Only']));
      return;
    }
    list.remove('Bodyweight Only');
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    _update(state.copyWith(equipment: list));
  }

  void toggleInjury(String item) {
    if (item == 'NONE') {
      _update(state.copyWith(injuries: const []));
      return;
    }
    final list = List<String>.from(state.injuries);
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    _update(state.copyWith(injuries: list));
  }

  /// Mark onboarding as completed and persist user profile.
  Future<void> complete() async {
    await _pendingDraft.catchError((Object _) {});
    if (!ref.read(onboardingCompleteProvider)) {
      // Persist first so restart after profile saving still opens account choice.
      await ref
          .read(hiveServiceProvider)
          .putSettingChecked(AppConstants.settingAccountChoicePending, true);
      ref.invalidate(accountChoicePendingProvider);
    }
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
    _update(state.copyWith(isCompleted: true));
  }

  Future<void> updatePrimaryGoal(String goal) async {
    await ref.read(accountProfileProvider.notifier).updatePrimaryGoal(goal);
    _update(state.copyWith(primaryGoal: goal));
  }

  /// Replay only resets the draft; saved data and completion remain intact.
  Future<void> reset() async {
    _progressRevision++;
    await _pendingDraft.catchError((Object _) {});
    await ref
        .read(hiveServiceProvider)
        .deleteSettingChecked(AppConstants.settingSetupDraft);
    // Replay has its own editable state; the saved completion flag stays true.
    // Returning users enter the questions directly, without the first-use gate.
    state = _fromSavedProfile().copyWith(currentPage: 1, isCompleted: false);
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
