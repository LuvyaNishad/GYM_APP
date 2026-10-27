import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';

class ExerciseFavorites extends Notifier<Set<String>> {
  Future<void> _writes = Future.value();
  @override
  Set<String> build() =>
      (ref
                  .watch(hiveServiceProvider)
                  .getSetting<List>('exercise_favorites_v1') ??
              [])
          .map((e) => e.toString())
          .toSet();
  Future<void> toggle(String name) {
    final hive = ref.read(hiveServiceProvider);
    _writes = _writes.catchError((Object _) {}).then((_) async {
      final next = {...state};
      if (!next.add(name)) next.remove(name);
      await hive.putSettingChecked('exercise_favorites_v1', next.toList());
      if (ref.mounted) state = next;
    });
    return _writes;
  }
}

final exerciseFavoritesProvider =
    NotifierProvider<ExerciseFavorites, Set<String>>(ExerciseFavorites.new);
