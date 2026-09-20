import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/hive_service.dart';
import '../models/onboarding_state.dart';

export '../models/onboarding_state.dart';

/// Whether the user has already finished onboarding, read straight from
/// storage.
///
/// Kept separate from [onboardingProvider] so the router can decide the initial
/// location without building the onboarding flow's page state.
final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(hiveServiceProvider).getSetting<bool>(
            AppConstants.settingOnboardingComplete,
            fallback: false,
          ) ??
      false;
});

/// Manages the step-by-step progression through the onboarding flow.
///
/// Kept alive so paging back and forth (or a transient rebuild) doesn't drop
/// the user back to page one mid-flow.
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    ref.keepAlive();
    return OnboardingState(isCompleted: ref.watch(onboardingCompleteProvider));
  }

  /// Advance to the next onboarding page if not already at the last page.
  void nextPage() {
    if (!state.isLastPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Return to the previous onboarding page if not at the first page.
  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Mark onboarding as completed so the app skips it on next launch.
  Future<void> complete() async {
    await ref
        .read(hiveServiceProvider)
        .putSetting(AppConstants.settingOnboardingComplete, true);
    ref.invalidate(onboardingCompleteProvider);
    state = state.copyWith(isCompleted: true);
  }

  /// Reset the onboarding flow to the first page and clear the persisted flag
  /// (used for re-onboarding).
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
