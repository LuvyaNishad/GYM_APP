import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../features/health_tracking/models/body_measurement_model.dart';
import 'auth_service.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

/// State of the background synchronization engine.
enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
    this.pendingCount = 0,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final int pendingCount;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    int? pendingCount,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        errorMessage: errorMessage ?? this.errorMessage,
        pendingCount: pendingCount ?? this.pendingCount,
      );
}

/// Provider that manages synchronization lifecycle and state.
final syncServiceProvider = NotifierProvider<SyncService, SyncState>(
  SyncService.new,
);

class SyncService extends Notifier<SyncState> {
  @override
  SyncState build() {
    ref.keepAlive();
    return const SyncState();
  }

  SupabaseService get _supabase => ref.read(supabaseServiceProvider);
  AuthService get _auth => ref.read(authServiceProvider);
  HiveService get _hive => ref.read(hiveServiceProvider);

  /// Synchronize all local Hive models up to Supabase.
  /// Safe to call frequently; fails gracefully without blocking the UI if offline.
  Future<void> syncAll() async {
    if (state.status == SyncStatus.syncing) return;

    if (!_supabase.isInitialized) {
      state = state.copyWith(status: SyncStatus.offline);
      return;
    }

    var userId = _auth.currentUserId;
    if (userId == null) {
      // Attempt anonymous guest session so guest data syncs safely to their own UUID
      try {
        final response = await _auth.signInAnonymously();
        userId = response.user?.id;
      } catch (e) {
        debugPrint('[SyncService] Anonymous auth skipped or offline: $e');
      }
    }

    if (userId == null) {
      state = state.copyWith(status: SyncStatus.offline);
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    try {
      await _pushProfile(userId);
      await _pushWorkouts(userId);
      await _pushSplits(userId);
      await _pushMeasurements(userId);

      state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
        pendingCount: 0,
        errorMessage: null,
      );
      debugPrint('[SyncService] Full sync completed successfully.');
    } catch (e, stack) {
      debugPrint('[SyncService] Sync encountered error: $e\n$stack');
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Push local profile to Supabase.
  Future<void> _pushProfile(String userId) async {
    final localUser = _hive.read(
      AppConstants.hiveBoxUser,
      AppConstants.hiveKeyLocalProfile,
      UserModel.fromJson,
    );
    if (localUser == null) return;

    final profileMap = <String, dynamic>{
      'id': userId,
      'email': localUser.email.isNotEmpty ? localUser.email : 'guest@leon.app',
      'display_name': localUser.displayName.isNotEmpty
          ? localUser.displayName
          : 'Leon Athlete',
      'weight_unit': localUser.weightUnit,
      'height_unit': localUser.heightUnit,
      'primary_goal': localUser.primaryGoal,
      'default_rest_seconds': localUser.defaultRestSeconds,
      'barbell_tare_kg': localUser.barbellTareKg,
      'available_plates': localUser.availablePlates,
      'audio_cues_enabled': localUser.audioCuesEnabled,
      'haptic_feedback_enabled': localUser.hapticFeedbackEnabled,
      'onboarding_complete': localUser.onboardingComplete,
      'total_workouts': localUser.totalWorkouts,
      'total_volume_kg': localUser.totalVolumeKg,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (localUser.avatarUrl != null) profileMap['avatar_url'] = localUser.avatarUrl;
    if (localUser.age != null) profileMap['age'] = localUser.age;
    if (localUser.heightCm != null) profileMap['height_cm'] = localUser.heightCm;
    if (localUser.currentWeight != null) profileMap['current_weight'] = localUser.currentWeight;
    if (localUser.targetWeight != null) profileMap['target_weight'] = localUser.targetWeight;
    if (localUser.preferredSplit != null) profileMap['preferred_split'] = localUser.preferredSplit;
    if (localUser.equipment.isNotEmpty) profileMap['equipment'] = localUser.equipment;
    if (localUser.injuries.isNotEmpty) profileMap['injuries'] = localUser.injuries;

    await _supabase.client.from('profiles').upsert(profileMap);
  }

  /// Push local workouts and their individual sets to Supabase.
  Future<void> _pushWorkouts(String userId) async {
    final workouts = _hive.readAll(
      AppConstants.hiveBoxWorkouts,
      WorkoutModel.fromJson,
    );
    if (workouts.isEmpty) return;

    for (final w in workouts) {
      final workoutRow = <String, dynamic>{
        'id': w.id,
        'user_id': userId,
        'name': w.name,
        'workout_date': w.date.toUtc().toIso8601String(),
        'duration_seconds': w.durationSeconds,
        'notes': w.notes,
        'total_volume_kg': w.totalVolumeKg ?? 0.0,
        'average_rpe': w.averageRpe,
        'training_plan': w.trainingPlan,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _supabase.client.from('workouts').upsert(workoutRow);

      // Collect sets from all exercises in this workout
      final setsRows = <Map<String, dynamic>>[];
      var order = 0;
      for (final ex in w.exercises) {
        for (final s in ex.sets) {
          setsRows.add({
            'id': '${w.id}_${ex.exerciseId}_$order',
            'workout_id': w.id,
            'user_id': userId,
            'exercise_id': ex.exerciseId,
            'exercise_name': ex.exerciseName,
            'muscle_group': ex.muscleGroup,
            'set_order': order++,
            'reps': s.reps,
            'weight_kg': s.weightKg,
            'weight_kg_right': s.weightKgRight,
            'reps_right': s.repsRight,
            'rpe': s.rpe,
            'is_warmup': s.isWarmup,
            'is_pr': s.isPr,
            'superset_group_id': ex.supersetGroupId,
            'created_at': w.date.toUtc().toIso8601String(),
          });
        }
      }

      if (setsRows.isNotEmpty) {
        await _supabase.client.from('workout_sets').upsert(setsRows);
      }
    }
  }

  /// Push custom splits/routines to Supabase.
  Future<void> _pushSplits(String userId) async {
    final splitBox = _hive.readAll(
      AppConstants.hiveBoxSplits,
      (json) => json,
    );
    if (splitBox.isEmpty) return;

    for (final raw in splitBox) {
      final id = (raw['id'] as String?) ?? 'split_${DateTime.now().millisecondsSinceEpoch}';
      final splitRow = <String, dynamic>{
        'id': id,
        'user_id': userId,
        'name': raw['name'] ?? 'Training Routine',
        'short_name': raw['shortName'] ?? raw['name'],
        'description': raw['description'] ?? '',
        'days_per_week': (raw['daysPerWeek'] as num?)?.toInt() ?? 4,
        'is_custom': raw['isCustom'] ?? true,
        'workouts': raw['workouts'] ?? [],
        'planned_muscle_sets': raw['plannedMuscleSets'] ?? {},
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _supabase.client.from('splits').upsert(splitRow);
    }
  }

  /// Push body measurements to Supabase.
  Future<void> _pushMeasurements(String userId) async {
    final entries = _hive.readAll(
      AppConstants.hiveBoxBodyMeasurements,
      BodyMeasurementEntry.fromJson,
    );
    if (entries.isEmpty) return;

    for (final m in entries) {
      final row = <String, dynamic>{
        'id': m.id,
        'user_id': userId,
        'measurement_date': m.date.toUtc().toIso8601String(),
        'weight_kg': m.weightKg,
        'body_fat_percent': m.bodyFatPercent,
        'waist_cm': m.waistCm,
        'chest_cm': m.chestCm,
        'arms_cm': m.armsCm,
        'thighs_cm': m.thighsCm,
        'notes': m.notes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _supabase.client.from('body_measurements').upsert(row);
    }
  }

  /// Restore user data from the cloud down to local Hive on a new phone.
  Future<int> restoreFromCloud() async {
    final userId = _auth.currentUserId;
    if (userId == null) return 0;

    state = state.copyWith(status: SyncStatus.syncing);
    var restoredItems = 0;

    try {
      // 1. Restore Profile
      final profileResponse = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null) {
        final user = UserModel(
          id: userId,
          email: profileResponse['email'] as String? ?? '',
          displayName: profileResponse['display_name'] as String? ?? 'Leon Athlete',
          avatarUrl: profileResponse['avatar_url'] as String?,
          weightUnit: profileResponse['weight_unit'] as String? ?? 'kg',
          heightUnit: profileResponse['height_unit'] as String? ?? 'cm',
          age: profileResponse['age'] as int?,
          heightCm: (profileResponse['height_cm'] as num?)?.toDouble(),
          currentWeight: (profileResponse['current_weight'] as num?)?.toDouble(),
          targetWeight: (profileResponse['target_weight'] as num?)?.toDouble(),
          preferredSplit: profileResponse['preferred_split'] as String?,
          equipment: (profileResponse['equipment'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
          injuries: (profileResponse['injuries'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
          primaryGoal: profileResponse['primary_goal'] as String? ?? 'BUILD MUSCLE',
          defaultRestSeconds:
              profileResponse['default_rest_seconds'] as int? ?? 90,
          barbellTareKg:
              (profileResponse['barbell_tare_kg'] as num?)?.toDouble() ?? 20.0,
          onboardingComplete:
              profileResponse['onboarding_complete'] as bool? ?? true,
          totalWorkouts: profileResponse['total_workouts'] as int? ?? 0,
          totalVolumeKg:
              (profileResponse['total_volume_kg'] as num?)?.toInt() ?? 0,
        );

        await _hive.put(
          AppConstants.hiveBoxUser,
          AppConstants.hiveKeyLocalProfile,
          user.toJson(),
        );
        restoredItems++;
      }

      // 2. Restore Workouts & Sets
      final workoutsResponse = await _supabase.client
          .from('workouts')
          .select('*, workout_sets(*)')
          .eq('user_id', userId)
          .order('workout_date', ascending: false);

      for (final w in (workoutsResponse as List<dynamic>)) {
        final wMap = Map<String, dynamic>.from(w as Map);
        final rawSets = (wMap['workout_sets'] as List<dynamic>? ?? [])
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();

        // Group sets by exercise
        final exerciseGroups = <String, List<Map<String, dynamic>>>{};
        for (final s in rawSets) {
          final exId = s['exercise_id'] as String;
          exerciseGroups.putIfAbsent(exId, () => []).add(s);
        }

        final exercises = exerciseGroups.entries.map((entry) {
          final sampleSet = entry.value.first;
          return WorkoutExercise(
            exerciseId: entry.key,
            exerciseName: sampleSet['exercise_name'] as String? ?? 'Exercise',
            muscleGroup: sampleSet['muscle_group'] as String? ?? 'General',
            supersetGroupId: sampleSet['superset_group_id'] as String?,
            sets: entry.value.map((s) {
              return WorkoutSet(
                reps: (s['reps'] as num).toInt(),
                weightKg: (s['weight_kg'] as num).toDouble(),
                weightKgRight: (s['weight_kg_right'] as num?)?.toDouble(),
                repsRight: (s['reps_right'] as num?)?.toInt(),
                rpe: (s['rpe'] as num?)?.toDouble() ?? 0.0,
                isWarmup: s['is_warmup'] as bool? ?? false,
                isPr: s['is_pr'] as bool? ?? false,
              );
            }).toList(),
          );
        }).toList();

        final model = WorkoutModel(
          id: wMap['id'] as String,
          userId: userId,
          name: wMap['name'] as String? ?? 'Workout',
          date: DateTime.parse(wMap['workout_date'] as String),
          durationSeconds: (wMap['duration_seconds'] as num?)?.toInt() ?? 0,
          notes: wMap['notes'] as String?,
          totalVolumeKg: (wMap['total_volume_kg'] as num?)?.toDouble(),
          averageRpe: (wMap['average_rpe'] as num?)?.toDouble(),
          trainingPlan: wMap['training_plan'] as Map<String, dynamic>?,
          exercises: exercises,
        );

        await _hive.put(
          AppConstants.hiveBoxWorkouts,
          model.id,
          model.toJson(),
        );
        restoredItems++;
      }

      // 3. Restore Body Measurements
      final measurementsResponse = await _supabase.client
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('measurement_date', ascending: false);

      for (final m in (measurementsResponse as List<dynamic>)) {
        final mMap = Map<String, dynamic>.from(m as Map);
        final entry = BodyMeasurementEntry(
          id: mMap['id'] as String,
          date: DateTime.parse(mMap['measurement_date'] as String),
          weightKg: (mMap['weight_kg'] as num).toDouble(),
          bodyFatPercent: (mMap['body_fat_percent'] as num?)?.toDouble(),
          waistCm: (mMap['waist_cm'] as num?)?.toDouble(),
          chestCm: (mMap['chest_cm'] as num?)?.toDouble(),
          armsCm: (mMap['arms_cm'] as num?)?.toDouble(),
          thighsCm: (mMap['thighs_cm'] as num?)?.toDouble(),
          notes: mMap['notes'] as String?,
        );
        await _hive.put(
          AppConstants.hiveBoxBodyMeasurements,
          entry.id,
          entry.toJson(),
        );
        restoredItems++;
      }

      state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
        errorMessage: null,
      );
      return restoredItems;
    } catch (e, stack) {
      debugPrint('[SyncService] Restore from cloud failed: $e\n$stack');
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      return restoredItems;
    }
  }
}
