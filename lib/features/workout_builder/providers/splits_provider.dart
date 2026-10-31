import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../services/hive_service.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../data/split_presets.dart';
import '../models/split_model.dart';
import '../models/training_schedule.dart';
import '../models/workout_sequence.dart';
import '../../history/providers/history_provider.dart';
import 'weekly_volume_provider.dart';

/// State of training splits, active tracking program, and volume history.
class SplitsState {
  const SplitsState({
    required this.splits,
    required this.activeSplitId,
    this.expandedSplitId,
    required this.loggedVolume,
    this.schedules = const [],
  });

  final List<TrainingSplitModel> splits;
  final String activeSplitId;
  final String? expandedSplitId;
  final Map<String, int> loggedVolume;
  final List<TrainingSchedule> schedules;

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
    List<TrainingSchedule>? schedules,
  }) {
    return SplitsState(
      splits: splits ?? this.splits,
      activeSplitId: activeSplitId ?? this.activeSplitId,
      expandedSplitId: clearExpanded
          ? null
          : (expandedSplitId ?? this.expandedSplitId),
      loggedVolume: loggedVolume ?? this.loggedVolume,
      schedules: schedules ?? this.schedules,
    );
  }
}

class SplitsNotifier extends Notifier<SplitsState> {
  bool _savingSchedule = false;
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

    final history = ref.watch(historyWorkoutsProvider);
    var schedules = TrainingSchedule.decode(
      hive.getSetting<String>(AppConstants.settingTrainingSchedules),
    );
    if (schedules.isEmpty) {
      schedules = [
        TrainingSchedule.fromLegacy(
          allSplits.firstWhere((split) => split.id == effectiveActiveId),
          history,
          scheduleDate(DateTime.now()),
        ),
      ];
      // Preserve the migration boundary across restarts, even before the first workout.
      hive.putSetting(
        AppConstants.settingTrainingSchedules,
        TrainingSchedule.encode(schedules),
      );
    }

    final today = scheduleDate(DateTime.now());
    if (trainingScheduleForDate(schedules, today)?.splitId !=
        effectiveActiveId) {
      schedules = startTrainingSchedule(
        schedules,
        allSplits.firstWhere((split) => split.id == effectiveActiveId),
        today,
      );
      hive.putSetting(
        AppConstants.settingTrainingSchedules,
        TrainingSchedule.encode(schedules),
      );
    }
    return SplitsState(
      splits: allSplits,
      activeSplitId: effectiveActiveId,
      expandedSplitId: null,
      schedules: schedules,
      loggedVolume: completedWeeklyMuscleSets(history, DateTime.now()),
    );
  }

  /// Pause until the user resumes, or optionally until a chosen return date.
  Future<void> pauseTraining({DateTime? resumeOn}) async {
    if (ref.read(activeSessionProvider).isActive) {
      throw StateError(
        'Finish or discard your current workout before pausing.',
      );
    }
    final today = ref.read(localDateProvider);
    final returnDate = resumeOn == null ? null : scheduleDate(resumeOn);
    if (returnDate != null && !returnDate.isAfter(today)) {
      throw ArgumentError('Choose a return date after today.');
    }
    final active = trainingScheduleForDate(state.schedules, today);
    final historyStart = active?.historyStartedOn ?? today;
    await _saveTrainingSchedules([
      ...state.schedules.where(
        (schedule) => schedule.startedOn.isBefore(today),
      ),
      TrainingSchedule.fromSplit(
        state.activeSplit,
        today,
        isPaused: true,
        historyStartedOn: historyStart,
      ),
      if (returnDate != null) _scheduleForReturn(returnDate, historyStart),
    ]);
  }

  Future<void> resumeTraining() async {
    final today = ref.read(localDateProvider);
    final active = trainingScheduleForDate(state.schedules, today);
    if (active?.isPaused != true) return;
    await _saveTrainingSchedules([
      ...state.schedules.where(
        (schedule) => schedule.startedOn.isBefore(today),
      ),
      _scheduleForReturn(today, active!.historyStartedOn),
    ]);
  }

  TrainingSchedule _scheduleForReturn(DateTime date, DateTime historyStart) {
    final split = state.activeSplit;
    final latest = latestCompletedSplitDay(
      split,
      ref.read(historyWorkoutsProvider),
      // Future-dated logs must never determine the return workout.
      ref.read(localDateProvider),
    );
    final index = latest == null ? 0 : nextWorkoutDayIndex(split, latest, date);
    return TrainingSchedule.fromSplit(
      split,
      date,
      // Workout-only routines restart their weekly training/rest pattern.
      startIndex: split.workouts.any((day) => day.isRestDay) ? index : 0,
      historyStartedOn: historyStart,
    );
  }

  Future<void> _saveTrainingSchedules(List<TrainingSchedule> schedules) async {
    if (_savingSchedule) {
      throw StateError('Your schedule is already being saved.');
    }
    _savingSchedule = true;
    try {
      await ref
          .read(hiveServiceProvider)
          .putSettingChecked(
            AppConstants.settingTrainingSchedules,
            TrainingSchedule.encode(schedules),
          );
      state = state.copyWith(schedules: schedules);
    } finally {
      _savingSchedule = false;
    }
  }

  bool _canStartTraining(BuildContext context) {
    if (!state.schedules.any((schedule) => schedule.isPaused)) return true;
    if (trainingScheduleForDate(
          state.schedules,
          ref.read(localDateProvider),
        )?.isPaused !=
        true) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resume training from Home before starting a workout.'),
      ),
    );
    return false;
  }

  /// Switches the actively tracked training split.
  void switchActiveSplit(String splitId) {
    if (state.activeSplitId == splitId) return;
    final split = state.splits.firstWhere((split) => split.id == splitId);
    final schedules = startTrainingSchedule(
      state.schedules,
      split,
      DateTime.now(),
    );
    state = state.copyWith(
      activeSplitId: splitId,
      clearExpanded: true,
      schedules: schedules,
    );
    ref
        .read(hiveServiceProvider)
        .putSetting(
          AppConstants.settingTrainingSchedules,
          TrainingSchedule.encode(schedules),
        );
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
    // Only future/current plan days change after an edit; retain the past copy.
    final changedCalendar =
        state.activeSplitId == split.id &&
        (state.activeSplit.daysPerWeek != split.daysPerWeek ||
            !listEquals(
              state.activeSplit.workouts.map((day) => day.isRestDay).toList(),
              split.workouts.map((day) => day.isRestDay).toList(),
            ));
    final schedules = changedCalendar
        ? startTrainingSchedule(state.schedules, split, DateTime.now())
        : state.schedules;
    if (changedCalendar) {
      await hive.putSetting(
        AppConstants.settingTrainingSchedules,
        TrainingSchedule.encode(schedules),
      );
    }
    state = state.copyWith(splits: current, schedules: schedules);
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

    final schedules = newActive != state.activeSplitId
        ? startTrainingSchedule(
            state.schedules,
            filtered.firstWhere((split) => split.id == newActive),
            DateTime.now(),
          )
        : state.schedules;

    state = state.copyWith(
      splits: filtered,
      activeSplitId: newActive,
      schedules: schedules,
      expandedSplitId: state.expandedSplitId == splitId
          ? newActive
          : state.expandedSplitId,
    );
    await hive.putSetting(AppConstants.settingActiveSplitId, newActive);
    await hive.putSetting(
      AppConstants.settingTrainingSchedules,
      TrainingSchedule.encode(schedules),
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
    if (!_canStartTraining(context)) return;
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
    if (!_canStartTraining(context)) return;
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
