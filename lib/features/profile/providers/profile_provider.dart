/// Account Profile state notifier and provider for LEON.
///
/// Coordinates user biometrics, workout preferences, settings toggles,
/// and synchronisation with global user profile state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../services/hive_service.dart';
import '../../../state/app_providers.dart';
import '../models/account_profile_model.dart';

class AccountProfileNotifier extends Notifier<AccountProfile> {
  static const String _hiveProfileKey = 'account_profile_data';

  @override
  AccountProfile build() {
    ref.keepAlive();

    // 1. Try reading existing account settings from Hive
    try {
      final hive = ref.watch(hiveServiceProvider);
      final json = hive.read(
        AppConstants.hiveBoxUser,
        _hiveProfileKey,
        (map) => map,
      );
      if (json != null) {
        return AccountProfile.fromJson(json);
      }
    } catch (_) {
      // Fallback on schema or decode failure
    }

    // 2. Check global user profile provider for existing name/split/weight
    final globalUser = ref.watch(userProfileProvider);
    if (globalUser != null) {
      return AccountProfile(
        id: globalUser.id,
        displayName: globalUser.displayName.isNotEmpty
            ? globalUser.displayName
            : 'Leon',
        email: globalUser.email.isNotEmpty
            ? globalUser.email
            : 'leon@fitness.os',
        avatarUrl: globalUser.avatarUrl,
        memberSince: globalUser.createdAt ?? DateTime(2026, 10, 1),
        currentWeightKg: globalUser.currentWeight ?? 78.5,
        targetWeightKg: globalUser.targetWeight ?? 74.0,
        weightUnit: globalUser.weightUnit,
        preferredSplit: globalUser.preferredSplit ?? 'Push / Pull / Legs',
        cycleTrackingEnabled: globalUser.cyclesEnabled,
        totalWorkouts:
            globalUser.totalWorkouts > 0 ? globalUser.totalWorkouts : 24,
        totalVolumeKg:
            globalUser.totalVolumeKg > 0 ? globalUser.totalVolumeKg : 48600,
      );
    }

    // 3. Fallback default account profile
    return AccountProfile(
      memberSince: DateTime(2026, 10, 1),
    );
  }

  Future<void> _persist(AccountProfile updated) async {
    state = updated;
    try {
      await ref.read(hiveServiceProvider).put(
            AppConstants.hiveBoxUser,
            _hiveProfileKey,
            updated.toJson(),
          );
    } catch (_) {}

    // Sync essential properties back to global userProfileProvider
    try {
      final currentGlobal = ref.read(userProfileProvider);
      final syncedUser = UserModel(
        id: updated.id,
        email: updated.email,
        displayName: updated.displayName,
        avatarUrl: updated.avatarUrl,
        weightUnit: updated.weightUnit,
        currentWeight: updated.currentWeightKg,
        targetWeight: updated.targetWeightKg,
        preferredSplit: updated.preferredSplit,
        cyclesEnabled: updated.cycleTrackingEnabled,
        totalWorkouts: updated.totalWorkouts,
        totalVolumeKg: updated.totalVolumeKg,
        createdAt: currentGlobal?.createdAt ?? updated.memberSince,
        lastActiveAt: DateTime.now(),
      );
      await ref.read(userProfileProvider.notifier).load(syncedUser);
    } catch (_) {}
  }

  /// Update display name, email, or avatar.
  Future<void> updateIdentity({
    String? displayName,
    String? email,
    String? avatarUrl,
  }) async {
    final updated = state.copyWith(
      displayName: displayName ?? state.displayName,
      email: email ?? state.email,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );
    await _persist(updated);
  }

  /// Update height, weights, and unit preferences.
  Future<void> updateBiometrics({
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    String? weightUnit,
    String? heightUnit,
  }) async {
    final updated = state.copyWith(
      heightCm: heightCm ?? state.heightCm,
      currentWeightKg: currentWeightKg ?? state.currentWeightKg,
      targetWeightKg: targetWeightKg ?? state.targetWeightKg,
      weightUnit: weightUnit ?? state.weightUnit,
      heightUnit: heightUnit ?? state.heightUnit,
    );
    await _persist(updated);
  }

  /// Update split, experience tier, rest timer, and barbell tare weight.
  Future<void> updatePreferences({
    String? preferredSplit,
    String? experienceLevel,
    int? defaultRestSeconds,
    double? barbellTareKg,
  }) async {
    final updated = state.copyWith(
      preferredSplit: preferredSplit ?? state.preferredSplit,
      experienceLevel: experienceLevel ?? state.experienceLevel,
      defaultRestSeconds: defaultRestSeconds ?? state.defaultRestSeconds,
      barbellTareKg: barbellTareKg ?? state.barbellTareKg,
    );
    await _persist(updated);
  }

  /// Toggle menstrual cycle recovery tracking.
  Future<void> toggleCycleTracking(bool value) async {
    final updated = state.copyWith(cycleTrackingEnabled: value);
    await _persist(updated);
  }

  /// Toggle audio cues for rest and sets.
  Future<void> toggleAudioCues(bool value) async {
    final updated = state.copyWith(audioCuesEnabled: value);
    await _persist(updated);
  }

  /// Toggle haptic feedback.
  Future<void> toggleHapticFeedback(bool value) async {
    final updated = state.copyWith(hapticFeedbackEnabled: value);
    await _persist(updated);
  }

  /// Reset account settings and restore initial defaults.
  Future<void> resetToDefaults() async {
    final defaults = AccountProfile(
      memberSince: DateTime.now(),
    );
    await _persist(defaults);
  }
}

final accountProfileProvider =
    NotifierProvider<AccountProfileNotifier, AccountProfile>(
  AccountProfileNotifier.new,
);
