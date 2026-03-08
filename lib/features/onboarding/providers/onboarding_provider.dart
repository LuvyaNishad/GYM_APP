import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/onboarding_state.dart';

export '../models/onboarding_state.dart';

/// Manages the step-by-step progression through the onboarding flow.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

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

  /// Mark onboarding as completed so the app can skip it on next launch.
  void complete() {
    state = state.copyWith(isCompleted: true);
    // TODO(onboarding): persist completion flag via Hive/SharedPreferences.
  }

  /// Reset onboarding flow to the first page (used for re-onboarding).
  void reset() {
    state = const OnboardingState();
  }
}

/// Global provider for [OnboardingNotifier].
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (_) => OnboardingNotifier(),
);
