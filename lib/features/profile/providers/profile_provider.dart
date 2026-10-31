import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/local_date_provider.dart';
import '../../../models/user_model.dart';
import '../../../state/app_providers.dart';
import '../../health_tracking/providers/body_measurements_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/models/programme_configuration.dart';
import '../../workout_builder/models/training_schedule.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../models/account_profile_model.dart';

class AccountProfileNotifier extends Notifier<AccountProfile> {
  @override
  AccountProfile build() {
    final user = ref.watch(userProfileProvider);
    final today = ref.watch(localDateProvider);
    final history = ref
        .watch(historyWorkoutsProvider)
        .where((w) => !scheduleDate(w.date).isAfter(today))
        .toList();
    final measurements = ref
        .watch(bodyMeasurementsProvider)
        .where((m) => !scheduleDate(m.date).isAfter(today));
    var profile = user == null
        ? AccountProfile(memberSince: DateTime.now())
        : AccountProfile.fromUser(user);
    final latest = measurements.firstOrNull;
    if (latest != null &&
        (profile.weightUpdatedAt == null ||
            !latest.date.isBefore(profile.weightUpdatedAt!))) {
      profile = profile.copyWith(currentWeightKg: latest.weightKg);
    }
    return profile.copyWith(
      totalWorkouts: history.length,
      totalVolumeKg: history.fold<double>(
        0,
        (sum, w) => sum + (w.totalVolumeKg ?? 0),
      ),
    );
  }

