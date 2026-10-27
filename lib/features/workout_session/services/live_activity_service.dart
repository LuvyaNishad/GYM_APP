import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service managing native iOS ActivityKit Live Activities & Dynamic Island widgets.
class LiveActivityService {
  LiveActivityService();

  static const MethodChannel _channel = MethodChannel('leon/live_activity');
  String? _currentActivityId;

  /// Current active iOS Live Activity ID, if running.
  String? get currentActivityId => _currentActivityId;

  /// Returns true if the device is iOS 16.1+ and Live Activities are permitted by the user.
  Future<bool> areActivitiesEnabled() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      final enabled = await _channel.invokeMethod<bool>('areActivitiesEnabled');
      return enabled ?? false;
    } on PlatformException catch (e) {
      debugPrint('[LiveActivityService] Error checking status: $e');
      return false;
    }
  }

  /// Starts a Live Activity on the Lock Screen and Dynamic Island.
  Future<void> startLiveActivity({
    required String workoutTitle,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    required int remainingSeconds,
    required int totalDurationSeconds,
    double targetWeightKg = 0.0,
    int targetReps = 0,
    String plateBreakdown = '',
    bool isResting = true,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final activityId = await _channel
          .invokeMethod<String>('startLiveActivity', {
            'workoutTitle': workoutTitle,
            'exerciseName': exerciseName,
            'setNumber': setNumber,
            'totalSets': totalSets,
            'remainingSeconds': remainingSeconds,
            'totalDurationSeconds': totalDurationSeconds,
            'targetWeightKg': targetWeightKg,
            'targetReps': targetReps,
            'plateBreakdown': plateBreakdown,
            'isResting': isResting,
          });
      _currentActivityId = activityId;
    } on PlatformException catch (e) {
      debugPrint('[LiveActivityService] Failed to start Live Activity: $e');
    }
  }

  /// Updates the running Live Activity and Dynamic Island with current countdown.
  Future<void> updateLiveActivity({
    required int remainingSeconds,
    required int totalDurationSeconds,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    double targetWeightKg = 0.0,
    int targetReps = 0,
    String plateBreakdown = '',
    bool isResting = true,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      await _channel.invokeMethod('updateLiveActivity', {
        'remainingSeconds': remainingSeconds,
        'totalDurationSeconds': totalDurationSeconds,
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'totalSets': totalSets,
        'targetWeightKg': targetWeightKg,
        'targetReps': targetReps,
        'plateBreakdown': plateBreakdown,
        'isResting': isResting,
      });
    } on PlatformException catch (e) {
      debugPrint('[LiveActivityService] Failed to update Live Activity: $e');
    }
  }

  /// Terminates and dismisses the Live Activity immediately.
  Future<void> stopLiveActivity() async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      await _channel.invokeMethod('stopLiveActivity');
      _currentActivityId = null;
    } on PlatformException catch (e) {
      debugPrint('[LiveActivityService] Failed to stop Live Activity: $e');
    }
  }
}

final liveActivityServiceProvider = Provider<LiveActivityService>((ref) {
  return LiveActivityService();
});
