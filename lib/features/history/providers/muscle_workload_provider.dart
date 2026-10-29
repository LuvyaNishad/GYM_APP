import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/workout_model.dart';
import '../models/muscle_workload.dart';
import 'training_coverage_provider.dart';

final sessionMuscleWorkloadProvider = Provider.autoDispose
    .family<MuscleWorkload, WorkoutModel>((ref, workout) {
      final index = ref.watch(trainingCoverageIndexProvider);
      final coverage = ref.watch(sessionCoverageProvider(workout));
      return MuscleWorkload.fromWorkout(workout, index, plan: coverage.plan);
    });

enum MuscleWorkloadScope { workout, week }

class MuscleWorkloadScopeNotifier extends Notifier<MuscleWorkloadScope> {
  @override
  MuscleWorkloadScope build() => MuscleWorkloadScope.workout;
  void select(MuscleWorkloadScope scope) => state = scope;
}

final muscleWorkloadScopeProvider =
    NotifierProvider<MuscleWorkloadScopeNotifier, MuscleWorkloadScope>(
      MuscleWorkloadScopeNotifier.new,
    );
