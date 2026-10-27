import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';

String habitDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class WaterEntry {
  const WaterEntry({required this.id, required this.ml, required this.time});
  final String id;
  final int ml;
  final DateTime time;
  Map<String, dynamic> toJson() => {
    'id': id,
    'ml': ml,
    'time': time.toIso8601String(),
  };
  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
    id: json['id'] as String,
    ml: (json['ml'] as num).toInt(),
    time: DateTime.parse(json['time'] as String),
  );
}

class DayHabits {
  const DayHabits({
    this.water = const [],
    this.sleepHours = 0,
    this.bedtime,
    this.wakeTime,
    this.feeling,
    this.calories = 0,
  });
  final List<WaterEntry> water;
  final double sleepHours;
  final DateTime? bedtime;
  final DateTime? wakeTime;
  final String? feeling;
  final int calories;
  int get waterMl => water.fold(0, (sum, e) => sum + e.ml);
  DayHabits copyWith({
    List<WaterEntry>? water,
    double? sleepHours,
    DateTime? bedtime,
    DateTime? wakeTime,
    String? feeling,
    int? calories,
    bool clearTimes = false,
    bool clearFeeling = false,
  }) => DayHabits(
    water: water ?? this.water,
    sleepHours: sleepHours ?? this.sleepHours,
    bedtime: clearTimes ? null : bedtime ?? this.bedtime,
    wakeTime: clearTimes ? null : wakeTime ?? this.wakeTime,
    feeling: clearFeeling ? null : feeling ?? this.feeling,
    calories: calories ?? this.calories,
  );
  Map<String, dynamic> toJson() => {
    'water': water.map((e) => e.toJson()).toList(),
    'sleepHours': sleepHours,
    'bedtime': bedtime?.toIso8601String(),
    'wakeTime': wakeTime?.toIso8601String(),
    'feeling': feeling,
    'calories': calories,
  };
  factory DayHabits.fromJson(Map<String, dynamic> json) => DayHabits(
    water: (json['water'] as List? ?? [])
        .map((e) => WaterEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
    bedtime: DateTime.tryParse(json['bedtime'] as String? ?? ''),
    wakeTime: DateTime.tryParse(json['wakeTime'] as String? ?? ''),
    feeling: json['feeling'] as String?,
    calories: (json['calories'] as num?)?.toInt() ?? 0,
  );
}

class HabitLog {
  const HabitLog({
    this.days = const {},
    this.waterGoalMl = 3500,
    this.sleepGoalHours = 8,
    this.stepsGoal = 8000,
  });
  final Map<String, DayHabits> days;
  final int waterGoalMl;
  final double sleepGoalHours;
  final int stepsGoal;
  DayHabits day(DateTime date) => days[habitDateKey(date)] ?? const DayHabits();
  HabitLog copyWith({
    Map<String, DayHabits>? days,
    int? waterGoalMl,
    double? sleepGoalHours,
    int? stepsGoal,
  }) => HabitLog(
    days: days ?? this.days,
    waterGoalMl: waterGoalMl ?? this.waterGoalMl,
    sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
    stepsGoal: stepsGoal ?? this.stepsGoal,
  );
  Map<String, dynamic> toJson() => {
    'days': days.map((k, v) => MapEntry(k, v.toJson())),
    'waterGoalMl': waterGoalMl,
    'sleepGoalHours': sleepGoalHours,
    'stepsGoal': stepsGoal,
  };
}

class HabitLogNotifier extends Notifier<HabitLog> {
  static const storageKey = 'daily_habits_v1';
  Future<void> _writes = Future.value();
  @override
  HabitLog build() {
    final raw = ref.watch(hiveServiceProvider).getSetting<String>(storageKey);
    if (raw == null) return const HabitLog();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return HabitLog(
        days: (json['days'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            DayHabits.fromJson(Map<String, dynamic>.from(v as Map)),
          ),
        ),
        waterGoalMl: (json['waterGoalMl'] as num?)?.toInt() ?? 3500,
        sleepGoalHours: (json['sleepGoalHours'] as num?)?.toDouble() ?? 8,
        stepsGoal: (json['stepsGoal'] as num?)?.toInt() ?? 8000,
      );
    } catch (_) {
      return const HabitLog();
    }
  }

  Future<void> _change(HabitLog Function(HabitLog) update) {
    final hive = ref.read(hiveServiceProvider);
    _writes = _writes.catchError((Object _) {}).then((_) async {
      final next = update(state);
      await hive.putSettingChecked(storageKey, jsonEncode(next.toJson()));
      if (ref.mounted) state = next;
    });
    return _writes;
  }

  Future<void> _day(DateTime date, DayHabits Function(DayHabits) update) =>
      _change(
        (log) => log.copyWith(
          days: {...log.days, habitDateKey(date): update(log.day(date))},
        ),
      );
  Future<void> addWater(int ml, {DateTime? date}) {
    if (ml <= 0 || ml > 5000) throw ArgumentError('Enter 1–5000 ml.');
    final now = DateTime.now();
    return _day(
      date ?? now,
      (day) => day.copyWith(
        water: [
          ...day.water,
          WaterEntry(id: '${now.microsecondsSinceEpoch}', ml: ml, time: now),
        ],
      ),
    );
  }

  Future<void> undoWater({DateTime? date}) => _day(
    date ?? DateTime.now(),
    (day) => day.copyWith(
      water: day.water.isEmpty
          ? []
          : day.water.sublist(0, day.water.length - 1),
    ),
  );
  Future<void> saveSleep({
    required DateTime date,
    required double hours,
    DateTime? bedtime,
    DateTime? wakeTime,
    String? feeling,
  }) {
    if (!hours.isFinite || hours <= 0 || hours > 24) {
      throw ArgumentError('Enter a duration between 0 and 24 hours.');
    }
    return _day(
      date,
      (day) => day.copyWith(
        sleepHours: hours,
        bedtime: bedtime,
        wakeTime: wakeTime,
        clearTimes: bedtime == null,
        feeling: feeling,
        clearFeeling: feeling == null,
      ),
    );
  }

  Future<void> addCalories(int calories) => _day(
    DateTime.now(),
    (day) => day.copyWith(calories: (day.calories + calories).clamp(0, 50000)),
  );
  Future<void> setGoals({int? waterMl, double? sleepHours, int? steps}) =>
      _change(
        (log) => log.copyWith(
          waterGoalMl: waterMl?.clamp(250, 10000),
          sleepGoalHours: sleepHours?.clamp(1, 16),
          stepsGoal: steps?.clamp(500, 100000),
        ),
      );
}

final habitLogProvider = NotifierProvider<HabitLogNotifier, HabitLog>(
  HabitLogNotifier.new,
);
