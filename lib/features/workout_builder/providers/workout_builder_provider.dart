import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder workout builder provider — selected exercise IDs.
/// TODO: implement drag-and-drop exercise selection state.
class WorkoutBuilderNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    ref.keepAlive();
    return const [];
  }

  void add(String exerciseId) => state = [...state, exerciseId];

  void remove(String exerciseId) =>
      state = state.where((id) => id != exerciseId).toList();

  void clear() => state = const [];
}

final workoutBuilderProvider =
    NotifierProvider<WorkoutBuilderNotifier, List<String>>(
  WorkoutBuilderNotifier.new,
);
