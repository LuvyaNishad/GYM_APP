import 'package:flutter/foundation.dart';

/// Immutable state tracking the comprehensive LEON Onboarding flow.
@immutable
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.agentName = '',
    this.age = 24,
    this.height = 178,
    this.isHeightCm = true,
    this.weight = 78,
    this.isWeightKg = true,
    this.targetWeight = 74,
    this.experienceLevel = 'INTERMEDIATE',
    this.primaryGoal = 'BUILD MUSCLE',
    this.trainingDaysPerWeek = 5,
    this.preferredSplit = 'PPL',
    this.equipment = const [
      'Dumbbells',
      'Barbell',
      'Bench',
      'Pull-up Bar',
    ],
    this.injuries = const [],
    this.isCompleted = false,
  });

  final int currentPage;
  final String agentName;
  final int age;
  final double height;
  final bool isHeightCm;
  final double weight;
  final bool isWeightKg;
  final double targetWeight;
  final String experienceLevel;
  final String primaryGoal;
  final int trainingDaysPerWeek;
  final String preferredSplit;
  final List<String> equipment;
  final List<String> injuries;
  final bool isCompleted;

  // 15 onboarding pages in total (0: Splash, 1: Welcome, 2-13: Steps 1-12, 14: Ready)
  static const int totalPages = 15;

  bool get isLastPage => currentPage == totalPages - 1;

  /// Progress fraction for the top progress bar across the 12 survey steps (pages 2-13).
  double get stepProgress {
    if (currentPage <= 1) return 0.0;
    if (currentPage >= 14) return 1.0;
    return (currentPage - 1) / 12.0;
  }

  /// Step label in format "01 / 12" through "12 / 12"
  String get stepLabel {
    if (currentPage < 2 || currentPage > 13) return '';
    final stepNum = currentPage - 1;
    final formatted = stepNum < 10 ? '0$stepNum' : '$stepNum';
    return '$formatted / 12';
  }

  OnboardingState copyWith({
    int? currentPage,
    String? agentName,
    int? age,
    double? height,
    bool? isHeightCm,
    double? weight,
    bool? isWeightKg,
    double? targetWeight,
    String? experienceLevel,
    String? primaryGoal,
    int? trainingDaysPerWeek,
    String? preferredSplit,
    List<String>? equipment,
    List<String>? injuries,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      agentName: agentName ?? this.agentName,
      age: age ?? this.age,
      height: height ?? this.height,
      isHeightCm: isHeightCm ?? this.isHeightCm,
      weight: weight ?? this.weight,
      isWeightKg: isWeightKg ?? this.isWeightKg,
      targetWeight: targetWeight ?? this.targetWeight,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      preferredSplit: preferredSplit ?? this.preferredSplit,
      equipment: equipment ?? this.equipment,
      injuries: injuries ?? this.injuries,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
