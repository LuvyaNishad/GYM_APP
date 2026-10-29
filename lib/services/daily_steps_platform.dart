import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Date-keyed totals from the phone's own tracker. Counts are authoritative
/// replacements, including zeroes; they must never be added to sensor counts.
class DailyStepsSnapshot {
  DailyStepsSnapshot({
    required this.date,
    required Map<String, int> days,
    required this.source,
    this.updatedAt,
  }) : days = Map.unmodifiable(days);

  final String date;
  final Map<String, int> days;
  final String source;
  final DateTime? updatedAt;

  static bool validDate(String value) {
    final parsed = DateTime.tryParse(value);
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
        parsed != null &&
        dateKey(parsed) == value;
  }

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory DailyStepsSnapshot.fromMap(Map<dynamic, dynamic> data) {
    final date = data['date'];
    final days = data['days'];
    final source = data['source'];
    if (date is! String ||
        !validDate(date) ||
        days is! Map ||
        source is! String ||
        source.isEmpty) {
      throw const FormatException('Invalid daily step snapshot');
    }
    final totals = <String, int>{};
    for (final entry in days.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String ||
          !validDate(key) ||
          key.compareTo(date) > 0 ||
          value is! num ||
          !value.isFinite ||
          value < 0 ||
          value % 1 != 0) {
        throw const FormatException('Invalid daily step total');
      }
      totals[key] = value.toInt();
    }
    if (!totals.containsKey(date)) {
      throw const FormatException('Missing current daily step total');
    }
    return DailyStepsSnapshot(
      date: date,
      days: totals,
      source: source,
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'date': date,
    'days': days,
    'source': source,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}

abstract interface class DailyStepsPlatform {
  Future<bool> hasMotionPermission();
  Future<bool> requestMotionPermission();
  Future<DailyStepsSnapshot?> readDailySteps();
}

class MethodChannelDailyStepsPlatform implements DailyStepsPlatform {
  static const channel = MethodChannel('com.example.leon/pedometer');

  @override
  Future<bool> hasMotionPermission() async =>
      (await Permission.activityRecognition.status).isGranted;

  @override
  Future<bool> requestMotionPermission() async =>
      (await Permission.activityRecognition.request()).isGranted;

  @override
  Future<DailyStepsSnapshot?> readDailySteps() async {
    final data = await channel.invokeMapMethod<dynamic, dynamic>(
      'getDailySteps',
    );
    return data == null ? null : DailyStepsSnapshot.fromMap(data);
  }
}

final dailyStepsPlatformProvider = Provider<DailyStepsPlatform>(
  (ref) => MethodChannelDailyStepsPlatform(),
);