  Future<void> _changes = Future.value();
  Future<void> _change(
    AccountProfile Function(AccountProfile) change, {
    bool? onboardingComplete,
  }) {
    final result = _changes.catchError((Object _) {}).then((_) async {
      final before = state;
      final updated = change(before);
      await ref.read(userProfileProvider.notifier).transform((current) {
        var user =
            (current ??
                    UserModel(
                      id: updated.id,
                      email: '',
                      displayName: '',
                      createdAt: updated.memberSince,
                    ))
                .copyWith(
                  id: current == null || updated.id != before.id
                      ? updated.id
                      : current.id,
                  email: current == null || updated.email != before.email
                      ? updated.email
                      : current.email,
                  displayName:
                      current == null ||
                          updated.displayName != before.displayName
                      ? updated.displayName
                      : current.displayName,
                  avatarUrl:
                      current == null || updated.avatarUrl != before.avatarUrl
                      ? updated.avatarUrl
                      : current.avatarUrl,
                  age: current == null || updated.age != before.age
                      ? updated.age
                      : current.age,
                  sex: current == null || updated.sex != before.sex
                      ? updated.sex
                      : current.sex,
                  heightCm:
                      current == null || updated.heightCm != before.heightCm
                      ? updated.heightCm
                      : current.heightCm,
                  currentWeight:
                      current == null ||
                          updated.currentWeightKg != before.currentWeightKg
                      ? updated.currentWeightKg
                      : current.currentWeight,
                  targetWeight:
                      current == null ||
                          updated.targetWeightKg != before.targetWeightKg
                      ? updated.targetWeightKg
                      : current.targetWeight,
                  startingWeightKg:
                      current == null ||
                          updated.startingWeightKg != before.startingWeightKg
                      ? updated.startingWeightKg
                      : current.startingWeightKg,
                  goalDirection:
                      current == null ||
                          updated.goalDirection != before.goalDirection
                      ? updated.goalDirection
                      : current.goalDirection,
                  weightUpdatedAt:
                      current == null ||
                          updated.weightUpdatedAt != before.weightUpdatedAt
                      ? updated.weightUpdatedAt
                      : current.weightUpdatedAt,
                  weightUnit:
                      current == null || updated.weightUnit != before.weightUnit
                      ? updated.weightUnit
                      : current.weightUnit,
                  heightUnit:
                      current == null || updated.heightUnit != before.heightUnit
                      ? updated.heightUnit
                      : current.heightUnit,
                  preferredSplit:
                      current == null ||
                          updated.preferredSplit != before.preferredSplit
                      ? resolveSplitId(updated.preferredSplit)
                      : current.preferredSplit,
                  experienceLevel:
                      current == null ||
                          updated.experienceLevel != before.experienceLevel
                      ? updated.experienceLevel
                      : current.experienceLevel,
                  trainingDaysPerWeek:
                      current == null ||
                          updated.trainingDaysPerWeek !=
                              before.trainingDaysPerWeek
                      ? updated.trainingDaysPerWeek
                      : current.trainingDaysPerWeek,
                  equipment:
                      current == null || updated.equipment != before.equipment
                      ? updated.equipment
                      : current.equipment,
                  injuries:
                      current == null || updated.injuries != before.injuries
                      ? updated.injuries
                      : current.injuries,
                  primaryGoal:
                      current == null ||
                          updated.primaryGoal != before.primaryGoal
                      ? updated.primaryGoal
                      : current.primaryGoal,
                  defaultRestSeconds:
                      current == null ||
                          updated.defaultRestSeconds !=
                              before.defaultRestSeconds
                      ? updated.defaultRestSeconds
                      : current.defaultRestSeconds,
                  barbellTareKg:
                      current == null ||
                          updated.barbellTareKg != before.barbellTareKg
                      ? updated.barbellTareKg
                      : current.barbellTareKg,
                  cyclesEnabled:
                      current == null ||
                          updated.cycleTrackingEnabled !=
                              before.cycleTrackingEnabled
                      ? updated.cycleTrackingEnabled
                      : current.cyclesEnabled,
                  audioCuesEnabled:
                      current == null ||
                          updated.audioCuesEnabled != before.audioCuesEnabled
                      ? updated.audioCuesEnabled
                      : current.audioCuesEnabled,
                  hapticFeedbackEnabled:
                      current == null ||
                          updated.hapticFeedbackEnabled !=
                              before.hapticFeedbackEnabled
                      ? updated.hapticFeedbackEnabled
                      : current.hapticFeedbackEnabled,
                  lastActiveAt: DateTime.now(),
                  schemaVersion: 2,
                  onboardingComplete:
                      onboardingComplete ??
                      current?.onboardingComplete ??
                      false,
                );
        if (user.preferredSplit != resolveSplitId(state.preferredSplit) ||
            user.trainingDaysPerWeek != state.trainingDaysPerWeek ||
            onboardingComplete == true) {
          final splits = ref.read(splitsProvider);
          final selected = splits.splits
              .where((s) => s.id == user.preferredSplit)
              .firstOrNull;
          if (selected == null) {
            throw ArgumentError('Choose an available training split.');
          }
          final plan = configureProgramme(selected, user);
          user = user.copyWith(
            trainingSchedules: TrainingSchedule.encode(
              startTrainingSchedule(
                splits.schedules,
                plan,
                ref.read(localDateProvider),
              ),
            ),
          );
        }
        return user;
      }, accountMirror: updated.toJson());
      if (!ref.mounted) return;
      ref.invalidateSelf();
    });
    _changes = result;
    return result;
  }

  Future<void> updateProfile({
    required String displayName,
    String? email,
    String? preferredSplit,
    String? experienceLevel,
  }) => _change(
    (current) => current.copyWith(
      displayName: displayName,
      email: email ?? current.email,
      preferredSplit: preferredSplit ?? current.preferredSplit,
      experienceLevel: experienceLevel ?? current.experienceLevel,
    ),
  );
  Future<void> updateIdentity({
    String? displayName,
    String? email,
    String? avatarUrl,
  }) => _change(
    (current) => current.copyWith(
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl ?? current.avatarUrl,
    ),
  );

