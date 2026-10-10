import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../data/split_presets.dart';
import '../models/split_model.dart';

/// State of training splits, active tracking program, and volume history.
class SplitsState {
  const SplitsState({
    required this.splits,
    required this.activeSplitId,
    this.expandedSplitId,
    required this.loggedVolume,
  });

  final List<TrainingSplitModel> splits;
  final String activeSplitId;
  final String? expandedSplitId;
  final Map<String, int> loggedVolume;

  TrainingSplitModel get activeSplit =>
      splits.firstWhere((s) => s.id == activeSplitId, orElse: () => splits.first);

  SplitsState copyWith({
    List<TrainingSplitModel>? splits,
    String? activeSplitId,
    String? expandedSplitId,
    bool clearExpanded = false,
    Map<String, int>? loggedVolume,
  }) {
    return SplitsState(
      splits: splits ?? this.splits,
      activeSplitId: activeSplitId ?? this.activeSplitId,
      expandedSplitId:
          clearExpanded ? null : (expandedSplitId ?? this.expandedSplitId),
      loggedVolume: loggedVolume ?? this.loggedVolume,
    );
  }
}

class SplitsNotifier extends Notifier<SplitsState> {
  @override
  SplitsState build() {
    ref.keepAlive();
    return SplitsState(
      splits: kPresetSplits,
      activeSplitId: 'split_ppl',
      expandedSplitId: 'split_ppl',
      // Baseline 14-day logged volume showing real-world progress + small deficit in Hamstrings
      loggedVolume: const {
        'Chest': 16,
        'Back': 14,
        'Shoulders': 12,
        'Quads': 11,
        'Hamstrings': 5,
        'Arms': 15,
      },
    );
  }

  /// Switches the actively tracked training split.
  void switchActiveSplit(String splitId) {
    state = state.copyWith(
      activeSplitId: splitId,
      expandedSplitId: splitId,
    );
  }

  /// Toggles expansion of a compact split card.
  void toggleExpandSplit(String splitId) {
    if (state.expandedSplitId == splitId) {
      state = state.copyWith(clearExpanded: true);
    } else {
      state = state.copyWith(expandedSplitId: splitId);
    }
  }

  /// Launches an active workout session with the selected day's exercises.
  void startWorkoutFromDay(BuildContext context, SplitWorkoutDay day) {
    final activeExercises =
        day.exercises.map((e) => e.toActiveExerciseState()).toList();

    ref.read(activeSessionProvider.notifier).startSession(
          splitName: '${state.activeSplit.shortName} // ${day.name.toUpperCase()}',
          initialExercises: activeExercises,
        );

    context.push(AppConstants.routeWorkoutSession);
  }

  /// Starts a freestyle / empty active workout session with 0 exercises preloaded.
  void startEmptyWorkout(BuildContext context) {
    ref.read(activeSessionProvider.notifier).startSession(
          splitName: 'FREESTYLE // UNSTRUCTURED SESSION',
          initialExercises: const [],
        );

    context.push(AppConstants.routeWorkoutSession);
  }

  /// Automatically fixes a lagging muscle deficit by adding a high-yield exercise
  /// and updating the logged/planned balance.
  void autoFixLaggingMuscle(String muscleGroup) {
    final currentLogged = Map<String, int>.from(state.loggedVolume);
    final currentVal = currentLogged[muscleGroup] ?? 0;
    currentLogged[muscleGroup] = currentVal + 6;

    state = state.copyWith(loggedVolume: currentLogged);
  }
}

final splitsProvider = NotifierProvider<SplitsNotifier, SplitsState>(
  SplitsNotifier.new,
);
