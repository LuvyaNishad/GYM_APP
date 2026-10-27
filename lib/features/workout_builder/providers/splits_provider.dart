import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/hive_service.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../data/split_presets.dart';
import '../models/split_model.dart';
import '../../history/providers/history_provider.dart';
import 'weekly_volume_provider.dart';

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

  TrainingSplitModel get activeSplit => splits.firstWhere(
    (s) => s.id == activeSplitId,
    orElse: () => splits.first,
  );

  List<TrainingSplitModel> get presetSplits =>
      splits.where((s) => !s.isCustom).toList();

  List<TrainingSplitModel> get customSplits =>
      splits.where((s) => s.isCustom).toList();

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
      expandedSplitId: clearExpanded
          ? null
          : (expandedSplitId ?? this.expandedSplitId),
      loggedVolume: loggedVolume ?? this.loggedVolume,
    );
  }
}

class SplitsNotifier extends Notifier<SplitsState> {
  @override
  SplitsState build() {
    ref.keepAlive();
    final hive = ref.watch(hiveServiceProvider);

    List<TrainingSplitModel> customSplits = [];
    try {
      customSplits = hive.readAll<TrainingSplitModel>(
        AppConstants.hiveBoxSplits,
        TrainingSplitModel.fromJson,
      );
    } catch (_) {
      customSplits = [];
    }

    final allSplits = [...kPresetSplits, ...customSplits];

    final savedActiveId =
        hive.getSetting<String>(
          AppConstants.settingActiveSplitId,
          fallback: 'split_ppl',
        ) ??
        'split_ppl';

    final effectiveActiveId = allSplits.any((s) => s.id == savedActiveId)
        ? savedActiveId
        : allSplits.first.id;

    return SplitsState(
      splits: allSplits,
      activeSplitId: effectiveActiveId,
      expandedSplitId: null,
      loggedVolume: completedWeeklyMuscleSets(
        ref.watch(historyWorkoutsProvider),
        DateTime.now(),
      ),
    );
  }

  /// Switches the actively tracked training split.
  void switchActiveSplit(String splitId) {
    state = state.copyWith(activeSplitId: splitId, clearExpanded: true);
    ref
        .read(hiveServiceProvider)
        .putSetting(AppConstants.settingActiveSplitId, splitId);
  }

  /// Saves a custom training split to state and local storage.
  Future<void> saveCustomSplit(TrainingSplitModel split) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.put(AppConstants.hiveBoxSplits, split.id, split.toJson());

    final current = List<TrainingSplitModel>.from(state.splits);
    final idx = current.indexWhere((s) => s.id == split.id);
    if (idx >= 0) {
      current[idx] = split;
    } else {
      current.add(split);
    }
    state = state.copyWith(splits: current);
  }

  /// Duplicates an existing preset or custom split into a customizable user routine.
  Future<TrainingSplitModel> duplicateSplit(String splitId) async {
    final original = state.splits.firstWhere((s) => s.id == splitId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newId = 'custom_split_$timestamp';

    final clonedWorkouts = original.workouts.map((w) {
      return w.copyWith(
        id: '${w.id}_$timestamp',
        exercises: w.exercises.map((e) => e.copyWith()).toList(),
      );
    }).toList();

    final duplicated = TrainingSplitModel(
      id: newId,
      name: '${original.name} (Custom)',
      shortName: '${original.shortName}*',
      daysPerWeek: original.daysPerWeek,
      description: 'Customized based on ${original.name}.',
      isCustom: true,
      workouts: clonedWorkouts,
      plannedMuscleSets: Map<String, int>.from(original.plannedMuscleSets),
    );

    await saveCustomSplit(duplicated);
    return duplicated;
  }

  /// Deletes a custom training split and falls back safely if it was active.
  Future<void> deleteCustomSplit(String splitId) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.delete(AppConstants.hiveBoxSplits, splitId);

    final filtered = state.splits.where((s) => s.id != splitId).toList();
    final newActive = state.activeSplitId == splitId
        ? (filtered.isNotEmpty ? filtered.first.id : 'split_ppl')
        : state.activeSplitId;

    state = state.copyWith(
      splits: filtered,
      activeSplitId: newActive,
      expandedSplitId: state.expandedSplitId == splitId
          ? newActive
          : state.expandedSplitId,
    );
    await hive.putSetting(AppConstants.settingActiveSplitId, newActive);
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
    final activeExercises = day.exercises
        .map((e) => e.toActiveExerciseState())
        .toList();

    ref
        .read(activeSessionProvider.notifier)
        .startSession(
          splitName:
              '${state.activeSplit.shortName} ● ${day.name.toUpperCase()}',
          initialExercises: activeExercises,
        );

    context.push(AppConstants.routeWorkoutSession);
  }

  /// Starts a freestyle / empty active workout session with 0 exercises preloaded.
  void startEmptyWorkout(BuildContext context) {
    ref
        .read(activeSessionProvider.notifier)
        .startSession(
          splitName: 'Freestyle Workout',
          initialExercises: const [],
        );

    context.push(AppConstants.routeWorkoutSession);
  }

  /// Automatically fixes a lagging muscle deficit by adding a high-yield exercise
  /// and updating the logged/planned balance.
  void autoFixLaggingMuscle(String muscleGroup) {
    // Kept for older callers; only completed workouts can change logged volume.
    // Current UI opens the routine editor so the user can review plan changes.
  }
}

final splitsProvider = NotifierProvider<SplitsNotifier, SplitsState>(
  SplitsNotifier.new,
);
