import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/workout_model.dart';
import '../models/user_model.dart';
import '../models/progress_model.dart';
import '../models/split_model.dart';
import '../features/profile/models/account_profile_model.dart';
import '../features/health_tracking/models/body_measurement_model.dart';
import '../features/workout_builder/models/split_model.dart';
import '../features/workout_builder/models/training_schedule.dart';
import '../features/exercise_library/models/exercise_library_item.dart';
import '../features/dashboard/providers/habit_log_provider.dart';
import 'hive_service.dart';
import 'daily_steps_platform.dart';

enum RestoreMode { keepExisting, useBackup, replaceAll }

class BackupPreview {
  const BackupPreview(this.backup, this.current, this.createdAt);
  final Map<String, dynamic> backup, current;
  final DateTime createdAt;
  Map<String, dynamic> get documents =>
      backup['documents'] as Map<String, dynamic>;
  Map<String, dynamic> get settings =>
      backup['settings'] as Map<String, dynamic>;
  List<String> get changes {
    const labels = {
      'workouts': 'Workouts',
      'user': 'Profile records',
      'progress': 'Exercise progress',
      'splits': 'Routines',
      'body_measurements': 'Measurements',
      'custom_exercises': 'Custom exercises',
    };
    final result = <String>[];
    final existing = current['documents'] as Map;
    for (final box in HiveService.documentBoxes) {
      final incoming = documents[box] as Map;
      final local = existing[box] as Map;
      final added = incoming.keys
          .where((key) => !local.containsKey(key))
          .length;
      final conflict = incoming.keys
          .where(
            (key) =>
                local.containsKey(key) &&
                jsonEncode(incoming[key]) != jsonEncode(local[key]),
          )
          .length;
      final identical = incoming.length - added - conflict;
      result.add(
        '${labels[box]}: ${incoming.length} in backup, $added new, $conflict conflicts, $identical identical; ${local.length} on device',
      );
      if (conflict > 0) {
        final changed = incoming.keys
            .where(
              (key) =>
                  local.containsKey(key) &&
                  jsonEncode(incoming[key]) != jsonEncode(local[key]),
            )
            .take(8);
        for (final key in changed) {
          final record = incoming[key] as Map;
          result.add(
            'Conflict: ${record['name'] ?? record['display_name'] ?? key}'
            '${record['date'] == null ? '' : ' (${record['date']})'}',
          );
        }
        if (conflict > 8) {
          result.add('${conflict - 8} more conflicting records');
        }
      }
    }
    final local = current['settings'] as Map;
    final conflicts = settings.keys
        .where(
          (key) =>
              local.containsKey(key) &&
              jsonEncode(local[key]) != jsonEncode(settings[key]),
        )
        .toList();
    result.add(
      '${settings.length} preferences/habit/step entries; conflicting keys: ${conflicts.isEmpty ? 'none' : conflicts.join(', ')}',
    );
    return result;
  }
}

class BackupService {
  const BackupService(this.hive);
  final HiveService hive;
  static const version = 2;
  static const maxBytes = 50 * 1024 * 1024;

  /// Reuse backup validation before accepting downloaded authored data.
  static void validatePortableSnapshot(Map<String, dynamic> snapshot) {
    final settings = snapshot['settings'] as Map;
    _validate({
      'documents': snapshot['documents'],
      'settings': {
        for (final key in settingsKeys)
          if (settings.containsKey(key)) key: settings[key],
      },
    });
  }

  // Portable user data only. Hardware step baselines, auth, active timers and
  // caches cannot safely be moved between installations.
  static const settingsKeys = {
    'onboarding_complete',
    'weight_unit',
    'active_split_id',
    'training_schedules_v1',
    'primary_goal',
    'target_weight',
    'plate_preferences_v1',
    'exercise_favorites_v1',
    'daily_habits_v1',
    'step_tracking_date',
    'step_today_count',
    'step_hourly_distribution',
    'step_history_by_date',
    'step_daily_snapshot',
    'step_record_steps',
    'step_record_date',
  };

