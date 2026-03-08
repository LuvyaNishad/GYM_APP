import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';
part 'onboarding_state.g.dart';

/// Immutable value object tracking the state of the onboarding flow.
///
/// Uses Freezed for codegen and JsonSerializable for persistence.
@freezed
class OnboardingState with _$OnboardingState {
  // Private generative constructor required to add getters/methods.
  const OnboardingState._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory OnboardingState({
    @Default(0) int currentPage,
    @Default(false) bool isCompleted,
  }) = _OnboardingState;

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);

  // ── Derived state ──────────────────────────────────────────────────────────

  /// Total number of onboarding pages.
  static const int totalPages = 4;

  /// True when the user is on the final onboarding page.
  bool get isLastPage => currentPage == totalPages - 1;
}
