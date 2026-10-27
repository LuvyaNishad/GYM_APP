import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';

class PlatePreferences {
  const PlatePreferences({
    this.barKg = 20,
    this.plates = const [25, 20, 15, 10, 5, 2.5, 1.25],
  });
  final double barKg;
  final List<double> plates;
}

class PlatePreferencesNotifier extends Notifier<PlatePreferences> {
  @override
  PlatePreferences build() {
    final data = ref
        .watch(hiveServiceProvider)
        .getSetting<Map>('plate_preferences_v1');
    return data == null
        ? const PlatePreferences()
        : PlatePreferences(
            barKg: _bar(data['bar']),
            plates: _plates(data['plates']),
          );
  }

  Future<void> save(PlatePreferences preferences) async {
    preferences = PlatePreferences(
      barKg: _bar(preferences.barKg),
      plates: _plates(preferences.plates),
    );
    await ref.read(hiveServiceProvider).putSettingChecked(
      'plate_preferences_v1',
      {'bar': preferences.barKg, 'plates': preferences.plates},
    );
    if (ref.mounted) state = preferences;
  }

  static double _bar(Object? value) =>
      value is num && value.isFinite && value >= 0 && value <= 100
      ? value.toDouble()
      : 20;
  static List<double> _plates(Object? values) {
    if (values is! List) return const PlatePreferences().plates;
    return values
        .whereType<num>()
        .where((n) => n.isFinite && n >= .01 && n <= 100)
        .map((n) => n.toDouble())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }
}

final platePreferencesProvider =
    NotifierProvider<PlatePreferencesNotifier, PlatePreferences>(
      PlatePreferencesNotifier.new,
    );
