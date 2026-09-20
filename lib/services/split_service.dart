/// LEON Split Service
///
/// Persists training splits and resolves which day of a split "today" is.
/// The day-resolution helpers are static and pure so the dashboard, the
/// session screen, and tests can all call them without a service instance.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/split_model.dart';
import 'hive_service.dart';

/// Provider that exposes the SplitService singleton.
final splitServiceProvider = Provider<SplitService>(
  (ref) => SplitService(ref.watch(hiveServiceProvider)),
);

class SplitService {
  const SplitService(this._hive);

  final HiveService _hive;

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> saveSplit(SplitModel split) => _hive.put(
        AppConstants.hiveBoxSplits,
        split.id,
        split.toJson(),
      );

  Future<List<SplitModel>> fetchSplits() async {
    final splits = _hive.readAll(
      AppConstants.hiveBoxSplits,
      SplitModel.fromJson,
    );
    splits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return splits;
  }

  Future<SplitModel?> fetchSplit(String splitId) async => _hive.read(
        AppConstants.hiveBoxSplits,
        splitId,
        SplitModel.fromJson,
      );

  Future<void> deleteSplit(String splitId) async {
    await _hive.delete(AppConstants.hiveBoxSplits, splitId);
    if (activeSplitId() == splitId) {
      await _hive.deleteSetting(AppConstants.settingActiveSplitId);
    }
  }

  // ── Active split ────────────────────────────────────────────────────────────

  /// The id of the split the user is currently following, or null.
  String? activeSplitId() =>
      _hive.getSetting<String>(AppConstants.settingActiveSplitId);

  Future<void> setActiveSplit(String? splitId) => splitId == null
      ? _hive.deleteSetting(AppConstants.settingActiveSplitId)
      : _hive.putSetting(AppConstants.settingActiveSplitId, splitId);

  /// Load the active split, or null when none is set (send the user to the
  /// split builder).
  Future<SplitModel?> fetchActiveSplit() async => activeSplitSync();

  /// Synchronous read of the active split, for provider initialisation — an
  /// async gap there would flash an empty dashboard on every launch.
  ///
  /// Returns null when no split is active *or* when the stored record can't be
  /// decoded: a split left behind by a schema change must not stop the app
  /// from booting.
  SplitModel? activeSplitSync() {
    final id = activeSplitId();
    if (id == null) return null;
    try {
      return _hive.read(AppConstants.hiveBoxSplits, id, SplitModel.fromJson);
    } catch (_) {
      return null;
    }
  }

  /// Persist [split] and make it the one the user is following.
  Future<void> activate(SplitModel split) async {
    await saveSplit(split);
    await setActiveSplit(split.id);
  }

  // ── Day resolution ──────────────────────────────────────────────────────────

  /// Which day of [split] falls on [date], as an index into
  /// [SplitModel.dayLabels].
  ///
  /// Splits cycle continuously from [SplitModel.createdAt] — a 3-day PPL
  /// started on a Monday puts Push on day 0, Pull on day 1, Legs on day 2,
  /// then Push again. Returns -1 for a split with no days configured.
  ///
  /// Dates are compared at day granularity so a session logged at 23:00 and
  /// one at 06:00 the same day resolve identically.
  static int dayIndexFor(SplitModel split, DateTime date) {
    final dayCount = split.dayLabels.length;
    if (dayCount == 0) return -1;

    final start = DateTime(
      split.createdAt.year,
      split.createdAt.month,
      split.createdAt.day,
    );
    final target = DateTime(date.year, date.month, date.day);
    final elapsed = target.difference(start).inDays;

    // Dart's `%` returns a non-negative result for a positive divisor, so
    // dates before createdAt wrap backwards through the cycle correctly.
    return elapsed % dayCount;
  }

  /// The label for the split day falling on [date], or null when unresolvable.
  static String? dayLabelFor(SplitModel split, DateTime date) {
    final index = dayIndexFor(split, date);
    if (index < 0 || index >= split.dayLabels.length) return null;
    return split.dayLabels[index];
  }

  /// Exercise ids scheduled for [date]. Empty when the day has none, or when
  /// [SplitModel.dayExerciseIds] is shorter than [SplitModel.dayLabels].
  static List<String> exerciseIdsFor(SplitModel split, DateTime date) {
    final index = dayIndexFor(split, date);
    if (index < 0 || index >= split.dayExerciseIds.length) {
      return const <String>[];
    }
    return split.dayExerciseIds[index];
  }

  /// Convenience wrappers for "today".
  static String? todaysLabel(SplitModel split) =>
      dayLabelFor(split, DateTime.now());

  static List<String> todaysExerciseIds(SplitModel split) =>
      exerciseIdsFor(split, DateTime.now());
}
