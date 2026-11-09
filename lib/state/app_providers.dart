/// AEON — global Riverpod providers.
///
/// Feature-specific providers live inside each feature's own `providers/`
/// directory. This file is for truly cross-cutting state (auth user, theme, etc.)
///
/// Riverpod 3 note: providers are auto-dispose by default. Everything here is
/// app-lifetime state, so each notifier calls `ref.keepAlive()` in `build()`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/split_model.dart';
import '../models/user_model.dart';
import '../services/hive_service.dart';
import '../services/split_service.dart';
import '../services/profile_storage.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

/// The UID of the currently authenticated user, or null if logged out.
/// Feature providers should `watch` this to react to auth changes.
class CurrentUserId extends Notifier<String?> {
  @override
  String? build() {
    ref.keepAlive();
    return null;
  }

  void signedIn(String userId) => state = userId;

  void signedOut() => state = null;
}

final currentUserIdProvider = NotifierProvider<CurrentUserId, String?>(
  CurrentUserId.new,
);

/// Whether the app has completed its bootstrap (Hive init, DI, etc.)
class AppBootstrapped extends Notifier<bool> {
  @override
  bool build() {
    ref.keepAlive();
    return false;
  }

  void markReady() => state = true;
}

final appBootstrappedProvider = NotifierProvider<AppBootstrapped, bool>(
  AppBootstrapped.new,
);

// ── Theme ─────────────────────────────────────────────────────────────────────

/// Whether the UI is in compact (phone) or expanded (tablet) layout.
final isCompactLayoutProvider = Provider<bool>((ref) => true);

// ── Navigation ────────────────────────────────────────────────────────────────

/// Currently selected bottom-navigation index.
class BottomNavIndex extends Notifier<int> {
  @override
  int build() {
    ref.keepAlive();
    return 0;
  }

  void select(int index) => state = index;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndex, int>(
  BottomNavIndex.new,
);

// ── Training Split ────────────────────────────────────────────────────────────

/// The user's currently active training split.
/// Drives "today's workout" on the dashboard and session-start routing.
/// Null = no split assigned yet (send user to split builder).
///
/// Hydrated synchronously from storage: [HiveService] boxes are open before the
/// first frame, so the split survives a restart without an async gap.
class ActiveSplit extends Notifier<SplitModel?> {
  @override
  SplitModel? build() {
    ref.keepAlive();
    return ref.watch(splitServiceProvider).activeSplitSync();
  }

  /// Persist [split] and follow it.
  Future<void> select(SplitModel split) async {
    await ref.read(splitServiceProvider).activate(split);
    state = split;
  }

  /// Stop following any split. The split itself stays saved.
  Future<void> clear() async {
    await ref.read(splitServiceProvider).setActiveSplit(null);
    state = null;
  }
}

final activeSplitProvider = NotifierProvider<ActiveSplit, SplitModel?>(
  ActiveSplit.new,
);

// ── User Profile ──────────────────────────────────────────────────────────────

/// The current user's profile model.
/// Drives weight-unit toggle, profile screen display, and questionnaire data.
/// Null = no profile stored yet (fresh install, pre-onboarding).
///
/// AEON is guest-first, so there is one local profile keyed by
/// [AppConstants.hiveKeyLocalProfile] whether or not it's backed by an account.
class UserProfile extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    ref.keepAlive();
    try {
      return readLocalProfile(ref.watch(hiveServiceProvider));
    } catch (_) {
      // A profile left behind by a schema change must not block boot.
      return null;
    }
  }

  Future<void> _writes = Future.value();

  /// Atomic profile/media changes share the same queue as form edits, so a
  /// pending form cannot publish an older avatar after a picture has saved.
  Future<void> persistSnapshot(Future<void> Function(HiveService) save) {
    final hive = ref.read(hiveServiceProvider);
    final result = _writes.catchError((Object _) {}).then((_) async {
      await save(hive);
      if (ref.mounted) state = readLocalProfile(hive);
    });
    _writes = result;
    return result;
  }

  /// All profile consumers share one persistence queue and read the latest value.
  Future<void> transform(
    UserModel? Function(UserModel? current) change, {
    Map<String, dynamic>? accountMirror,
  }) {
    final result = _writes.catchError((Object _) {}).then((_) async {
      final updated = change(state);
      if (updated == null) return;
      final hive = ref.read(hiveServiceProvider);
      if (accountMirror == null) {
        await hive.put(
          AppConstants.hiveBoxUser,
          AppConstants.hiveKeyLocalProfile,
          updated.toJson(),
        );
      } else {
        await hive.putAll<MapEntry<String, Map<String, dynamic>>>(
          AppConstants.hiveBoxUser,
          [
            MapEntry(AppConstants.hiveKeyLocalProfile, updated.toJson()),
            MapEntry('account_profile_data', {
              ...accountMirror,
              'avatar_url': updated.avatarUrl,
            }),
          ],
          keyOf: (entry) => entry.key,
          toJson: (entry) => entry.value,
        );
      }
      if (ref.mounted) state = updated;
    });
    _writes = result;
    return result;
  }

  Future<void> load(UserModel? profile) {
    if (profile == null) {
      state = null;
      return Future.value();
    }
    return transform((_) => profile);
  }

  Future<void> update(UserModel Function(UserModel current) change) =>
      transform((current) => current == null ? null : change(current));

  /// Drop the in-memory profile without touching storage (sign-out).
  void clear() => state = null;

  /// Delete the stored profile as well (account reset).
  Future<void> erase() async {
    await ref
        .read(hiveServiceProvider)
        .delete(AppConstants.hiveBoxUser, AppConstants.hiveKeyLocalProfile);
    state = null;
  }
}

final userProfileProvider = NotifierProvider<UserProfile, UserModel?>(
  UserProfile.new,
);