  Future<Uint8List> export({DateTime? now}) async {
    final snapshot = await hive.flushedSnapshot();
    final settings = snapshot['settings'] as Map;
    final portable = <String, dynamic>{
      'documents': snapshot['documents'],
      'settings': {
        for (final key in settingsKeys)
          if (settings.containsKey(key)) key: settings[key],
      },
    };
    _validate(portable);
    return Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert({
          'format': 'leon_backup',
          'version': version,
          'created_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
          'units': 'kg_cm',
          ...portable,
        }),
      ),
    );
  }

  Future<BackupPreview> preview(Uint8List bytes) async {
    if (bytes.length > maxBytes) {
      throw const FormatException('Backup exceeds 50 MB.');
    }
    final source = utf8.decode(bytes);
    final decoded = jsonDecode(source);
    _rejectDuplicateKeys(source);
    final root = _map(decoded, 'backup');
    if (root['format'] != 'leon_backup' ||
        root['version'] is! int ||
        ![1, version].contains(root['version'])) {
      throw const FormatException('Unsupported backup format/version.');
    }
    if (root['units'] != 'kg_cm') {
      throw const FormatException('Backup must store kg/cm.');
    }
    final created = DateTime.parse(root['created_at'] as String);
    final documents = _map(root['documents'], 'documents');
    // V1 used the same keyed records but had no custom-exercise/measurement box.
    if (root['version'] == 1) {
      documents.putIfAbsent('custom_exercises', () => <String, dynamic>{});
      documents.putIfAbsent('body_measurements', () => <String, dynamic>{});
    }
    final data = <String, dynamic>{
      'documents': documents,
      'settings': _map(root['settings'], 'settings'),
    };
    _validate(data);
    return BackupPreview(data, await hive.flushedSnapshot(), created);
  }

  Future<void> restore(
    BackupPreview preview,
    RestoreMode mode, {
    Future<void> Function(String)? beforeBoxWrite,
  }) async {
    _validate(preview.backup);
    final current = preview.current;
    if ((current['settings'] as Map)[AppConstants.settingActiveSessionData] !=
        null) {
      throw StateError(
        'Finish or discard your active workout before restoring.',
      );
    }
    final currentDocs = current['documents'] as Map;
    final replacement = <String, dynamic>{
      'documents': {
        for (final box in HiveService.documentBoxes)
          box: switch (mode) {
            RestoreMode.replaceAll => preview.documents[box],
            RestoreMode.keepExisting => {
              ...preview.documents[box] as Map,
              ...currentDocs[box] as Map,
            },
            RestoreMode.useBackup => {
              ...currentDocs[box] as Map,
              ...preview.documents[box] as Map,
            },
          },
      },
      'settings': {
        for (final entry in (current['settings'] as Map).entries)
          if (mode != RestoreMode.replaceAll ||
              !settingsKeys.contains(entry.key))
            entry.key: entry.value,
        if (mode != RestoreMode.keepExisting) ...preview.settings,
        if (mode == RestoreMode.keepExisting)
          for (final entry in preview.settings.entries)
            if (!(current['settings'] as Map).containsKey(entry.key))
              entry.key: entry.value,
      },
    };
    // Rebind the phone sensor on this installation. Preserve dated totals.
    for (final key in [
      'step_boot_base',
      'step_reboot_offset',
      'step_last_hw_reading',
    ]) {
      (replacement['settings'] as Map).remove(key);
    }
    await hive.restoreSnapshot(
      replacement,
      expectedSnapshot: _fingerprint(current),
      fingerprint: _fingerprint,
      reconcile: (latest) {
        // Keep concurrent device-only metadata while replacing reviewed data.
        final settings = replacement['settings'] as Map;
        final live = latest['settings'] as Map;
        for (final key in live.keys) {
          if (!settingsKeys.contains(key) &&
              !{
                'step_boot_base',
                'step_reboot_offset',
                'step_last_hw_reading',
              }.contains(key)) {
            settings[key] = live[key];
          }
        }
        for (final key in settings.keys.toList()) {
          if (!settingsKeys.contains(key) && !live.containsKey(key)) {
            settings.remove(key);
          }
        }
        if (mode == RestoreMode.keepExisting &&
            live.containsKey('step_daily_snapshot')) {
          settings['step_daily_snapshot'] = live['step_daily_snapshot'];
        }
        return replacement;
      },
      beforeBoxWrite: beforeBoxWrite,
    );
  }

  static String _fingerprint(Map<String, dynamic> snapshot) {
    final current = snapshot['settings'] as Map;
    final settings = <String, dynamic>{
      for (final key in settingsKeys)
        if (current.containsKey(key)) key: current[key],
      AppConstants.settingActiveSessionData:
          current[AppConstants.settingActiveSessionData],
    };
    if (settings['step_daily_snapshot'] is String) {
      final steps = _map(
        jsonDecode(settings['step_daily_snapshot'] as String),
        'steps',
      );
      steps.remove('updatedAt');
      settings['step_daily_snapshot'] = steps;
    }
    return jsonEncode({
      'documents': snapshot['documents'],
      'settings': settings,
    });
  }

  static Map<String, dynamic> _map(Object? value, String label) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException('$label must be an object with string keys.');
    }
    return Map<String, dynamic>.from(value);
  }

  static void _rejectDuplicateKeys(String source) {
    final stack = <Set<String>?>[];
    final expecting = <bool>[];
    final tokens = RegExp(
      r'"(?:\\.|[^"\\])*"|[{}\[\]:,]|[^{}\[\]:,\s]+',
    ).allMatches(source);
    for (final match in tokens) {
      final token = match.group(0)!;
      if (token == '{' || token == '[') {
        stack.add(token == '{' ? <String>{} : null);
        expecting.add(token == '{');
      } else if (token == '}' || token == ']') {
        stack.removeLast();
        expecting.removeLast();
      } else if (token == ':') {
        expecting[expecting.length - 1] = false;
      } else if (token == ',') {
        expecting[expecting.length - 1] = stack.last != null;
      } else if (stack.isNotEmpty &&
          stack.last != null &&
          expecting.last &&
          token.startsWith('"')) {
        final key = jsonDecode(token) as String;
        if (!stack.last!.add(key)) {
          throw FormatException('Duplicate JSON key: $key');
        }
      }
    }
  }

  static void _schedules(String raw) {
    _rejectDuplicateKeys(raw);
    final entries = jsonDecode(raw) as List;
    for (final entry in entries) {
      final j = _map(entry, 'schedule');
      if (j['splitId'] is! String ||
          (j['splitId'] as String).isEmpty ||
          j['trainingDays'] is! List ||
          (j['trainingDays'] as List).isEmpty ||
          (j['trainingDays'] as List).any((d) => d is! bool)) {
        throw const FormatException('Invalid training schedule.');
      }
      DateTime.parse(j['startedOn'] as String);
      if (j['historyStartedOn'] != null) {
        DateTime.parse(j['historyStartedOn'] as String);
      }
    }
    if (TrainingSchedule.decode(raw).length != entries.length) {
      throw const FormatException('Invalid training schedule.');
    }
  }

  static void _validate(Map<String, dynamic> data) {
    final documents = _map(data['documents'], 'documents');
    if (documents.length != HiveService.documentBoxes.length ||
        HiveService.documentBoxes.any((box) => !documents.containsKey(box))) {
      throw const FormatException(
        'Backup has missing or unsupported data boxes.',
      );
    }
    // Reject non-finite/negative physical measurements before model defaults
    // can hide malformed fields. JSON encodability also rejects native values.
    void physical(Object? value, [String field = '']) {
      if (value is Map) {
        for (final e in value.entries) {
          physical(e.value, e.key.toString());
        }
      } else if (value is List) {
        for (final item in value) {
          physical(item, field);
        }
      } else if (value is num &&
          (!value.isFinite ||
              ((field.toLowerCase().contains('weight') ||
                      field.contains('reps') ||
                      field.endsWith('_cm') ||
                      field.contains('duration')) &&
                  value < 0))) {
        throw FormatException('Invalid numeric value in $field.');
      }
    }

    physical(data);
    void range(
      Object? value,
      String field,
      num min,
      num max, {
      bool integer = false,
    }) {
      if (value == null) return;
      if (value is! num ||
          !value.isFinite ||
          value < min ||
          value > max ||
          (integer && value % 1 != 0)) {
        throw FormatException('Invalid numeric value in $field.');
      }
    }

    for (final box in HiveService.documentBoxes) {
      final records = _map(documents[box], box);
      if (records.length > 100000) {
        throw FormatException('Too many records in $box.');
      }
      for (final e in records.entries) {
        final json = _map(e.value, '$box/${e.key}');
        if (e.key.isEmpty || (box != 'user' && json['id'] != e.key)) {
          throw FormatException(
            'Invalid/duplicate record identity in $box/${e.key}.',
          );
        }
        try {
          switch (box) {
            case 'workouts':
              WorkoutModel.fromJson(json);
            case 'body_measurements':
              BodyMeasurementEntry.fromJson(json);
            case 'custom_exercises':
              ExerciseLibraryItem.fromJson(json);
            case 'progress':
              ProgressModel.fromJson(json);
            case 'splits':
              if (json.containsKey('createdAt')) {
                SplitModel.fromJson(json);
              } else {
                TrainingSplitModel.fromJson(json);
              }
            case 'user':
              if (e.key == 'account_profile_data') {
                AccountProfile.fromJson(json);
              } else {
                UserModel.fromJson(json);
              }
              if (json['training_schedules'] != null) {
                _schedules(json['training_schedules'] as String);
              }
          }
        } catch (error) {
          throw FormatException('Invalid $box/${e.key}: $error');
        }
      }
    }
    final settings = _map(data['settings'], 'settings');
    if (settings.keys.any((key) => !settingsKeys.contains(key))) {
      throw const FormatException('Backup contains unsupported settings.');
    }
    if (settings['plate_preferences_v1'] != null) {
      final plates = _map(
        settings['plate_preferences_v1'],
        'plate preferences',
      );
      range(plates['bar'], 'barbell weight', 0, 100);
      if (plates['plates'] is! List) {
        throw const FormatException('Invalid available plates.');
      }
      for (final value in plates['plates'] as List) {
        if (value == null) {
          throw const FormatException('Invalid available plate.');
        }
        range(value, 'available plate', 0.01, 100);
      }
    }
    const types = <String, Type>{
      'onboarding_complete': bool,
      'weight_unit': String,
      'active_split_id': String,
      'primary_goal': String,
      'target_weight': num,
      'step_tracking_date': String,
      'step_today_count': int,
      'step_record_steps': int,
      'step_record_date': String,
    };
    for (final entry in types.entries) {
      final value = settings[entry.key];
      if (value == null) continue;
      final valid = switch (entry.value) {
        const (bool) => value is bool,
        const (String) => value is String,
        const (int) => value is int && value >= 0,
        const (num) => value is num && value.isFinite && value >= 0,
        _ => false,
      };
      if (!valid) throw FormatException('Invalid preference: ${entry.key}');
    }
    if (settings['weight_unit'] != null &&
        !['kg', 'lb', 'lbs'].contains(settings['weight_unit'])) {
      throw const FormatException('Unsupported weight unit.');
    }
    if (settings['exercise_favorites_v1'] != null) {
      final favorites = settings['exercise_favorites_v1'];
      if (favorites is! List ||
          favorites.any((e) => e is! String) ||
          favorites.toSet().length != favorites.length) {
        throw const FormatException('Invalid favorite exercise IDs.');
      }
    }
    for (final key in [
      'training_schedules_v1',
      'daily_habits_v1',
      'step_history_by_date',
      'step_hourly_distribution',
      'step_daily_snapshot',
    ]) {
      if (settings[key] != null) {
        if (settings[key] is! String) {
          throw FormatException('$key must contain JSON.');
        }
        _rejectDuplicateKeys(settings[key] as String);
        final json = jsonDecode(settings[key] as String);
        physical(json);
        if (key == 'training_schedules_v1') {
          _schedules(settings[key] as String);
        }
        if (key == 'step_daily_snapshot') {
          DailyStepsSnapshot.fromMap(json as Map);
        }
        if (key == 'step_history_by_date') {
          final days = _map(json, 'step history');
          if (days.entries.any(
            (e) =>
                !DailyStepsSnapshot.validDate(e.key) ||
                e.value is! int ||
                (e.value as int) < 0,
          )) {
            throw const FormatException('Invalid step history.');
          }
        }
        if (key == 'step_hourly_distribution' &&
            (json is! List ||
                json.length != 24 ||
                json.any((n) => n is! int || n < 0))) {
          throw const FormatException('Invalid hourly step totals.');
        }
        if (key == 'daily_habits_v1') {
          final habits = _map(json, key);
          range(habits['waterGoalMl'], 'water goal', 250, 10000, integer: true);
          range(habits['sleepGoalHours'], 'sleep goal', 1, 16);
          range(habits['stepsGoal'], 'step goal', 500, 100000, integer: true);
          final days = _map(habits['days'], 'habit days');
          for (final e in days.entries) {
            if (!DailyStepsSnapshot.validDate(e.key)) {
              throw const FormatException('Invalid habit date.');
            }
            final day = _map(e.value, e.key);
            range(day['sleepHours'], 'sleep duration', 0, 24);
            range(day['soreness'], 'soreness', 0, 10, integer: true);
            range(day['calories'], 'calories', 0, 100000, integer: true);
            for (final water in day['water'] as List? ?? []) {
              final entry = _map(water, 'water entry');
              // Recovery forms allow one entry for the complete daily total.
              range(entry['ml'], 'water amount', 1, 10000, integer: true);
            }
            DayHabits.fromJson(day);
          }
        }
      }
    }
    jsonEncode(data);
  }
}

final backupServiceProvider = Provider(
  (ref) => BackupService(ref.watch(hiveServiceProvider)),
);
