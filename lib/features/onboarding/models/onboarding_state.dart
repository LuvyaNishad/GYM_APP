/// Immutable value object tracking the state of the onboarding flow.
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.isCompleted = false,
  });

  final int currentPage;
  final bool isCompleted;

  /// Total number of onboarding pages.
  static const int totalPages = 4;

  bool get isLastPage => currentPage == totalPages - 1;

  OnboardingState copyWith({
    int? currentPage,
    bool? isCompleted,
  }) =>
      OnboardingState(
        currentPage: currentPage ?? this.currentPage,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingState &&
          runtimeType == other.runtimeType &&
          currentPage == other.currentPage &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(currentPage, isCompleted);
}
