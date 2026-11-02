import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveActivityService {
  LiveActivityService({
    this.channel = const MethodChannel('leon/live_activity'),
    bool? supported,
  }) : supported = supported ?? (!kIsWeb && Platform.isIOS);
  final MethodChannel channel;
  final bool supported;
  String? _currentActivityId, _workoutId;
  DateTime? _deadline;
  String _weightUnit = 'kg';
  int _revision = 0;
  Future<void> _pending = Future.value();
  String? get currentActivityId => _currentActivityId;
  void configureIdentity(
    String? workoutId,
    DateTime? deadline, [
    String weightUnit = 'kg',
  ]) {
    if (_workoutId != workoutId) {
      _revision++;
      _currentActivityId = null;
    }
    _workoutId = workoutId;
    _deadline = deadline;
    _weightUnit = weightUnit;
  }

  Future<T?> _call<T>(String method, Object? args, {int? revision}) =>
      _enqueue(() => channel.invokeMethod<T>(method, args), revision: revision);

  Future<T?> _enqueue<T>(Future<T?> Function() action, {int? revision}) {
    if (!supported) return Future.value();
    final result = _pending.then<T?>((_) async {
      if (revision != null && revision != _revision) return null;
      try {
        return await action();
      } on MissingPluginException {
        return null;
      } on PlatformException {
        return null;
      }
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<bool> areActivitiesEnabled() async =>
      await _call<bool>('areActivitiesEnabled', null) ?? false;
  Future<void> cleanupStaleActivities(String? validWorkoutId) async {
    await _call('cleanupStaleActivities', {'workoutId': validWorkoutId});
  }

  Future<void> startLiveActivity({
    required String workoutTitle,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    required int remainingSeconds,
    required int totalDurationSeconds,
    double targetWeightKg = 0,
    int targetReps = 0,
    String plateBreakdown = '',
    bool isResting = true,
  }) async {
    final revision = _revision;
    if (!supported ||
        _workoutId == null ||
        _deadline == null ||
        !_deadline!.isAfter(DateTime.now())) {
      return;
    }
    final workoutId = _workoutId;
    final payload = <String, Object?>{
      'workoutTitle': workoutTitle,
      'workoutId': workoutId,
      'targetEndTime': _deadline?.millisecondsSinceEpoch,
      'exerciseName': exerciseName,
      'setNumber': setNumber,
      'totalSets': totalSets,
      'remainingSeconds': remainingSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'targetWeightKg': targetWeightKg,
      'weightUnit': _weightUnit == 'kg' ? 'kg' : 'lb',
      'targetReps': targetReps,
      'plateBreakdown': plateBreakdown,
      'isResting': isResting,
    };
    final id = await _enqueue<String>(() async {
      if (await channel.invokeMethod<bool>('areActivitiesEnabled') != true ||
          revision != _revision) {
        return null;
      }
      return channel.invokeMethod<String>('startLiveActivity', payload);
    }, revision: revision);
    if (revision == _revision) {
      _currentActivityId = id;
    } else if (id != null) {
      await _call('stopLiveActivity', {'activityId': id});
    }
  }

  Future<void> updateLiveActivity({
    required int remainingSeconds,
    required int totalDurationSeconds,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    double targetWeightKg = 0,
    int targetReps = 0,
    String plateBreakdown = '',
    bool isResting = true,
  }) async {
    await _call('updateLiveActivity', {
      'activityId': _currentActivityId,
      'workoutId': _workoutId,
      'targetEndTime': _deadline?.millisecondsSinceEpoch,
      'remainingSeconds': remainingSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'exerciseName': exerciseName,
      'setNumber': setNumber,
      'totalSets': totalSets,
      'targetWeightKg': targetWeightKg,
      'weightUnit': _weightUnit == 'kg' ? 'kg' : 'lb',
      'targetReps': targetReps,
      'plateBreakdown': plateBreakdown,
      'isResting': isResting,
    }, revision: _revision);
  }

  Future<void> stopLiveActivity() async {
    final revision = ++_revision;
    await _call('stopLiveActivity', {
      'activityId': _currentActivityId,
      'workoutId': _workoutId,
    });
    if (revision == _revision) _currentActivityId = null;
  }
}

final liveActivityServiceProvider = Provider((ref) => LiveActivityService());