  Future<void> updateBiometrics({
    int? age,
    String? sex,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    String? weightUnit,
    String? heightUnit,
    bool replace = false,
  }) => _change((current) {
    final weight = replace
        ? currentWeightKg
        : currentWeightKg ?? current.currentWeightKg;
    final target = replace
        ? targetWeightKg
        : targetWeightKg ?? current.targetWeightKg;
    final newGoal =
        target != current.targetWeightKg || current.startingWeightKg == null;
    return current.copyWith(
      age: replace ? age : age ?? current.age,
      sex: replace ? sex : sex ?? current.sex,
      heightCm: replace ? heightCm : heightCm ?? current.heightCm,
      currentWeightKg: weight,
      targetWeightKg: target,
      startingWeightKg: newGoal ? weight : current.startingWeightKg,
      goalDirection: target == null || weight == null
          ? null
          : newGoal
          ? (target < weight
                ? 'lose'
                : target > weight
                ? 'gain'
                : 'maintain')
          : current.goalDirection,
      weightUpdatedAt: currentWeightKg != null
          ? DateTime.now()
          : current.weightUpdatedAt,
      weightUnit: weightUnit,
      heightUnit: heightUnit,
    );
  });

  Future<void> applySetup({
    required String displayName,
    required String splitId,
    required String experience,
    required int days,
    required List<String> equipment,
    required List<String> injuries,
    required String primaryGoal,
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetKg,
    required String weightUnit,
    required String heightUnit,
  }) => _change(
    (current) => current.copyWith(
      displayName: displayName.isEmpty ? current.displayName : displayName,
      age: age,
      heightCm: heightCm,
      currentWeightKg: weightKg,
      targetWeightKg: targetKg,
      startingWeightKg:
          targetKg != current.targetWeightKg || current.startingWeightKg == null
          ? weightKg
          : current.startingWeightKg,
      goalDirection: weightKg == null || targetKg == null
          ? null
          : targetKg != current.targetWeightKg ||
                current.startingWeightKg == null
          ? (targetKg < weightKg
                ? 'lose'
                : targetKg > weightKg
                ? 'gain'
                : 'maintain')
          : current.goalDirection,
      weightUpdatedAt: weightKg == null
          ? current.weightUpdatedAt
          : DateTime.now(),
      preferredSplit: resolveSplitId(splitId),
      experienceLevel: experience,
      trainingDaysPerWeek: days,
      equipment: equipment,
      injuries: injuries,
      primaryGoal: primaryGoal,
      weightUnit: weightUnit,
      heightUnit: heightUnit,
    ),
    onboardingComplete: true,
  );

  Future<void> updatePreferences({
    String? preferredSplit,
    String? experienceLevel,
    int? defaultRestSeconds,
    double? barbellTareKg,
  }) => _change(
    (current) => current.copyWith(
      preferredSplit: preferredSplit,
      experienceLevel: experienceLevel,
      defaultRestSeconds: defaultRestSeconds,
      barbellTareKg: barbellTareKg,
    ),
  );
  Future<void> updatePrimaryGoal(String goal) =>
      _change((current) => current.copyWith(primaryGoal: goal));
  Future<void> toggleCycleTracking(bool value) =>
      _change((current) => current.copyWith(cycleTrackingEnabled: value));
  Future<void> toggleAudioCues(bool value) =>
      _change((current) => current.copyWith(audioCuesEnabled: value));
  Future<void> toggleHapticFeedback(bool value) =>
      _change((current) => current.copyWith(hapticFeedbackEnabled: value));
  Future<void> resetToDefaults() => _change(
    (current) => current.copyWith(
      weightUnit: 'kg',
      heightUnit: 'cm',
      defaultRestSeconds: 90,
      barbellTareKg: 20,
      audioCuesEnabled: true,
      hapticFeedbackEnabled: true,
    ),
  );
}

final accountProfileProvider =
    NotifierProvider<AccountProfileNotifier, AccountProfile>(
      AccountProfileNotifier.new,
    );
